import os
import numpy as np
import pandas as pd
import cv2
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report, confusion_matrix
import torch
import torch.nn as nn
import torch.optim as optim
import torch.nn.functional as F
from torch.utils.data import Dataset, DataLoader
import torchvision.transforms as transforms
from torchvision.transforms import functional as TF
import torchvision.transforms as transforms
from torchvision.transforms import functional as TF
import torchvision.models as models
from torchvision.models import ResNet18_Weights, EfficientNet_B0_Weights
import matplotlib.pyplot as plt
import seaborn as sns
from collections import Counter
import pickle
import glob
import random
from PIL import Image
import io

# Set random seeds for reproducibility
np.random.seed(42)
torch.manual_seed(42)
random.seed(42)
if torch.cuda.is_available():
    torch.cuda.manual_seed(42)
    torch.cuda.manual_seed_all(42)


def downscale_upscale(pil_img: Image.Image) -> Image.Image:
    """Downscale and upscale to simulate distance blur"""
    w, h = pil_img.size
    scale = random.choice([0.5, 0.6, 0.7, 0.8, 0.9])
    small = pil_img.resize((max(1, int(w * scale)), max(1, int(h * scale))), Image.BILINEAR)
    return small.resize((w, h), Image.BILINEAR)


def jpeg_compress(pil_img: Image.Image) -> Image.Image:
    """Apply JPEG compression to simulate phone camera artifacts"""
    buf = io.BytesIO()
    pil_img.save(buf, format='JPEG', quality=random.randint(30, 70))
    buf.seek(0)
    return Image.open(buf).convert('RGB')


class PainDataset(Dataset):
    """Custom PyTorch dataset for pain classification"""
    
    def __init__(self, data_index, img_size=(224, 224), augment=False, balance=False):
        self.data_index = data_index
        self.img_size = img_size
        self.augment = augment
        self.balance = balance
        self.mapping = None
        
        # Synthetic Data Balancing Logic
        if balance:
            print("Applying synthetic data balancing...")
            indices = {0: [], 1: [], 2: []}
            for idx, (_, label) in enumerate(data_index):
                indices[label].append(idx)
            
            # Target count is the count of the majority class (Low)
            max_count = len(indices[0])
            print(f"  Majority class count: {max_count}")
            
            balanced_indices = []
            # Keep all Low samples
            balanced_indices.extend(indices[0])
            
            # Oversample Moderate
            if indices[1]:
                mod_factor = max_count // len(indices[1])
                mod_remainder = max_count % len(indices[1])
                balanced_indices.extend(indices[1] * mod_factor)
                balanced_indices.extend(indices[1][:mod_remainder])
                print(f"  Upsampled Moderate from {len(indices[1])} to {len(indices[1]) * mod_factor + mod_remainder}")
            
            # Oversample Severe
            if indices[2]:
                sev_factor = max_count // len(indices[2])
                sev_remainder = max_count % len(indices[2])
                balanced_indices.extend(indices[2] * sev_factor)
                balanced_indices.extend(indices[2][:sev_remainder])
                print(f"  Upsampled Severe from {len(indices[2])} to {len(indices[2]) * sev_factor + sev_remainder}")
                
            self.mapping = balanced_indices
            print(f"  Total balanced dataset size: {len(self.mapping)}")
        
        # Data augmentation transforms
        if augment:
            self.transform = transforms.Compose([
                transforms.ToPILImage(),
                transforms.Resize(img_size),
                transforms.RandomApply([transforms.Lambda(downscale_upscale)], p=0.5),
                transforms.RandomApply([transforms.GaussianBlur(kernel_size=3)], p=0.3),
                transforms.RandomApply([transforms.Lambda(jpeg_compress)], p=0.3),
                transforms.RandomRotation(10),
                transforms.RandomHorizontalFlip(),
                transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1),
                transforms.ToTensor(),
                transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
            ])
        else:
            self.transform = transforms.Compose([
                transforms.ToPILImage(),
                transforms.Resize(img_size),
                transforms.ToTensor(),
                transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
            ])
    
    def __len__(self):
        if self.balance and self.mapping:
            return len(self.mapping)
        return len(self.data_index)
    
    def __getitem__(self, index):
        if self.balance and self.mapping:
            real_index = self.mapping[index]
            img_path, label = self.data_index[real_index]
        else:
            img_path, label = self.data_index[index]
        
        try:
            # Load image
            img = cv2.imread(img_path)
            if img is None:
                print(f"Warning: Could not load image {img_path}")
                # Return a black image if loading fails
                img = np.zeros((*self.img_size, 3), dtype=np.uint8)
            else:
                img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            
            # Apply transforms
            img = self.transform(img)
            
            return img, torch.tensor(label, dtype=torch.long)
            
        except Exception as e:
            print(f"Error processing {img_path}: {e}")
            # Return a black image and label 0 if processing fails
            img = np.zeros((*self.img_size, 3), dtype=np.uint8)
            img = self.transform(img)
            return img, torch.tensor(0, dtype=torch.long)

