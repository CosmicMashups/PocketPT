"""
Knowledge Distillation Training Script for Pain Classification Model
(Subject-Aware Splitting Version)

This script implements knowledge distillation using a pre-trained teacher model
to improve the student PainCNN model performance, with strict subject-level
data splitting to prevent leakage.
"""

import os
import numpy as np
import pickle
import json
import cv2
import random
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, precision_recall_fscore_support
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
from torch.utils.data import DataLoader
import matplotlib.pyplot as plt
import seaborn as sns
from collections import Counter

# Import from existing training script
from train_pain_model import (
    PainDataset, PainCNN, build_cnn_model, build_model,
    downscale_upscale, jpeg_compress
)

# Import teacher models
from teacher_models import build_teacher_model, fine_tune_teacher

# Set random seeds for reproducibility
np.random.seed(42)
torch.manual_seed(42)
if torch.cuda.is_available():
    torch.cuda.manual_seed(42)
    torch.cuda.manual_seed_all(42)


def create_subject_aware_data_index(images_dir, labels_dir):
    """
    Create data index including subject IDs for proper splitting.
    Returns list of dicts: {'path': str, 'label': int, 'subject': str}
    """
    print("Creating subject-aware data index...")
    
    data_index = []
    
    # Get all subject directories
    if not os.path.exists(images_dir):
        print(f"Error: Images directory not found: {images_dir}")
        return None

    subject_dirs = [d for d in os.listdir(images_dir) if os.path.isdir(os.path.join(images_dir, d))]
    print(f"Found {len(subject_dirs)} subjects")
    
    for subject_id in subject_dirs:
        subject_img_dir = os.path.join(images_dir, subject_id)
        subject_label_dir = os.path.join(labels_dir, 'PSPI', subject_id)
        
        if not os.path.exists(subject_label_dir):
            # print(f"Warning: No labels found for subject {subject_id}")
            continue
        
        # Get all sequence directories for this subject
        sequence_dirs = [d for d in os.listdir(subject_img_dir) 
                        if os.path.isdir(os.path.join(subject_img_dir, d))]
        
        for sequence_id in sequence_dirs:
            img_seq_dir = os.path.join(subject_img_dir, sequence_id)
            label_seq_dir = os.path.join(subject_label_dir, sequence_id)
            
            if not os.path.exists(label_seq_dir):
                continue
            
            # Get all images in this sequence
            img_files = sorted([f for f in os.listdir(img_seq_dir) if f.endswith('.png')])
            
            for img_file in img_files:
                # Extract frame number
                frame_num = img_file.replace('.png', '')
                label_file = os.path.join(label_seq_dir, f"{frame_num}_facs.txt")
                
                if os.path.exists(label_file):
                    try:
                        # Read PSPI score
                        with open(label_file, 'r') as f:
                            pspi_score = float(f.read().strip())
                        
                        # Convert PSPI score to pain category
                        if pspi_score <= 3:
                            pain_category = 0  # Low
                        elif pspi_score <= 7:
                            pain_category = 1  # Moderate
                        else:
                            pain_category = 2  # Severe
                        
                        img_path = os.path.join(img_seq_dir, img_file)
                        data_index.append({
                            'path': img_path,
                            'label': pain_category,
                            'subject': subject_id
                        })
                        
                    except Exception as e:
                        continue
    
    if len(data_index) == 0:
        print("No data found! Please check your paths.")
        return None
    
    print(f"Total samples found: {len(data_index)}")
    return data_index

def subject_wise_train_test_split(data_index, test_size=0.3, val_size=0.5, random_state=42):
    """
    Split data by Subject ID to prevent data leakage.
    test_size: Fraction of subjects for (Val + Test)
    val_size: Fraction of (Val + Test) to be used for Validation
    """
    # Group data by subject
    subjects = {}
    for item in data_index:
        subj = item['subject']
        if subj not in subjects:
            subjects[subj] = []
        subjects[subj].append((item['path'], item['label']))
    
    subject_ids = list(subjects.keys())
    print(f"Total unique subjects: {len(subject_ids)}")
    
    # Split subjects
    train_subjs, temp_subjs = train_test_split(subject_ids, test_size=test_size, random_state=random_state)
    val_subjs, test_subjs = train_test_split(temp_subjs, test_size=val_size, random_state=random_state)
    
    print(f"Split (Subjects): Train={len(train_subjs)}, Val={len(val_subjs)}, Test={len(test_subjs)}")
    print(f"Train Subjects: {train_subjs}")
    print(f"Val Subjects: {val_subjs}")
    print(f"Test Subjects: {test_subjs}")
    
    # Flatten to frame lists
    train_data = []
    for subj in train_subjs:
        train_data.extend(subjects[subj])
        
    val_data = []
    for subj in val_subjs:
        val_data.extend(subjects[subj])
        
    test_data = []
    for subj in test_subjs:
        test_data.extend(subjects[subj])
        
    print(f"Split (Frames): Train={len(train_data)}, Val={len(val_data)}, Test={len(test_data)}")
    return train_data, val_data, test_data


