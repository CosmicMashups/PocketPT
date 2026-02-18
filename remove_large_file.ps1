# Script to remove large file from Git history
$filePath = "build/web/assets/assets/model/pain_recognition_model.onnx.data"

Write-Host "Removing large file from Git history: $filePath"

# Remove from index
git rm --cached $filePath

# Remove from all commits using filter-branch
git filter-branch --force --index-filter "git rm --cached --ignore-unmatch $filePath" --prune-empty --tag-name-filter cat -- --all

Write-Host "File removed from Git history. Run 'git push --force' to update remote (use with caution)."