def create_data_index(images_dir, labels_dir):
    """Create index of image paths and corresponding pain labels"""
    print("Creating data index...")
    
    data_index = []
    
    # Get all subject directories
    subject_dirs = [d for d in os.listdir(images_dir) if os.path.isdir(os.path.join(images_dir, d))]
    print(f"Found {len(subject_dirs)} subjects")
    
    for subject_id in subject_dirs:
        subject_img_dir = os.path.join(images_dir, subject_id)
        subject_label_dir = os.path.join(labels_dir, 'PSPI', subject_id)
        
        if not os.path.exists(subject_label_dir):
            print(f"Warning: No labels found for subject {subject_id}")
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
                        # PSPI typically ranges 0-16, map to our categories:
                        # Low: 0-3, Moderate: 4-7, Severe: 8+
                        if pspi_score <= 3:
                            pain_category = 0  # Low
                        elif pspi_score <= 7:
                            pain_category = 1  # Moderate
                        else:
                            pain_category = 2  # Severe
                        
                        img_path = os.path.join(img_seq_dir, img_file)
                        data_index.append((img_path, pain_category))
                        
                    except Exception as e:
                        print(f"Error reading label {label_file}: {e}")
                        continue
    
    if len(data_index) == 0:
        print("No data found! Please check your paths.")
        return None
    
    print(f"Total samples found: {len(data_index)}")
    
    # Print class distribution
    labels = [item[1] for item in data_index]
    class_counts = Counter(labels)
    print("Class distribution:")
    print(f"  Low (0): {class_counts[0]}")
    print(f"  Moderate (1): {class_counts[1]}")
    print(f"  Severe (2): {class_counts[2]}")
    
    return data_index

