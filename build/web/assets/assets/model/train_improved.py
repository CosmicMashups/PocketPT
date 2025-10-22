#!/usr/bin/env python3
"""
Improved CNN Training Script for MPII Pose Classification
"""

import os
import sys
import argparse
import yaml
import logging
import time
import csv
from datetime import datetime
from typing import Dict, Any, Optional

import torch
import torch.nn as nn
import torch.optim as optim
from torch.optim.lr_scheduler import ReduceLROnPlateau, CosineAnnealingLR
from torch.cuda.amp import GradScaler, autocast
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from sklearn.utils.class_weight import compute_class_weight

# Add src to path for absolute imports
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(current_dir, 'src'))

from utils.common import (
    set_seed, get_device, save_json, AverageMeter, 
    compute_metrics, save_confusion_matrix
)
from models.cnn_backbones import create_cnn, freeze_backbone
from datasets.pocketpt_dataset import build_dataloaders


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='Train CNN for MPII pose classification')
    
    # Data arguments
    parser.add_argument('--csv', type=str, default='annotations_filtered.csv',
                       help='Path to annotations CSV file')
    parser.add_argument('--img-root', type=str, 
                       default='mpii-dataset/mpii_human_pose_v1/images/',
                       help='Root directory for images')
    parser.add_argument('--include-unknown', action='store_true',
                       help='Include samples with unknown labels')
    
    # Model arguments
    parser.add_argument('--backbone', type=str, default='resnet18',
                       choices=['resnet18', 'resnet34', 'mobilenet_v2', 'efficientnet_b0'],
                       help='CNN backbone architecture')
    parser.add_argument('--pretrained', action='store_true', default=True,
                       help='Use pretrained weights')
    parser.add_argument('--freeze-backbone', action='store_true',
                       help='Freeze backbone layers initially')
    parser.add_argument('--dropout', type=float, default=0.3,
                       help='Dropout rate')
    
    # Training arguments
    parser.add_argument('--epochs', type=int, default=50,
                       help='Number of training epochs')
    parser.add_argument('--batch-size', type=int, default=32,
                       help='Batch size')
    parser.add_argument('--lr', type=float, default=1e-3,
                       help='Learning rate')
    parser.add_argument('--weight-decay', type=float, default=1e-4,
                       help='Weight decay')
    parser.add_argument('--sgd', action='store_true',
                       help='Use SGD instead of Adam')
    parser.add_argument('--class-weights', action='store_true', default=True,
                       help='Use class weights for imbalanced data')
    parser.add_argument('--amp', action='store_true', default=True,
                       help='Use mixed precision training')
    parser.add_argument('--clip-grad', type=float, default=1.0,
                       help='Gradient clipping norm')
    
    # Data split arguments
    parser.add_argument('--val-split', type=float, default=0.2,
                       help='Validation split ratio')
    parser.add_argument('--test-split', type=float, default=0.1,
                       help='Test split ratio')
    parser.add_argument('--num-workers', type=int, default=4,
                       help='Number of data loader workers')
    
    # Early stopping and checkpointing
    parser.add_argument('--early-stop-patience', type=int, default=10,
                       help='Early stopping patience')
    parser.add_argument('--checkpoint-dir', type=str, default='artifacts',
                       help='Directory to save checkpoints')
    parser.add_argument('--resume', action='store_true',
                       help='Resume from last checkpoint')
    
    # Other arguments
    parser.add_argument('--seed', type=int, default=42,
                       help='Random seed')
    parser.add_argument('--config', type=str, default='configs/cnn.yaml',
                       help='Path to config file')
    
    return parser.parse_args()


def load_config(config_path: str, args: argparse.Namespace) -> Dict[str, Any]:
    """Load configuration from YAML file and override with CLI args."""
    config = {}
    
    # Load YAML config if it exists
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f)
    
    # Override with CLI arguments
    cli_args = vars(args)
    for key, value in cli_args.items():
        if value is not None and key != 'config':
            config[key] = value
    
    return config


def setup_logging(log_dir: str):
    """Setup logging configuration."""
    os.makedirs(log_dir, exist_ok=True)
    
    # Create log file
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    log_file = os.path.join(log_dir, f'train_improved_{timestamp}.log')
    
    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler(sys.stdout)
        ]
    )
    
    return log_file