class FocalLoss(nn.Module):
    """Focal Loss for addressing class imbalance"""
    def __init__(self, alpha=None, gamma=2.0, reduction='mean'):
        super(FocalLoss, self).__init__()
        self.alpha = alpha
        self.gamma = gamma
        self.reduction = reduction
    
    def forward(self, inputs, targets):
        ce_loss = F.cross_entropy(inputs, targets, reduction='none', weight=self.alpha)
        p_t = torch.exp(-ce_loss)
        focal_loss = (1 - p_t) ** self.gamma * ce_loss
        
        if self.reduction == 'mean':
            return focal_loss.mean()
        elif self.reduction == 'sum':
            return focal_loss.sum()
        else:
            return focal_loss

def kd_loss_fn(student_logits, teacher_logits, temperature=4.0):
    """Knowledge Distillation loss (KL divergence)"""
    p = F.log_softmax(student_logits / temperature, dim=1)
    q = F.softmax(teacher_logits / temperature, dim=1)
    return F.kl_div(p, q, reduction='batchmean') * (temperature * temperature)


def evaluate_model(model, loader, device, return_feats=False):
    """Evaluate model on dataset"""
    model.eval()
    all_preds = []
    all_labels = []
    
    with torch.no_grad():
        for data, target in loader:
            data, target = data.to(device), target.to(device)
            if return_feats:
                output, _ = model(data, return_feats=True)
            else:
                output = model(data)
            preds = torch.argmax(output, dim=1).cpu().numpy()
            all_preds.extend(preds)
            all_labels.extend(target.cpu().numpy())
    
    acc = accuracy_score(all_labels, all_preds)
    prec, rec, f1, _ = precision_recall_fscore_support(
        all_labels, all_preds, average='weighted', zero_division=0
    )
    prec_per_class, rec_per_class, f1_per_class, _ = precision_recall_fscore_support(
        all_labels, all_preds, average=None, zero_division=0
    )
    
    return {
        'accuracy': acc,
        'precision': prec,
        'recall': rec,
        'f1': f1,
        'precision_per_class': prec_per_class.tolist(),
        'recall_per_class': rec_per_class.tolist(),
        'f1_per_class': f1_per_class.tolist(),
        'predictions': all_preds,
        'labels': all_labels
    }

