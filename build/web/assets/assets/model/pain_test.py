"""
Knowledge Distillation Training Script for Pain Classification Model

This script implements knowledge distillation using a pre-trained teacher model
(EfficientNet-B4 or ResNet-101) to improve the student PainCNN model performance.
"""

import os
import numpy as np
import pickle
import json
import cv2
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
    PainDataset, create_data_index, PainCNN, build_cnn_model,
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


def kd_loss_fn(student_logits, teacher_logits, temperature=4.0):
    """
    Knowledge Distillation loss (KL divergence)
    
    Args:
        student_logits: Student model logits
        teacher_logits: Teacher model logits
        temperature: Temperature for softmax scaling
    
    Returns:
        KL divergence loss
    """
    p = F.log_softmax(student_logits / temperature, dim=1)
    q = F.softmax(teacher_logits / temperature, dim=1)
    return F.kl_div(p, q, reduction='batchmean') * (temperature * temperature)


def evaluate_model(model, loader, device, return_feats=False):
    """
    Evaluate model on dataset
    
    Returns:
        Dictionary with accuracy, precision, recall, F1
    """
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
    
    # Per-class metrics
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


def evaluate_distance_bins(model, test_data, test_loader, device, class_names):
    """
    Evaluate model performance on distance bins (close/mid/far)
    """
    try:
        face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        
        def face_area_ratio(img_path: str) -> float:
            img = cv2.imread(img_path)
            if img is None:
                return 0.0
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            faces = face_cascade.detectMultiScale(gray, 1.1, 4)
            if len(faces) == 0:
                return 0.0
            x, y, w, h = max(faces, key=lambda b: b[2] * b[3])
            h_img, w_img = gray.shape[:2]
            return (w * h) / float(w_img * h_img + 1e-9)
        
        # Compute ratios for test images
        test_img_paths = [p for (p, _) in test_data]
        ratios = [face_area_ratio(p) for p in test_img_paths]
        
        # Get predictions - need to match loader batches to original data indices
        model.eval()
        all_preds = []
        all_labels = []
        
        with torch.no_grad():
            for data, target in test_loader:
                data, target = data.to(device), target.to(device)
                output = model(data)
                preds = torch.argmax(output, dim=1).cpu().numpy()
                all_preds.extend(preds)
                all_labels.extend(target.cpu().numpy())
        
        all_preds = np.array(all_preds)
        all_labels = np.array(all_labels)
        
        # Define bins
        bins = {
            'close': [],  # > 0.08
            'mid': [],    # 0.03–0.08
            'far': []     # < 0.03
        }
        
        # Match predictions to distance ratios
        # Note: This assumes test_loader preserves order and doesn't shuffle
        for idx, r in enumerate(ratios):
            if idx >= len(all_preds):
                break
            if r > 0.08:
                bins['close'].append(idx)
            elif r >= 0.03:
                bins['mid'].append(idx)
            else:
                bins['far'].append(idx)
        
        results = {}
        for name, indices in bins.items():
            if not indices:
                results[name] = {'samples': 0, 'accuracy': 0.0, 'precision': 0.0, 'recall': 0.0, 'f1': 0.0}
                continue
            
            y_true_bin = all_labels[indices]
            y_pred_bin = all_preds[indices]
            acc = (y_true_bin == y_pred_bin).mean()
            prec, rec, f1, _ = precision_recall_fscore_support(
                y_true_bin, y_pred_bin, average='weighted', zero_division=0
            )
            
            results[name] = {
                'samples': len(indices),
                'accuracy': float(acc),
                'precision': float(prec),
                'recall': float(rec),
                'f1': float(f1)
            }
        
        return results
    except Exception as e:
        print(f"Distance bin evaluation failed: {e}")
        import traceback
        traceback.print_exc()
        return {}