def save_checkpoint(model: nn.Module, optimizer: optim.Optimizer, 
                   scheduler, epoch: int, best_metric: float, config: Dict[str, Any], 
                   checkpoint_dir: str, filename: str):
    """Save training checkpoint."""
    os.makedirs(checkpoint_dir, exist_ok=True)
    
    checkpoint = {
        'epoch': epoch,
        'model_state_dict': model.state_dict(),
        'optimizer_state_dict': optimizer.state_dict(),
        'scheduler_state_dict': scheduler.state_dict() if scheduler else None,
        'best_metric': best_metric,
        'config': config
    }
    
    checkpoint_path = os.path.join(checkpoint_dir, filename)
    torch.save(checkpoint, checkpoint_path)
    logging.info(f"Checkpoint saved: {checkpoint_path}")


def load_checkpoint(checkpoint_path: str, model: nn.Module, 
                   optimizer: optim.Optimizer, scheduler):
    """Load training checkpoint."""
    if os.path.exists(checkpoint_path):
        checkpoint = torch.load(checkpoint_path, map_location='cpu')
        
        model.load_state_dict(checkpoint['model_state_dict'])
        optimizer.load_state_dict(checkpoint['optimizer_state_dict'])
        
        if scheduler and checkpoint.get('scheduler_state_dict'):
            scheduler.load_state_dict(checkpoint['scheduler_state_dict'])
        
        start_epoch = checkpoint['epoch'] + 1
        best_metric = checkpoint['best_metric']
        
        logging.info(f"Resumed from checkpoint: {checkpoint_path}")
        logging.info(f"Starting from epoch: {start_epoch}")
        logging.info(f"Best metric so far: {best_metric}")
        
        return start_epoch, best_metric
    
    return 0, 0.0


def compute_class_weights_from_csv(csv_path: str) -> torch.Tensor:
    """Compute class weights from CSV file to handle class imbalance."""
    df = pd.read_csv(csv_path)
    labels = df['label'].values
    
    # Compute balanced class weights
    unique_classes = np.unique(labels)
    class_weights = compute_class_weight(
        'balanced', 
        classes=unique_classes, 
        y=labels
    )
    
    # Convert to tensor
    class_weights_tensor = torch.tensor(class_weights, dtype=torch.float32)
    
    logging.info(f"Computed class weights for {len(unique_classes)} classes")
    logging.info(f"Class weights range: {class_weights_tensor.min():.3f} - {class_weights_tensor.max():.3f}")
    
    return class_weights_tensor


def train_epoch(model: nn.Module, train_loader, criterion: nn.Module, 
                optimizer: optim.Optimizer, device: str, scaler: Optional[GradScaler] = None):
    """Train for one epoch."""
    model.train()
    
    losses = AverageMeter()
    accuracies = AverageMeter()
    
    for batch_idx, (data, target) in enumerate(train_loader):
        data, target = data.to(device, non_blocking=True), target.to(device, non_blocking=True)
        
        optimizer.zero_grad()
        
        if scaler is not None:
            with autocast():
                output = model(data)
                loss = criterion(output, target)
            
            scaler.scale(loss).backward()
            scaler.unscale_(optimizer)
            torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
            scaler.step(optimizer)
            scaler.update()
        else:
            output = model(data)
            loss = criterion(output, target)
            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
            optimizer.step()
        
        # Compute accuracy
        pred = output.argmax(dim=1, keepdim=True)
        accuracy = pred.eq(target.view_as(pred)).float().mean()
        
        losses.update(loss.item(), data.size(0))
        accuracies.update(accuracy.item(), data.size(0))
        
        if batch_idx % 50 == 0:
            logging.info(f'Batch {batch_idx}/{len(train_loader)}: '
                        f'Loss: {losses.avg:.4f}, Acc: {accuracies.avg:.4f}')
    
    return losses.avg, accuracies.avg


def validate_epoch(model: nn.Module, val_loader, criterion: nn.Module, 
                  device: str, label_encoder) -> tuple:
    """Validate for one epoch."""
    model.eval()
    
    losses = AverageMeter()
    all_predictions = []
    all_targets = []
    
    with torch.no_grad():
        for data, target in val_loader:
            data, target = data.to(device, non_blocking=True), target.to(device, non_blocking=True)
            
            output = model(data)
            loss = criterion(output, target)
            
            pred = output.argmax(dim=1)
            
            losses.update(loss.item(), data.size(0))
            all_predictions.extend(pred.cpu().numpy())
            all_targets.extend(target.cpu().numpy())
    
    # Compute metrics
    metrics = compute_metrics(all_targets, all_predictions)
    
    return losses.avg, metrics


