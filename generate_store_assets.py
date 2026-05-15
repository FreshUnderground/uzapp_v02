#!/usr/bin/env python3
"""
Generate app store assets for Uzaapp
Creates:
- 512x512 app icon
- Feature graphic (1024x500)
- Placeholder for screenshots
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Paths
BASE_DIR = os.path.join(os.path.dirname(__file__), 'assets', 'store')
LOGO_PATH = os.path.join(os.path.dirname(__file__), 'assets', 'logo.png')

def create_app_icon():
    """Create 512x512 app icon from existing logo"""
    print("Creating 512x512 app icon...")
    
    # Open and resize logo
    logo = Image.open(LOGO_PATH)
    logo = logo.resize((512, 512), Image.Resampling.LANCZOS)
    
    # Save to store directory
    icon_path = os.path.join(BASE_DIR, 'icon-512.png')
    logo.save(icon_path, 'PNG')
    print(f"✓ Saved: {icon_path}")
    
    return icon_path

def create_feature_graphic():
    """Create 1024x500 feature graphic with text"""
    print("Creating feature graphic (1024x500)...")
    
    # Create background
    width, height = 1024, 500
    bg_color = (0, 128, 128)  # Teal color from your theme
    image = Image.new('RGB', (width, height), bg_color)
    draw = ImageDraw.Draw(image)
    
    # Add logo in center-left
    logo = Image.open(LOGO_PATH)
    logo_size = 200
    logo = logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
    logo_x = 100
    logo_y = (height - logo_size) // 2
    image.paste(logo, (logo_x, logo_y), logo if logo.mode == 'RGBA' else None)
    
    # Add text
    try:
        # Try to use a nice font, fallback to default
        font = ImageFont.truetype("arial.ttf", 48)
    except:
        font = ImageFont.load_default()
    
    text = "Buy & Sell Locally with Uzaapp"
    text_color = (255, 255, 255)
    
    # Calculate text position (right side)
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    text_x = logo_x + logo_size + 100
    text_y = (height - text_height) // 2
    
    # Draw text with shadow for better visibility
    shadow_offset = 3
    draw.text((text_x + shadow_offset, text_y + shadow_offset), text, 
              fill=(0, 0, 0, 128), font=font)
    draw.text((text_x, text_y), text, fill=text_color, font=font)
    
    # Save
    feature_path = os.path.join(BASE_DIR, 'feature-graphic-1024x500.png')
    image.save(feature_path, 'PNG')
    print(f"✓ Saved: {feature_path}")
    
    return feature_path

def create_screenshot_placeholders():
    """Create placeholder structure for screenshots"""
    print("Creating screenshot placeholders...")
    
    screenshot_dir = os.path.join(BASE_DIR, 'screenshots')
    
    # Common phone sizes for app stores
    sizes = {
        'phone-portrait': (1080, 1920),
        'phone-landscape': (1920, 1080),
    }
    
    for name, (w, h) in sizes.items():
        # Create placeholder
        bg_color = (240, 240, 240)
        image = Image.new('RGB', (w, h), bg_color)
        draw = ImageDraw.Draw(image)
        
        # Add text
        try:
            font = ImageFont.truetype("arial.ttf", 72)
        except:
            font = ImageFont.load_default()
        
        text = f"{name}\n{w}x{h}\nScreenshot"
        text_color = (128, 128, 128)
        
        # Center text
        bbox = draw.multiline_textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        text_x = (w - text_width) // 2
        text_y = (h - text_height) // 2
        
        draw.multiline_text((text_x, text_y), text, fill=text_color, font=font, align='center')
        
        # Save
        screenshot_path = os.path.join(screenshot_dir, f'{name}-placeholder.png')
        image.save(screenshot_path, 'PNG')
        print(f"✓ Saved: {screenshot_path}")

def main():
    print("=" * 50)
    print("Uzaapp - App Store Assets Generator")
    print("=" * 50)
    print()
    
    # Create app icon
    create_app_icon()
    print()
    
    # Create feature graphic
    create_feature_graphic()
    print()
    
    # Create screenshot placeholders
    create_screenshot_placeholders()
    print()
    
    print("=" * 50)
    print("✓ All assets generated successfully!")
    print("=" * 50)
    print()
    print("Generated files:")
    print(f"  📱 App Icon: {os.path.join(BASE_DIR, 'icon-512.png')}")
    print(f"  🖼️ Feature Graphic: {os.path.join(BASE_DIR, 'feature-graphic-1024x500.png')}")
    print(f"  📸 Screenshot placeholders: {os.path.join(BASE_DIR, 'screenshots', '*.png')}")
    print()
    print("Next steps:")
    print("  1. Take actual screenshots of your app")
    print("  2. Replace placeholder screenshots with real ones")
    print("  3. Upload to Google Play Console / Apple App Store Connect")

if __name__ == '__main__':
    main()