def main():
    # Configuration
    config = {
        'teacher_model': 'efficientnet-b4',
        'fine_tune_teacher': False,
        'distill_epochs': 20,
        'batch_size': 32,
        'learning_rate': 1e-5,
        'learning_rate_scratch': 1e-4,
        'temperature': 4.0,
        'alpha': 0.5,
        'beta': 0.4,
        'gamma': 0.1,
        'early_stopping_patience': 10,
        'img_size': (224, 224),
        'load_student_checkpoint': False,
        'student_model_name': 'resnet18',
        'use_class_balancing': False,
        'use_synthetic_balancing': True,
        'use_focal_loss': True,
        'focal_gamma': 2.0,
    }
    
    repo_root = os.path.dirname(os.path.abspath(__file__))
    dataset_root = os.path.join(repo_root, "dataset", "archive (2)")
    IMAGES_DIR = os.path.join(dataset_root, "Images", "Images")
    LABELS_DIR = os.path.join(dataset_root, "Frame_Labels", "Frame_Labels")
    
    print("=== Knowledge Distillation Training (Subject-Aware) ===")
    print(f"Using GPU: NVIDIA GeForce RTX 3050 6GB (Device 0)")
    
    # Create data index
    data_index = create_subject_aware_data_index(IMAGES_DIR, LABELS_DIR)
    if data_index is None:
        return
    
    # Split data by subject
    train_data, val_data, test_data = subject_wise_train_test_split(data_index)
    
    # Create datasets
    train_dataset = PainDataset(train_data, img_size=config['img_size'], augment=True,
                               balance=config.get('use_synthetic_balancing', False))
    val_dataset = PainDataset(val_data, img_size=config['img_size'], augment=False)
    test_dataset = PainDataset(test_data, img_size=config['img_size'], augment=False)
    
    # Device setup
    device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')
    print(f"\nActive Device: {device}")
    if torch.cuda.is_available():
        print(f"Device Name: {torch.cuda.get_device_name(0)}")

    # Dataloaders
    train_loader = DataLoader(train_dataset, batch_size=config['batch_size'], shuffle=True, num_workers=0) # num_workers=0 for stability on Windows
    val_loader = DataLoader(val_dataset, batch_size=config['batch_size'], shuffle=False, num_workers=0)
    test_loader = DataLoader(test_dataset, batch_size=config['batch_size'], shuffle=False, num_workers=0)
    
    # Build Teacher
    print("\nPhase 1: Teacher Model Setup")
    teacher = build_teacher_model(model_type=config['teacher_model'], num_classes=3, pretrained=True)
    teacher = teacher.to(device)
    teacher.eval()
    for param in teacher.parameters():
        param.requires_grad = False
    
    # Build Student
    print("\nPhase 2: Student Model Setup")
    student = build_model(config['student_model_name'], num_classes=3, pretrained=True)
    student = student.to(device)
    
    optimizer = optim.AdamW(student.parameters(), lr=config['learning_rate_scratch'], weight_decay=1e-5)
    scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='min', factor=0.5, patience=5, min_lr=1e-7)
    
    if config.get('use_focal_loss', False):
        # Calculate rough weights from train set
        labels = [label for _, label in train_data]
        counts = Counter(labels)
        total = sum(counts.values())
        weights = torch.tensor([np.sqrt(total/counts[i]) for i in range(3)], dtype=torch.float).to(device)
        print(f"Focal Loss Weights: {weights}")
        ce_loss = FocalLoss(alpha=weights, gamma=config['focal_gamma'])
    else:
        ce_loss = nn.CrossEntropyLoss()

    # Training Loop
    best_val_f1 = 0.0
    patience_counter = 0
    history = {'train_loss': [], 'val_loss': [], 'train_acc': [], 'val_acc': [], 'val_f1': []}
    
    print("\nStarting distillation training...")
    
    for epoch in range(config['distill_epochs']):
        student.train()
        train_loss = 0.0
        train_correct = 0
        train_total = 0
        
        for batch_idx, (data, target) in enumerate(train_loader):
            data, target = data.to(device), target.to(device)
            optimizer.zero_grad()
            
            student_logits, student_feats = student(data, return_feats=True)
            with torch.no_grad():
                teacher_logits, teacher_feats = teacher(data, return_feats=True)
            
            loss_ce = ce_loss(student_logits, target)
            loss_kd = kd_loss_fn(student_logits, teacher_logits, config['temperature'])
            
            # Simple feature loss
            if student_feats.shape == teacher_feats.shape:
                loss_feat = F.mse_loss(student_feats, teacher_feats)
            else:
                loss_feat = torch.tensor(0.0, device=device)
                
            loss = config['alpha']*loss_ce + config['beta']*loss_kd + config['gamma']*loss_feat
            
            loss.backward()
            optimizer.step()
            
            train_loss += loss.item()
            _, predicted = torch.max(student_logits.data, 1)
            train_total += target.size(0)
            train_correct += (predicted == target).sum().item()
            
            if batch_idx % 50 == 0:
                print(f"Epoch {epoch+1}/{config['distill_epochs']} Batch {batch_idx} Loss: {loss.item():.4f}")
        
        # Validation
        val_metrics = evaluate_model(student, val_loader, device)
        
        # Metrics
        train_loss /= len(train_loader)
        train_acc = train_correct / train_total
        
        history['train_loss'].append(train_loss)
        history['train_acc'].append(train_acc)
        history['val_loss'].append(1.0 - val_metrics['f1'])
        history['val_acc'].append(val_metrics['accuracy'])
        history['val_f1'].append(val_metrics['f1'])
        
        print(f"Epoch {epoch+1}: Train Acc {train_acc:.4f} | Val Acc {val_metrics['accuracy']:.4f} | Val F1 {val_metrics['f1']:.4f}")
        
        scheduler.step(1.0 - val_metrics['f1'])
        
        if val_metrics['f1'] > best_val_f1:
            best_val_f1 = val_metrics['f1']
            patience_counter = 0
            torch.save(student.state_dict(), 'models/pain_classification_model_distilled.pth')
            print("  Saved Best Model")
        else:
            patience_counter += 1
            if patience_counter >= config['early_stopping_patience']:
                print("Early Stopping")
                break

    print("\nTraining Complete.")
    print("\nIntegration Checklist & Model Info:")
    print("1. Model Input: 224x224, RGB, Normalized Mean=[0.485, 0.456, 0.406], Std=[0.229, 0.224, 0.225]")
    print("2. Model Output: Logits (size 3). Use Softmax for probabilities.")
    print("3. Format: .pth saved. Export to .onnx/tflite using export scripts.")
    print("4. Classes: 0=Low, 1=Moderate, 2=Severe")

if __name__ == "__main__":
    main()