def main():
    # Configuration
    config = {
        'teacher_model': 'efficientnet-b4',  # or 'resnet-101'
        'fine_tune_teacher': False,  # SKIP fine-tuning - use ImageNet weights directly (MUCH FASTER)
        'teacher_epochs': 15,  # Not used if fine_tune_teacher=False
        'distill_epochs': 20,  # Reduced - distillation converges faster
        'batch_size': 32,
        'learning_rate': 1e-5,  # Lower LR for fine-tuning from pre-trained student
        'learning_rate_scratch': 1e-4,  # Higher LR if training from scratch
        'temperature': 4.0,
        'alpha': 0.5,  # CrossEntropy weight
        'beta': 0.4,   # Knowledge Distillation weight
        'gamma': 0.1,  # Feature loss weight
        'early_stopping_patience': 10,
        'img_size': (224, 224),
        'load_student_checkpoint': True,  # Load existing trained student model
    }
    
    repo_root = os.path.dirname(os.path.abspath(__file__))
    dataset_root = os.path.join(repo_root, "dataset", "archive (2)")
    IMAGES_DIR = os.path.join(dataset_root, "Images", "Images")
    LABELS_DIR = os.path.join(dataset_root, "Frame_Labels", "Frame_Labels")
    
    print("=== Knowledge Distillation Training ===")
    print(f"Teacher Model: {config['teacher_model']}")
    print(f"Fine-tune Teacher: {config['fine_tune_teacher']}")
    print(f"Distillation Epochs: {config['distill_epochs']}")
    print(f"Load Student Checkpoint: {config['load_student_checkpoint']}")
    print(f"Loss Weights: alpha={config['alpha']}, beta={config['beta']}, gamma={config['gamma']}")
    print(f"Temperature: {config['temperature']}")
    print(f"\nNote: Training should be faster since:")
    print(f"  - Teacher model uses ImageNet pre-trained weights (frozen during distillation)")
    if config['load_student_checkpoint']:
        print(f"  - Student model starts from pre-trained checkpoint (fine-tuning)")
    else:
        print(f"  - Student model training from scratch")
    
    # Create data index
    data_index = create_data_index(IMAGES_DIR, LABELS_DIR)
    if data_index is None:
        return
    
    # Split data (same split as original training)
    train_data, temp_data = train_test_split(
        data_index, test_size=0.3, random_state=42,
        stratify=[item[1] for item in data_index]
    )
    val_data, test_data = train_test_split(
        temp_data, test_size=0.5, random_state=42,
        stratify=[item[1] for item in temp_data]
    )
    
    print(f"\nDataset split:")
    print(f"Training samples: {len(train_data)}")
    print(f"Validation samples: {len(val_data)}")
    print(f"Test samples: {len(test_data)}")
    
    # Create datasets
    train_dataset = PainDataset(train_data, img_size=config['img_size'], augment=True)
    val_dataset = PainDataset(val_data, img_size=config['img_size'], augment=False)
    test_dataset = PainDataset(test_data, img_size=config['img_size'], augment=False)
    
    train_loader = DataLoader(train_dataset, batch_size=config['batch_size'], shuffle=True, num_workers=4)
    val_loader = DataLoader(val_dataset, batch_size=config['batch_size'], shuffle=False, num_workers=4)
    test_loader = DataLoader(test_dataset, batch_size=config['batch_size'], shuffle=False, num_workers=4)
    
    # Device setup
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"\nUsing device: {device}")
    
    # ===== Phase 1: Build and optionally fine-tune teacher =====
    print("\n" + "="*60)
    print("Phase 1: Teacher Model Setup")
    print("="*60)
    
    teacher = build_teacher_model(
        model_type=config['teacher_model'],
        num_classes=3,
        pretrained=True
    )
    teacher = teacher.to(device)
    
    # Use ImageNet pre-trained teacher directly (fast path - no fine-tuning)
    if config['fine_tune_teacher']:
        teacher_path = 'models/teacher_model.pth'
        if not os.path.exists(teacher_path):
            print("Fine-tuning teacher on pain dataset...")
            print("WARNING: This will take 5-7 hours. Consider setting fine_tune_teacher=False for faster training.")
            teacher = fine_tune_teacher(
                teacher, train_loader, val_loader, device,
                epochs=config['teacher_epochs'], lr=config['learning_rate']
            )
            
            # Save fine-tuned teacher
            os.makedirs('models', exist_ok=True)
            torch.save({
                'model_state_dict': teacher.state_dict(),
                'model_type': config['teacher_model'],
            }, teacher_path)
            print(f"Fine-tuned teacher saved to {teacher_path}")
        elif os.path.exists(teacher_path):
            print(f"Loading fine-tuned teacher from {teacher_path}")
            checkpoint = torch.load(teacher_path, map_location=device, weights_only=False)
            teacher.load_state_dict(checkpoint['model_state_dict'])
    else:
        print("Using ImageNet pre-trained teacher directly (no fine-tuning)")
        print("This is much faster and still provides strong distillation guidance.")
    
    # Freeze teacher for distillation
    teacher.eval()
    for param in teacher.parameters():
        param.requires_grad = False
    print("Teacher model frozen and ready for distillation")
    
    # ===== Phase 2: Knowledge Distillation =====
    print("\n" + "="*60)
    print("Phase 2: Knowledge Distillation")
    print("="*60)
    
    # Build student model
    student = build_cnn_model(num_classes=3)
    
    # Load from existing checkpoint if available (fine-tuning scenario)
    student_checkpoint_path = 'models/pain_classification_model.pth'
    student_pretrained = False
    
    if config['load_student_checkpoint'] and os.path.exists(student_checkpoint_path):
        print(f"Loading student from existing pre-trained checkpoint: {student_checkpoint_path}")
        checkpoint = torch.load(student_checkpoint_path, map_location=device, weights_only=False)
        student.load_state_dict(checkpoint['model_state_dict'])
        student_pretrained = True
        
        # Use lower learning rate for fine-tuning
        learning_rate = config['learning_rate']
        print(f"Student is pre-trained. Using fine-tuning LR: {learning_rate}")
        
        # Optionally load optimizer state if available
        if 'optimizer_state_dict' in checkpoint:
            print("Note: Optimizer state found but not loaded (fresh optimizer for distillation)")
    else:
        # Training from scratch
        learning_rate = config['learning_rate_scratch']
        print(f"Student training from scratch. Using LR: {learning_rate}")
    
    student = student.to(device)
    
    # Setup optimizer and losses
    # Use appropriate learning rate based on whether student is pre-trained
    optimizer = optim.AdamW(student.parameters(), lr=learning_rate, weight_decay=1e-5)
    scheduler = optim.lr_scheduler.ReduceLROnPlateau(
        optimizer, mode='min', factor=0.5, patience=5, min_lr=1e-7
    )
    
    ce_loss = nn.CrossEntropyLoss()
    
    # Training history
    history = {
        'train_loss': [],
        'val_loss': [],
        'train_acc': [],
        'val_acc': [],
        'val_f1': []
    }
    
    best_val_f1 = 0.0
    patience_counter = 0
    best_model_state = None
    
    class_names = ['Low', 'Moderate', 'Severe']
    
    print("\nStarting distillation training...")
    
    for epoch in range(config['distill_epochs']):
        # Training phase
        student.train()
        train_loss = 0.0
        train_correct = 0
        train_total = 0
        
        for batch_idx, (data, target) in enumerate(train_loader):
            data, target = data.to(device), target.to(device)
            
            optimizer.zero_grad()
            
            # Student forward
            student_logits, student_feats = student(data, return_feats=True)
            
            # Teacher forward (frozen)
            with torch.no_grad():
                teacher_logits, teacher_feats = teacher(data, return_feats=True)
            
            # Compute losses
            loss_ce = ce_loss(student_logits, target)
            loss_kd = kd_loss_fn(student_logits, teacher_logits, config['temperature'])
            
            # Feature loss (MSE on features)
            if config['gamma'] > 0:
                # Project features to same dimension if needed
                if student_feats.size(1) != teacher_feats.size(1):
                    # Use a projection layer or skip feature loss
                    loss_feat = torch.tensor(0.0, device=device)
                else:
                    loss_feat = F.mse_loss(student_feats, teacher_feats)
            else:
                loss_feat = torch.tensor(0.0, device=device)
            
            # Combined loss
            loss = (config['alpha'] * loss_ce + 
                   config['beta'] * loss_kd + 
                   config['gamma'] * loss_feat)
            
            loss.backward()
            optimizer.step()
            
            train_loss += loss.item()
            _, predicted = torch.max(student_logits.data, 1)
            train_total += target.size(0)
            train_correct += (predicted == target).sum().item()
            
            # Print progress every 25 batches for more frequent updates
            if batch_idx % 25 == 0:
                progress_pct = (batch_idx / len(train_loader)) * 100
                print(f'Epoch {epoch+1}/{config["distill_epochs"]}, Batch {batch_idx}/{len(train_loader)} ({progress_pct:.1f}%), '
                      f'Loss: {loss.item():.4f} (CE: {loss_ce.item():.4f}, KD: {loss_kd.item():.4f}, '
                      f'Feat: {loss_feat.item():.4f})', flush=True)
        
        # Validation phase
        val_metrics = evaluate_model(student, val_loader, device, return_feats=False)
        val_loss = val_metrics['f1']  # Use F1 for scheduler (inverse)
        
        train_loss /= len(train_loader)
        train_acc = train_correct / train_total
        
        # Store history
        history['train_loss'].append(train_loss)
        history['train_acc'].append(train_acc)
        history['val_loss'].append(1.0 - val_metrics['f1'])  # Store as loss-like value
        history['val_acc'].append(val_metrics['accuracy'])
        history['val_f1'].append(val_metrics['f1'])
        
        print(f'\n{"="*60}')
        print(f'Epoch {epoch+1}/{config["distill_epochs"]} COMPLETE:')
        print(f'  Train Loss: {train_loss:.4f}, Train Acc: {train_acc:.4f}')
        print(f'  Val Acc: {val_metrics["accuracy"]:.4f}, Val F1: {val_metrics["f1"]:.4f}')
        print(f'  Val Precision: {val_metrics["precision"]:.4f}, Val Recall: {val_metrics["recall"]:.4f}')
        print(f'{"="*60}\n', flush=True)
        
        scheduler.step(val_loss)
        
        # Early stopping
        if val_metrics['f1'] > best_val_f1:
            best_val_f1 = val_metrics['f1']
            patience_counter = 0
            best_model_state = student.state_dict().copy()
            print(f'  New best model saved! (F1: {best_val_f1:.4f})')
        else:
            patience_counter += 1
            print(f'  No improvement. Patience: {patience_counter}/{config["early_stopping_patience"]}')
            
            if patience_counter >= config['early_stopping_patience']:
                print(f'\nEarly stopping triggered after {epoch+1} epochs')
                break
    
    # Restore best model
    if best_model_state is not None:
        student.load_state_dict(best_model_state)
        print('\nBest model weights restored')
    
    # ===== Phase 3: Final Evaluation =====
    print("\n" + "="*60)
    print("Phase 3: Final Evaluation")
    print("="*60)
    
    # Evaluate on test set
    print("\nEvaluating on test set...")
    test_metrics = evaluate_model(student, test_loader, device, return_feats=False)
    
    print(f"\nTest Set Results:")
    print(f"  Accuracy: {test_metrics['accuracy']:.4f}")
    print(f"  Precision: {test_metrics['precision']:.4f}")
    print(f"  Recall: {test_metrics['recall']:.4f}")
    print(f"  F1-Score: {test_metrics['f1']:.4f}")
    
    print("\nPer-Class Metrics:")
    for i, name in enumerate(class_names):
        print(f"  {name}:")
        print(f"    Precision: {test_metrics['precision_per_class'][i]:.4f}")
        print(f"    Recall: {test_metrics['recall_per_class'][i]:.4f}")
        print(f"    F1: {test_metrics['f1_per_class'][i]:.4f}")
    
    # Classification report
    print("\nClassification Report:")
    print(classification_report(
        test_metrics['labels'], test_metrics['predictions'],
        target_names=class_names
    ))
    
    # Confusion matrix
    cm = confusion_matrix(test_metrics['labels'], test_metrics['predictions'])
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
                xticklabels=class_names, yticklabels=class_names)
    plt.title('Confusion Matrix - Distilled Model')
    plt.ylabel('True Label')
    plt.xlabel('Predicted Label')
    plt.tight_layout()
    plt.savefig('confusion_matrix_distilled.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("\nConfusion matrix saved to confusion_matrix_distilled.png")
    
    # Distance-bin evaluation
    print("\nEvaluating per-distance bins...")
    distance_metrics = evaluate_distance_bins(student, test_data, test_loader, device, class_names)
    for bin_name, metrics in distance_metrics.items():
        print(f"\n[{bin_name.upper()}]")
        print(f"  Samples: {metrics['samples']}")
        print(f"  Accuracy: {metrics['accuracy']:.4f}")
        print(f"  F1: {metrics['f1']:.4f}")
    
    # Save model and metrics
    print("\n" + "="*60)
    print("Saving Model and Metrics")
    print("="*60)
    
    os.makedirs('models', exist_ok=True)
    
    # Save distilled student model
    distilled_model_path = 'models/pain_classification_model_distilled.pth'
    torch.save({
        'model_state_dict': student.state_dict(),
        'test_accuracy': test_metrics['accuracy'],
        'test_f1': test_metrics['f1'],
        'test_precision': test_metrics['precision'],
        'test_recall': test_metrics['recall'],
        'model_architecture': 'PainCNN',
        'num_classes': 3,
        'img_size': config['img_size'],
        'distillation_config': config
    }, distilled_model_path)
    print(f"Distilled model saved to: {distilled_model_path}")
    
    # Save training history
    with open('models/distillation_history.pkl', 'wb') as f:
        pickle.dump(history, f)
    print("Training history saved to: models/distillation_history.pkl")
    
    # Save metrics as JSON
    metrics_dict = {
        'test_metrics': {
            'accuracy': float(test_metrics['accuracy']),
            'precision': float(test_metrics['precision']),
            'recall': float(test_metrics['recall']),
            'f1': float(test_metrics['f1']),
            'precision_per_class': test_metrics['precision_per_class'],
            'recall_per_class': test_metrics['recall_per_class'],
            'f1_per_class': test_metrics['f1_per_class']
        },
        'distance_metrics': distance_metrics,
        'config': config
    }
    
    with open('models/distillation_metrics.json', 'w') as f:
        json.dump(metrics_dict, f, indent=2)
    print("Metrics saved to: models/distillation_metrics.json")
    
    print("\n" + "="*60)
    print("=== Distillation Training Complete ===")
    print("="*60)
    print(f"Best Validation F1: {best_val_f1:.4f}")
    print(f"Final Test Accuracy: {test_metrics['accuracy']:.4f}")
    print(f"Final Test F1: {test_metrics['f1']:.4f}")


if __name__ == "__main__":
    main()