class PainCNN(nn.Module):
    """CNN model for pain classification using PyTorch"""
    
    def __init__(self, num_classes=3):
        super(PainCNN, self).__init__()
        
        # First Conv Block
        self.conv1_1 = nn.Conv2d(3, 32, kernel_size=3, padding=1)
        self.bn1_1 = nn.BatchNorm2d(32)
        self.conv1_2 = nn.Conv2d(32, 32, kernel_size=3, padding=1)
        self.pool1 = nn.MaxPool2d(2, 2)
        self.dropout1 = nn.Dropout2d(0.25)
        
        # Second Conv Block
        self.conv2_1 = nn.Conv2d(32, 64, kernel_size=3, padding=1)
        self.bn2_1 = nn.BatchNorm2d(64)
        self.conv2_2 = nn.Conv2d(64, 64, kernel_size=3, padding=1)
        self.pool2 = nn.MaxPool2d(2, 2)
        self.dropout2 = nn.Dropout2d(0.25)
        
        # Third Conv Block
        self.conv3_1 = nn.Conv2d(64, 128, kernel_size=3, padding=1)
        self.bn3_1 = nn.BatchNorm2d(128)
        self.conv3_2 = nn.Conv2d(128, 128, kernel_size=3, padding=1)
        self.pool3 = nn.MaxPool2d(2, 2)
        self.dropout3 = nn.Dropout2d(0.25)
        
        # Fourth Conv Block
        self.conv4_1 = nn.Conv2d(128, 256, kernel_size=3, padding=1)
        self.bn4_1 = nn.BatchNorm2d(256)
        self.pool4 = nn.MaxPool2d(2, 2)
        self.dropout4 = nn.Dropout2d(0.25)
        
        # Calculate the size of flattened features
        # After 4 pooling layers: 224 -> 112 -> 56 -> 28 -> 14
        self.feature_size = 256 * 14 * 14
        
        # Classifier
        self.fc1 = nn.Linear(self.feature_size, 512)
        self.bn_fc1 = nn.BatchNorm1d(512)
        self.dropout_fc1 = nn.Dropout(0.5)
        self.fc2 = nn.Linear(512, 256)
        self.dropout_fc2 = nn.Dropout(0.5)
        self.fc3 = nn.Linear(256, num_classes)
    
    def forward(self, x, return_feats=False):
        # First Conv Block
        x = F.relu(self.bn1_1(self.conv1_1(x)))
        x = F.relu(self.conv1_2(x))
        x = self.pool1(x)
        x = self.dropout1(x)
        
        # Second Conv Block
        x = F.relu(self.bn2_1(self.conv2_1(x)))
        x = F.relu(self.conv2_2(x))
        x = self.pool2(x)
        x = self.dropout2(x)
        
        # Third Conv Block
        x = F.relu(self.bn3_1(self.conv3_1(x)))
        x = F.relu(self.conv3_2(x))
        x = self.pool3(x)
        x = self.dropout3(x)
        
        # Fourth Conv Block
        x = F.relu(self.bn4_1(self.conv4_1(x)))
        x = self.pool4(x)
        x = self.dropout4(x)
        
        # Extract features for distillation (after pool4, before FC layers)
        features = x.view(x.size(0), -1)  # Flatten features
        
        # Classify
        x = F.relu(self.bn_fc1(self.fc1(features)))
        x = self.dropout_fc1(x)
        x = F.relu(self.fc2(x))
        x = self.dropout_fc2(x)
        logits = self.fc3(x)
        
        if return_feats:
            return logits, features
        return logits

class ResNetWrapper(nn.Module):
    def __init__(self, num_classes=3, pretrained=True):
        super(ResNetWrapper, self).__init__()
        weights = ResNet18_Weights.IMAGENET1K_V1 if pretrained else None
        self.model = models.resnet18(weights=weights)
        num_ftrs = self.model.fc.in_features
        self.model.fc = nn.Linear(num_ftrs, num_classes)
        
    def forward(self, x, return_feats=False):
        # Extract features
        x = self.model.conv1(x)
        x = self.model.bn1(x)
        x = self.model.relu(x)
        x = self.model.maxpool(x)

        x = self.model.layer1(x)
        x = self.model.layer2(x)
        x = self.model.layer3(x)
        x = self.model.layer4(x)

        x = self.model.avgpool(x)
        features = x.view(x.size(0), -1)
        
        logits = self.model.fc(features)
        
        if return_feats:
            return logits, features
        return logits

class EfficientNetWrapper(nn.Module):
    def __init__(self, num_classes=3, pretrained=True):
        super(EfficientNetWrapper, self).__init__()
        weights = EfficientNet_B0_Weights.IMAGENET1K_V1 if pretrained else None
        self.model = models.efficientnet_b0(weights=weights)
        num_ftrs = self.model.classifier[1].in_features
        self.model.classifier[1] = nn.Linear(num_ftrs, num_classes)
        
    def forward(self, x, return_feats=False):
        # Extract features
        features = self.model.features(x)
        features = self.model.avgpool(features)
        features = features.flatten(1)
        
        logits = self.model.classifier(features)
        
        if return_feats:
            return logits, features
        return logits

def build_model(model_name='resnet18', num_classes=3, pretrained=True):
    """
    Build model for pain classification
    
    Args:
        model_name: 'resnet18', 'efficientnet_b0', or 'custom'
        num_classes: Number of output classes
        pretrained: Whether to use pre-trained weights (for backbones)
    """
    if model_name == 'custom':
        return PainCNN(num_classes=num_classes)
    
    elif model_name == 'resnet18':
        return ResNetWrapper(num_classes=num_classes, pretrained=pretrained)
        
    elif model_name == 'efficientnet_b0':
        return EfficientNetWrapper(num_classes=num_classes, pretrained=pretrained)
        
    else:
        raise ValueError(f"Unknown model name: {model_name}")

