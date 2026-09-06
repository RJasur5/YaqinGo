import os
import re

lib_path = r'C:\Users\Jasur\.gemini\antigravity\scratch\findix\findix_app\lib'

def process_file(file_path):
    if 'theme.dart' in file_path or 'gradient_button.dart' in file_path:
        return # Skip theme mapping and button texts which should stay white
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replacements:
    # Colors.white.withValues(alpha: X) -> AppColors.textPrimary.withValues(alpha: X)
    content = re.sub(r'Colors\.white\.withValues', r'AppColors.textPrimary.withValues', content)
    
    # Colors.white -> AppColors.textPrimary
    content = re.sub(r'Colors\.white', r'AppColors.textPrimary', content)
    
    # AppColors.splashGradient is used in full-screen backgrounds. We updated it to a light blue gradient.
    # So dark texts will show up correctly now!

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

for root, _, files in os.walk(lib_path):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

print("Conversion complete.")