def plot_training_curves(train_log_path: str, save_path: str):
    """Plot training and validation curves."""
    try:
        df = pd.read_csv(train_log_path)
        
        plt.figure(figsize=(15, 10))
        
        # Loss curves
        plt.subplot(2, 2, 1)
        plt.plot(df['epoch'], df['train_loss'], label='Train Loss', marker='o')
        plt.plot(df['epoch'], df['val_loss'], label='Val Loss', marker='s')
        plt.title('Training and Validation Loss')
        plt.xlabel('Epoch')
        plt.ylabel('Loss')
        plt.legend()
        plt.grid(True)
        
        # Accuracy curves
        plt.subplot(2, 2, 2)
        plt.plot(df['epoch'], df['train_acc'], label='Train Acc', marker='o')
        plt.plot(df['epoch'], df['val_acc'], label='Val Acc', marker='s')
        plt.title('Training and Validation Accuracy')
        plt.xlabel('Epoch')
        plt.ylabel('Accuracy')
        plt.legend()
        plt.grid(True)
        
        # F1 score
        plt.subplot(2, 2, 3)
        plt.plot(df['epoch'], df['val_macro_f1'], label='Val F1', marker='s', color='green')
        plt.title('Validation F1 Score')
        plt.xlabel('Epoch')
        plt.ylabel('F1 Score')
        plt.legend()
        plt.grid(True)
        
        # Learning rate
        plt.subplot(2, 2, 4)
        plt.plot(df['epoch'], df['lr'], label='Learning Rate', marker='o', color='red')
        plt.title('Learning Rate')
        plt.xlabel('Epoch')
        plt.ylabel('LR')
        plt.legend()
        plt.grid(True)
        
        plt.tight_layout()
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        logging.info(f"Training curves saved to {save_path}")
        
    except Exception as e:
        logging.warning(f"Could not plot training curves: {e}")


