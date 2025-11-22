# App Icon & Splash Screen Setup Guide

## 📋 Requirements

### 1️⃣ App Icon (1024×1024 PNG)

**Specifications:**
- **Canvas:** 1024×1024 px
- **Logo:** 600–650 px wide (~60% of canvas)
- **Padding:** ~20–25% on each side
- **Background:** Transparent (recommended) or solid color

**Visual Layout:**
```
+-------------------------+
|       Padding           |
|      +------+           |
|      | LOGO |           |
|      +------+           |
|       Padding           |
+-------------------------+
Canvas: 1024x1024 px
Logo: ~600-650 px wide
```

**File Location:** `assets/icons/app_icon.png`

---

### 2️⃣ Splash Screen (1200×1200 PNG)

**Specifications:**
- **Canvas:** 1200×1200 px (square)
- **Logo:** 600–700 px wide (~50–60% of canvas width)
- **Padding:** ~20–25% around logo
- **Background:** Transparent or solid color matching your splash screen

**Visual Layout:**
```
+-------------------------+
|       Padding           |
|      +------+           |
|      | LOGO |           |
|      +------+           |
|       Padding           |
+-------------------------+
Canvas: 1200x1200 px
Logo: ~600-700 px wide
```

**File Location:** `assets/images/splash.png`

---

## 🚀 Setup Steps

### Step 1: Prepare Your Images

1. **Create App Icon:**
   - Create a 1024×1024 px PNG
   - Place your logo (600–650px wide) centered
   - Save as `assets/icons/app_icon.png`

2. **Create Splash Screen:**
   - Create a 1200×1200 px PNG
   - Place your logo (600–700px wide) centered
   - Save as `assets/images/splash.png`

### Step 2: Run Flutter Commands

```bash
# Get dependencies
flutter pub get

# Generate app icons
flutter pub run flutter_launcher_icons:main

# Generate splash screens
flutter pub run flutter_native_splash:create

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

---

## ✅ Configuration (Already Set Up)

Your `pubspec.yaml` is already configured:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.4
  flutter_native_splash: ^2.4.7

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"

flutter_native_splash:
  color: "#ffffff"
  image: assets/images/splash.png
  android: true
  ios: true
```

---

## 📝 Key Notes

- **App Icon:** 1024×1024 canvas, logo ~60%, padding ~20–25%
- **Splash Screen:** 1200×1200 canvas, logo ~50–60%, padding ~20–25%
- **Transparent background** is recommended for both (unless your brand color is solid)
- If splash looks blurry, ensure logo is ~50–60% of canvas width and centered

---

## 🔧 Troubleshooting

**If icons don't appear:**
1. Make sure images are in the correct folders
2. Run `flutter clean` then rebuild
3. Uninstall the app from device/emulator and reinstall

**If splash is blurry:**
- Ensure logo is not too large (should be ~50–60% of canvas width)
- Keep logo centered with padding around it
- Use high-quality source images