def build_cnn_model(num_classes=3):
    """Legacy wrapper for backward compatibility"""
    return build_model('custom', num_classes=num_classes)

def plot_training_history(history):
    """Plot training history"""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))
    
    # Plot accuracy
    ax1.plot(history['train_acc'], label='Training Accuracy')
    ax1.plot(history['val_acc'], label='Validation Accuracy')
    ax1.set_title('Model Accuracy')
    ax1.set_xlabel('Epoch')
    ax1.set_ylabel('Accuracy')
    ax1.legend()
    
    # Plot loss
    ax2.plot(history['train_loss'], label='Training Loss')
    ax2.plot(history['val_loss'], label='Validation Loss')
    ax2.set_title('Model Loss')
    ax2.set_xlabel('Epoch')
    ax2.set_ylabel('Loss')
    ax2.legend()
    
    plt.tight_layout()
    plt.savefig('training_history.png', dpi=300, bbox_inches='tight')
    plt.show()

def main():
    # Configuration
    repo_root = os.path.dirname(os.path.abspath(__file__))
    dataset_root = os.path.join(repo_root, "dataset", "archive (2)")
    IMAGES_DIR = os.path.join(dataset_root, "Images", "Images")
    LABELS_DIR = os.path.join(dataset_root, "Frame_Labels", "Frame_Labels")
    BATCH_SIZE = 32  # Increased slightly as backbones are efficient
    IMG_SIZE = (224, 224)
    EPOCHS = 50
    MODEL_NAME = 'resnet18'  # Options: 'resnet18', 'efficientnet_b0', 'custom'
    USE_CLASS_BALANCING = True
    
    print("=== Pain Classification CNN Training ===")
    print(f"Images directory: {IMAGES_DIR}")
    print(f"Labels directory: {LABELS_DIR}")
    
    # Create data index
    data_index = create_data_index(IMAGES_DIR, LABELS_DIR)
    if data_index is None:
        return
    
    # Split data
    train_data, temp_data = train_test_split(data_index, test_size=0.3, 
                                           random_state=42, stratify=[item[1] for item in data_index])
    val_data, test_data = train_test_split(temp_data, test_size=0.5, 
                                         random_state=42, stratify=[item[1] for item in temp_data])
    
    print(f"\nDataset split:")
    print(f"Training samples: {len(train_data)}")
    print(f"Validation samples: {len(val_data)}")
    print(f"Test samples: {len(test_data)}")
    
    # Create datasets and data loaders
    train_dataset = PainDataset(train_data, img_size=IMG_SIZE, augment=True)
    val_dataset = PainDataset(val_data, img_size=IMG_SIZE, augment=False)
    test_dataset = PainDataset(test_data, img_size=IMG_SIZE, augment=False)
    
    # Build model and setup device
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"\nUsing device: {device}")

    # Calculate class weights for sampling
    if USE_CLASS_BALANCING:
        print("\nCalculating class weights for balancing...")
        # Get all labels from training data
        train_labels = [label for _, label in train_data]
        class_counts = Counter(train_labels)
        total_samples = len(train_labels)
        
        print(f"Train Class Counts: {dict(class_counts)}")
        
        # Calculate weights: total / (num_classes * class_count)
        class_weights = {cls: total_samples / (len(class_counts) * count) 
                        for cls, count in class_counts.items()}
        
        # Create sample weights for each training sample
        sample_weights = [class_weights[label] for _, label in train_data]
        sample_weights = torch.DoubleTensor(sample_weights)
        
        # Create sampler
        sampler = torch.utils.data.WeightedRandomSampler(
            weights=sample_weights,
            num_samples=len(sample_weights),
            replacement=True
        )
        
        # Calculate loss weights (inverse frequency)
        # Normalize so they sum to num_classes or average to 1
        loss_weights = torch.tensor([class_weights[i] for i in range(3)], dtype=torch.float)
        loss_weights = loss_weights.to(device)
        
        print(f"Class Weights: {class_weights}")
        print("Using WeightedRandomSampler and Weighted Loss")
        
        train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, sampler=sampler, num_workers=4)
    else:
        train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, shuffle=True, num_workers=4)
        loss_weights = None

    val_loader = DataLoader(val_dataset, batch_size=BATCH_SIZE, shuffle=False, num_workers=4)
    test_loader = DataLoader(test_dataset, batch_size=BATCH_SIZE, shuffle=False, num_workers=4)
    
    print(f"\nBuilding model: {MODEL_NAME}...")
    model = build_model(MODEL_NAME, num_classes=3, pretrained=True)
    model = model.to(device)
    
    # Setup optimizer and loss function
    # Use lower LR for pre-trained models
    lr = 0.0001 if MODEL_NAME != 'custom' else 0.001
    optimizer = optim.Adam(model.parameters(), lr=lr)
    criterion = nn.CrossEntropyLoss(weight=loss_weights if USE_CLASS_BALANCING else None)
    
    print("\nModel Summary:")
    total_params = sum(p.numel() for p in model.parameters())
    trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    print(f"Total parameters: {total_params:,}")
    print(f"Trainable parameters: {trainable_params:,}")
    
    # Training setup
    scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='min', factor=0.5, patience=5, min_lr=1e-7)
    
    # Early stopping parameters
    best_val_loss = float('inf')
    patience = 10
    patience_counter = 0
    best_model_state = None
    
    # Training history
    history = {
        'train_loss': [],
        'train_acc': [],
        'val_loss': [],
        'val_acc': []
    }
    
    print("\nStarting training...")
    
    for epoch in range(EPOCHS):
        # Training phase
        model.train()
        train_loss = 0.0
        train_correct = 0
        train_total = 0
        
        for batch_idx, (data, target) in enumerate(train_loader):
            data, target = data.to(device), target.to(device)
            
            optimizer.zero_grad()
            output = model(data)
            loss = criterion(output, target)
            loss.backward()
            optimizer.step()
            
            train_loss += loss.item()
            _, predicted = torch.max(output.data, 1)
            train_total += target.size(0)
            train_correct += (predicted == target).sum().item()
            
            if batch_idx % 50 == 0:
                print(f'Epoch {epoch+1}/{EPOCHS}, Batch {batch_idx}/{len(train_loader)}, '
                      f'Loss: {loss.item():.4f}')
        
        # Validation phase
        model.eval()
        val_loss = 0.0
        val_correct = 0
        val_total = 0
        
        with torch.no_grad():
            for data, target in val_loader:
                data, target = data.to(device), target.to(device)
                output = model(data)
                loss = criterion(output, target)
                
                val_loss += loss.item()
                _, predicted = torch.max(output.data, 1)
                val_total += target.size(0)
                val_correct += (predicted == target).sum().item()
        
        # Calculate averages
        train_loss /= len(train_loader)
        val_loss /= len(val_loader)
        train_acc = train_correct / train_total
        val_acc = val_correct / val_total
        
        # Store history
        history['train_loss'].append(train_loss)
        history['train_acc'].append(train_acc)
        history['val_loss'].append(val_loss)
        history['val_acc'].append(val_acc)
        
        print(f'Epoch {epoch+1}/{EPOCHS}:')
        print(f'  Train Loss: {train_loss:.4f}, Train Acc: {train_acc:.4f}')
        print(f'  Val Loss: {val_loss:.4f}, Val Acc: {val_acc:.4f}')
        
        # Learning rate scheduling
        scheduler.step(val_loss)
        
        # Early stopping
        if val_loss < best_val_loss:
            best_val_loss = val_loss
            patience_counter = 0
            best_model_state = model.state_dict().copy()
            print(f'  New best model saved!')
        else:
            patience_counter += 1
            print(f'  No improvement. Patience: {patience_counter}/{patience}')
            
            if patience_counter >= patience:
                print(f'Early stopping triggered after {epoch+1} epochs')
                break
    
    # Restore best model
    if best_model_state is not None:
        model.load_state_dict(best_model_state)
        print('Best model weights restored')
    
    # Plot training history
    plot_training_history(history)
    
    # Evaluate on test set
    print("\nEvaluating on test set...")
    model.eval()
    test_loss = 0.0
    test_correct = 0
    test_total = 0
    y_pred_classes = []
    y_true = []
    
    with torch.no_grad():
        for data, target in test_loader:
            data, target = data.to(device), target.to(device)
            output = model(data)
            loss = criterion(output, target)
            
            test_loss += loss.item()
            _, predicted = torch.max(output.data, 1)
            test_total += target.size(0)
            test_correct += (predicted == target).sum().item()
            
            y_pred_classes.extend(predicted.cpu().numpy())
            y_true.extend(target.cpu().numpy())
    
    test_loss /= len(test_loader)
    test_accuracy = test_correct / test_total
    
    print(f"Test Accuracy: {test_accuracy:.4f}")
    print(f"Test Loss: {test_loss:.4f}")
    
    y_pred_classes = np.array(y_pred_classes)
    y_true = np.array(y_true)
    
    # Classification report
    class_names = ['Low', 'Moderate', 'Severe']
    print("\nClassification Report:")
    print(classification_report(y_true, y_pred_classes, target_names=class_names))
    
    # Confusion matrix
    cm = confusion_matrix(y_true, y_pred_classes)
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
                xticklabels=class_names, yticklabels=class_names)
    plt.title('Confusion Matrix')
    plt.ylabel('True Label')
    plt.xlabel('Predicted Label')
    plt.savefig('confusion_matrix.png', dpi=300, bbox_inches='tight')
    plt.show()

    # Distance-binned evaluation (close/mid/far by face bbox area)
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

        # Compute ratios for test images in order
        test_img_paths = [p for (p, _) in test_data]
        ratios = [face_area_ratio(p) for p in test_img_paths]

        # Define bins by area fraction
        bins = {
            'close': [],  # > 0.08 (~>8% of frame)
            'mid': [],    # 0.03–0.08
            'far': []     # < 0.03
        }
        for idx, r in enumerate(ratios):
            if r > 0.08:
                bins['close'].append(idx)
            elif r >= 0.03:
                bins['mid'].append(idx)
            else:
                bins['far'].append(idx)

        def report_bin(name: str, indices: list):
            if not indices:
                print(f"No samples in {name} bin")
                return
            y_true_bin = y_true[indices]
            y_pred_bin = y_pred_classes[indices]
            acc = (y_true_bin == y_pred_bin).mean()
            print(f"\n[{name.upper()}] samples: {len(indices)}  Accuracy: {acc:.4f}")
            print(classification_report(y_true_bin, y_pred_bin, target_names=class_names, zero_division=0))

        report_bin('close', bins['close'])
        report_bin('mid', bins['mid'])
        report_bin('far', bins['far'])
    except Exception as e:
        print(f"Per-distance evaluation skipped: {e}")
    
    # Save model and related files
    print("\nSaving model...")
    os.makedirs('models', exist_ok=True)
    
    # Save PyTorch model
    torch.save({
        'model_state_dict': model.state_dict(),
        'optimizer_state_dict': optimizer.state_dict(),
        'test_accuracy': test_accuracy,
        'test_loss': test_loss,
        'model_architecture': MODEL_NAME,
        'num_classes': 3,
        'img_size': IMG_SIZE
    }, 'models/pain_classification_model.pth')
    
    # Save label encoder info
    label_info = {
        'classes': class_names,
        'class_mapping': {0: 'Low', 1: 'Moderate', 2: 'Severe'}
    }
    
    with open('models/label_info.pkl', 'wb') as f:
        pickle.dump(label_info, f)
    
    # Save training history
    with open('models/training_history.pkl', 'wb') as f:
        pickle.dump(history, f)
    
    print("\n=== Training Complete ===")
    print(f"Model saved to: models/pain_classification_model.pth")
    print(f"Label info saved to: models/label_info.pkl")
    print(f"Training history saved to: models/training_history.pkl")
    print(f"\nFinal Test Accuracy: {test_accuracy:.4f}")

if __name__ == "__main__":
    main()