def main():
    """Main training function."""
    args = parse_args()
    
    # Load configuration
    config = load_config(args.config, args)
    
    # Setup logging
    log_file = setup_logging('logs')
    logging.info(f"Improved training started. Log file: {log_file}")
    logging.info(f"Configuration: {config}")
    
    # Set seed and device
    set_seed(config['seed'])
    device = get_device()
    logging.info(f"Using device: {device}")
    
    # Create directories
    os.makedirs(config['checkpoint_dir'], exist_ok=True)
    os.makedirs('logs', exist_ok=True)
    
    # Build dataloaders
    logging.info("Building dataloaders...")
    train_loader, val_loader, test_loader, label_encoder, class_weights = build_dataloaders(config)
    
    # Create model
    logging.info(f"Creating model with backbone: {config['backbone']}")
    num_classes = len(label_encoder.classes_)
    model = create_cnn(
        backbone=config['backbone'],
        num_classes=num_classes,
        pretrained=config['pretrained'],
        dropout=config['dropout']
    )
    
    # Freeze backbone if requested
    if config.get('freeze_backbone', False):
        model = freeze_backbone(model, freeze=True)
        logging.info("Backbone layers frozen")
    
    model = model.to(device)
    
    # Loss function with class weights
    if config.get('class_weights', False) and class_weights is not None:
        class_weights = class_weights.to(device)
        criterion = nn.CrossEntropyLoss(weight=class_weights)
        logging.info("Using class weights for loss")
    else:
        criterion = nn.CrossEntropyLoss()
    
    # Optimizer
    if config.get('sgd', False):
        optimizer = optim.SGD(model.parameters(), lr=config['lr'], 
                             momentum=0.9, weight_decay=config['weight_decay'])
        logging.info("Using SGD optimizer")
    else:
        optimizer = optim.Adam(model.parameters(), lr=config['lr'], 
                              weight_decay=config['weight_decay'])
        logging.info("Using Adam optimizer")
    
    # Scheduler - use CosineAnnealingLR for better convergence
    scheduler = CosineAnnealingLR(optimizer, T_max=config['epochs'], eta_min=1e-6)
    logging.info("Using CosineAnnealingLR scheduler")
    
    # Mixed precision
    scaler = None
    if config.get('amp', False) and device == 'cuda':
        scaler = GradScaler()
        logging.info("Using mixed precision training")
    
    # Resume from checkpoint if requested
    start_epoch = 0
    best_metric = 0.0
    if config.get('resume', False):
        last_checkpoint = os.path.join(config['checkpoint_dir'], 'cnn_last.pt')
        start_epoch, best_metric = load_checkpoint(last_checkpoint, model, optimizer, scheduler)
    
    # Training loop
    logging.info("Starting training...")
    
    # Create training log CSV
    log_csv_path = os.path.join('logs', 'train_improved_log.csv')
    log_fields = ['epoch', 'lr', 'train_loss', 'val_loss', 'train_acc', 'val_acc', 
                  'val_macro_f1', 'time']
    
    with open(log_csv_path, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=log_fields)
        writer.writeheader()
    
    # Initialize early stopping variables
    patience_counter = 0
    
    for epoch in range(start_epoch, config['epochs']):
        epoch_start_time = time.time()
        
        # Train
        train_loss, train_acc = train_epoch(model, train_loader, criterion, 
                                           optimizer, device, scaler)
        
        # Validate
        val_loss, val_metrics = validate_epoch(model, val_loader, criterion, 
                                              device, label_encoder)
        
        # Update learning rate
        scheduler.step()
        current_lr = optimizer.param_groups[0]['lr']
        
        # Save confusion matrix periodically
        if epoch % 10 == 0 or epoch == config['epochs'] - 1:
            # Get predictions for confusion matrix
            model.eval()
            all_preds = []
            all_targets = []
            
            with torch.no_grad():
                for data, target in val_loader:
                    data = data.to(device, non_blocking=True)
                    output = model(data)
                    pred = output.argmax(dim=1)
                    all_preds.extend(pred.cpu().numpy())
                    all_targets.extend(target.numpy())
            
            # Save confusion matrix
            cm_path = os.path.join(config['checkpoint_dir'], f'confmat_epoch{epoch}.png')
            save_confusion_matrix(all_targets, all_preds, 
                                label_encoder.classes_, cm_path,
                                f'Confusion Matrix - Epoch {epoch}')
        
        # Log epoch results
        epoch_time = time.time() - epoch_start_time
        logging.info(f"Epoch {epoch}: train_loss={train_loss:.4f}, "
                    f"val_loss={val_loss:.4f}, val_acc={val_metrics['accuracy']:.4f}, "
                    f"val_f1={val_metrics['f1']:.4f}, lr={current_lr:.6f}")
        
        # Save to CSV
        with open(log_csv_path, 'a', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=log_fields)
            writer.writerow({
                'epoch': epoch,
                'lr': current_lr,
                'train_loss': train_loss,
                'val_loss': val_loss,
                'train_acc': train_acc,
                'val_acc': val_metrics['accuracy'],
                'val_macro_f1': val_metrics['f1'],
                'time': epoch_time
            })
        
        # Save checkpoints
        save_checkpoint(model, optimizer, scheduler, epoch, best_metric, 
                       config, config['checkpoint_dir'], 'cnn_last.pt')
        
        # Save best model
        if val_metrics['f1'] > best_metric:
            best_metric = val_metrics['f1']
            save_checkpoint(model, optimizer, scheduler, epoch, best_metric, 
                           config, config['checkpoint_dir'], 'cnn_best.pt')
            logging.info(f"New best model saved with F1: {best_metric:.4f}")
        
        # Unfreeze backbone after warmup if requested
        if (config.get('freeze_backbone', False) and epoch == 2 and 
            config.get('warmup_epochs', 3) == 3):
            model = freeze_backbone(model, freeze=False)
            logging.info("Backbone layers unfrozen")
        
        # Early stopping
        if val_metrics['f1'] <= best_metric:
            patience_counter += 1
            if patience_counter >= config.get('early_stop_patience', 10):
                logging.info(f"Early stopping triggered after {epoch + 1} epochs")
                break
        else:
            patience_counter = 0
    
    # Training summary
    logging.info("Training completed!")
    logging.info(f"Best validation F1: {best_metric:.4f}")
    logging.info(f"Model saved to: {config['checkpoint_dir']}")
    logging.info(f"Training log: {log_csv_path}")
    
    # Plot training curves
    plot_training_curves(log_csv_path, os.path.join('logs', 'train_val_curves.png'))


if __name__ == '__main__':
    main()
