import os
from PIL import Image

def resize_icon(source_path):
    # Android sizes
    android_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    
    img = Image.open(source_path)
    
    # Android generation
    base_dir_android = 'android/app/src/main/res'
    for folder, size in android_sizes.items():
        folder_path = os.path.join(base_dir_android, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        icon_path = os.path.join(folder_path, 'ic_launcher.png')
        resized_img = img.resize((size, size), Image.Resampling.LANCZOS)
        resized_img.save(icon_path)
        
        round_icon_path = os.path.join(folder_path, 'ic_launcher_round.png')
        resized_img.save(round_icon_path)
        print(f"Generated Android icon in {folder} ({size}x{size})")

    # iOS sizes (based on Contents.json)
    ios_icons = [
        {"size": 40, "name": "Icon-App-20x20@2x.png"},
        {"size": 60, "name": "Icon-App-20x20@3x.png"},
        {"size": 29, "name": "Icon-App-29x29@1x.png"},
        {"size": 58, "name": "Icon-App-29x29@2x.png"},
        {"size": 87, "name": "Icon-App-29x29@3x.png"},
        {"size": 40, "name": "Icon-App-40x40@1x.png"},
        {"size": 80, "name": "Icon-App-40x40@2x.png"},
        {"size": 120, "name": "Icon-App-40x40@3x.png"},
        {"size": 120, "name": "Icon-App-60x60@2x.png"},
        {"size": 180, "name": "Icon-App-60x60@3x.png"},
        {"size": 20, "name": "Icon-App-20x20@1x.png"},
        {"size": 76, "name": "Icon-App-76x76@1x.png"},
        {"size": 152, "name": "Icon-App-76x76@2x.png"},
        {"size": 167, "name": "Icon-App-83.5x83.5@2x.png"},
        {"size": 1024, "name": "Icon-App-1024x1024@1x.png"},
    ]
    
    base_dir_ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    if os.path.exists(base_dir_ios):
        for icon in ios_icons:
            icon_path = os.path.join(base_dir_ios, icon["name"])
            size = icon["size"]
            resized_img = img.resize((size, size), Image.Resampling.LANCZOS)
            resized_img.save(icon_path)
            print(f"Generated iOS icon: {icon['name']} ({size}x{size})")
    else:
        print("iOS directory not found, skipping iOS icons.")

if __name__ == "__main__":
    resize_icon('assets/images/logo.png')
