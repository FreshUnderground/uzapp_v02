# Uzaapp - Screenshot Capture Guide

## 📸 How to Capture App Screenshots for App Stores

### Method 1: Using Flutter DevTools (Recommended)

1. **Run your app in debug mode:**
   ```powershell
   flutter run
   ```

2. **Open Flutter DevTools:**
   - Press `v` in the terminal to open DevTools in browser
   - Or visit: http://127.0.0.1:9100

3. **Navigate to each screen you want to capture:**
   - Home/Discovery feed
   - Product detail page
   - Shop profile
   - Categories
   - Stories/Arrivages
   - User profile
   - Search results

4. **Take screenshots:**
   - In DevTools, go to the "Inspector" tab
   - Click the camera icon 📷
   - Screenshot will be saved to your computer

### Method 2: Using Android Emulator

1. **Open Android Emulator**
2. **Navigate to the screen**
3. **Take screenshot:**
   - Click the camera icon in the emulator toolbar
   - Or use: `Ctrl + S` (Windows)
   - Screenshots saved to: `Pictures/Screenshots/`

### Method 3: Using Physical Android Device

1. **Enable USB debugging** on your phone
2. **Connect via USB**
3. **Navigate to each screen**
4. **Take screenshot:**
   - Press `Power + Volume Down` buttons simultaneously
   - Or use ADB command:
     ```powershell
     adb shell screencap -p /sdcard/screenshot.png
     adb pull /sdcard/screenshot.png
     ```

### Method 4: Using iOS Simulator (Mac only)

1. **Open iOS Simulator**
2. **Navigate to the screen**
3. **Take screenshot:**
   - Press `Cmd + S`
   - Or: File → Save Screenshot
   - Screenshots saved to Desktop

---

## 📋 Required Screenshots Checklist

### Google Play Store (Minimum 2, Maximum 8)

- [ ] **Home Screen** - Discovery feed showing products
- [ ] **Product Detail** - Product with price, description, shop info
- [ ] **Shop Profile** - Boutique page with products list
- [ ] **Categories** - Browse products by category
- [ ] **New Arrivals** - Stories/Arrivages feature
- [ ] **Search** - Search results page
- [ ] **User Profile** - Account settings
- [ ] **Map/Location** - Shop location view (if applicable)

### Apple App Store (Required Device Sizes)

**iPhone 6.7" Display (1290 x 2796) - Required:**
- [ ] Home Screen
- [ ] Product Detail
- [ ] Shop Profile

**iPhone 6.5" Display (1284 x 2778) - Required:**
- [ ] Home Screen
- [ ] Product Detail

**iPhone 5.5" Display (1242 x 2208) - Optional:**
- [ ] Home Screen

---

## 🎨 Screenshot Best Practices

### DO ✅
1. **Use real data** - Show actual products, not placeholders
2. **Good lighting** - Ensure screens are clear and readable
3. **Remove sensitive info** - Hide personal data, phone numbers
4. **Show key features** - Highlight what makes Uzaapp unique
5. **Use latest app version** - Capture from the final build
6. **Consistent theme** - All screenshots should match
7. **Portrait orientation** - Primary focus on phone portrait (1080x1920)

### DON'T ❌
1. **Don't use mockups** - Use real app screens
2. **Don't include debug info** - No debug banners or logs
3. **Don't show empty states** - Populate with sample data
4. **Don't use low resolution** - Minimum 1080x1920
5. **Don't include personal data** - Protect privacy

---

## 📐 Screenshot Specifications

### Google Play Store
- **Format**: PNG or JPEG
- **Minimum dimension**: 320px
- **Maximum dimension**: 3840px
- **Recommended**: 1080x1920 (Full HD portrait)
- **Aspect ratio**: 16:9 or 9:16

### Apple App Store
- **Format**: PNG or JPEG (no alpha/transparency)
- **Color space**: RGB
- **Required sizes**:
  - iPhone 6.7": 1290 x 2796 pixels
  - iPhone 6.5": 1284 x 2778 pixels  
  - iPhone 5.5": 1242 x 2208 pixels

---

## 🛠️ Post-Processing (Optional)

### Add Device Frames
Use these tools to put screenshots in phone frames:
- **Online**: https://mockupphone.com/
- **Figma**: Search "Phone Mockup" in community
- **Canva**: Use phone frame templates

### Add Captions/Annotations
- Use **Canva** or **Figma** to add text overlays
- Highlight key features with arrows or circles
- Keep text minimal and readable

### Recommended Tools
- **GIMP** (Free): https://www.gimp.org/
- **Photopea** (Free, Online): https://www.photopea.com/
- **Canva** (Free tier): https://www.canva.com/
- **Figma** (Free tier): https://www.figma.com/

---

## 📁 Organize Your Screenshots

Save screenshots in this structure:
```
assets/store/screenshots/
├── google-play/
│   ├── screenshot-01-home.png
│   ├── screenshot-02-product.png
│   ├── screenshot-03-shop.png
│   └── ...
├── app-store/
│   ├── iphone-6.7-inch/
│   │   ├── screenshot-01-home.png
│   │   └── screenshot-02-product.png
│   └── iphone-6.5-inch/
│       ├── screenshot-01-home.png
│       └── screenshot-02-product.png
└── raw/
    └── (original captures)
```

---

## 🚀 Quick Command to Resize Screenshots

If you need to resize screenshots to exact dimensions:

```powershell
# Using ImageMagick (install first: choco install imagemagick)
magick input.png -resize 1080x1920^ -gravity center -extent 1080x1920 output.png
```

---

## 📝 Caption Suggestions for App Store

### Google Play Store (80 characters max per caption)

1. **Home**: "Discover products from local shops near you"
2. **Product**: "View detailed product info and pricing"
3. **Shop**: "Explore local boutiques and their collections"
4. **Categories**: "Browse by category to find what you need"
5. **Arrivals**: "Stay updated with new arrivals from favorite shops"
6. **Search**: "Quickly find products with powerful search"
7. **Profile**: "Manage your account and preferences"
8. **Location**: "Get directions to physical shop locations"

---

## 🎯 Final Checklist Before Upload

- [ ] All screenshots are high quality (no blur)
- [ ] Screenshots show real app content
- [ ] No sensitive/personal information visible
- [ ] Consistent visual style across all screenshots
- [ ] Proper dimensions for each platform
- [ ] Captions written for each screenshot
- [ ] Saved in correct folder structure
- [ ] Tested on both light and dark backgrounds

---

## 📞 Need Help?

- **Google Play Guidelines**: https://support.google.com/googleplay/android-developer/answer/9866151
- **Apple Guidelines**: https://developer.apple.com/app-store/product-page/screenshots/
- **Flutter Screenshot Package**: https://pub.dev/packages/screenshot

---

**Good luck with your app store submission! 🚀**
