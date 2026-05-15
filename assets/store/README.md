# Uzaapp - App Store Assets

This directory contains all assets needed for app store listings (Google Play Store, Apple App Store).

## 📁 Directory Structure

```
store/
├── icon-512.png                    # App icon (512x512)
├── feature-graphic-1024x500.png   # Feature graphic for Google Play
└── screenshots/
    ├── phone-portrait-*.png       # Phone screenshots (1080x1920)
    └── phone-landscape-*.png      # Landscape screenshots (1920x1080)
```

## 📱 Required Assets

### 1. App Icon (512x512 PNG)
- **File**: `icon-512.png`
- **Size**: 512x512 pixels
- **Format**: PNG, 32-bit
- **Requirements**:
  - Simple, recognizable logo
  - No text or transparency
  - Rounded corners will be applied by app stores automatically

### 2. Feature Graphic (1024x500 PNG)
- **File**: `feature-graphic-1024x500.png`
- **Size**: 1024x500 pixels
- **Format**: PNG or JPEG
- **Text**: "Buy & Sell Locally with Uzaapp"
- **Requirements**:
  - Visually appealing
  - Shows app purpose
  - No important content in center (will be overlaid with app icon on some platforms)

### 3. Screenshots (IMPORTANT)

#### Google Play Store Requirements:
- **Minimum**: 2 screenshots
- **Maximum**: 8 screenshots
- **Recommended sizes**:
  - Phone: 1080x1920 (9:16 ratio)
  - 7-inch tablet: 1200x1920
  - 10-inch tablet: 1440x2560

#### Apple App Store Requirements:
- **Minimum**: 1 screenshot per device size
- **Required sizes**:
  - iPhone 6.7" (1290x2796)
  - iPhone 6.5" (1284x2778)
  - iPhone 5.5" (1242x2208)

#### Recommended Screenshots to Capture:
1. **Home Screen** - Main discovery feed
2. **Product Detail** - Show product with price and details
3. **Shop Profile** - Boutique page with products
4. **Categories** - Browse by category
5. **Stories/Arrivages** - New arrivals feature
6. **User Profile** - Account management
7. **Search** - Product search functionality
8. **Checkout/Cart** - Shopping cart (if applicable)

## 🎨 Design Guidelines

### Colors
- Primary: `#008080` (Teal)
- Background: White `#FFFFFF`
- Text: Dark gray/black

### Typography
- Clean, modern fonts
- Good contrast for readability
- Consistent spacing

### Screenshot Best Practices
1. **Use real data** - Don't use placeholder content
2. **Show key features** - Highlight what makes Uzaapp unique
3. **Add captions** - Use app store's caption feature to explain each screenshot
4. **Localize** - Consider French/English versions for different markets
5. **High quality** - No blur, good lighting, clear text

## 🛠️ Generating Assets

### Automatic Generation
Run the Python script to generate base assets:

```bash
pip install Pillow
python generate_store_assets.py
```

This will create:
- ✅ 512x512 app icon from your logo
- ✅ Feature graphic with "Buy & Sell Locally with Uzaapp" text
- ✅ Screenshot placeholders

### Manual Steps
After running the script:
1. Replace placeholder screenshots with actual app screenshots
2. Review and customize the feature graphic if needed
3. Upload to app store consoles

## 📤 Upload Locations

### Google Play Console
1. Go to **Store Presence** > **Store Listing**
2. Upload:
   - App icon (512x512)
   - Feature graphic (1024x500)
   - Screenshots (minimum 2, up to 8)
   - Phone screenshots first, then tablet if available

### Apple App Store Connect
1. Go to **My Apps** > Select your app
2. Under **iOS App**, add screenshots for each device size
3. App icon is set in Xcode project (already configured via flutter_launcher_icons)

## 📝 Store Listing Text

### Short Description (80 characters max)
```
Buy & sell locally. Discover products, shops & new arrivals in your area.
```

### Full Description
```
Uzaapp connects local buyers and sellers in your community.

🛍️ DISCOVER PRODUCTS
Browse thousands of products from local shops near you. Find exactly what you're looking for with powerful search and categories.

🏪 VISIT SHOPS
Explore local boutiques, view their collections, and get directions to physical stores.

📢 NEW ARRIVALS
Stay updated with the latest products from your favorite shops. Never miss new stock!

📍 LOCATION-BASED
Find shops and products near you. Support local businesses in your community.

🔒 SECURE & PRIVATE
Your data is protected. Shop with confidence.

Download Uzaapp today and start discovering your local marketplace!
```

### Keywords
```
marketplace, local shopping, buy sell, community, boutique, products, nearby shops, DRC, Congo, Kinshasa
```

## ✅ Checklist Before Publishing

- [ ] App icon uploaded (512x512)
- [ ] Feature graphic uploaded (1024x500)
- [ ] Minimum 2 screenshots uploaded
- [ ] Screenshots show real app content
- [ ] Short description written (<80 chars)
- [ ] Full description written (<4000 chars)
- [ ] Keywords added
- [ ] Category selected (Shopping)
- [ ] Contact information added
- [ ] Privacy policy URL added
- [ ] Content rating completed
- [ ] Pricing set (Free)
- [ ] Countries/regions selected

## 🔗 Useful Links

- [Google Play Store Listing Guidelines](https://support.google.com/googleplay/android-developer/answer/9866151)
- [App Store Screenshot Guidelines](https://developer.apple.com/app-store/product-page/screenshots/)
- [App Icon Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)
