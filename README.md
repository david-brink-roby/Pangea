# Pangea Web App

This document provides instructions for rebuilding the Pangea web app and managing its assets.

---

## 1. Rebuilding the Webpage

1. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```
2. **Compile for web target**:
   ```bash
   flutter build web --no-tree-shake-icons
   ```
   - The compiled files are written to `build/web/`.
   - Serve `build/web/` as the document root on your web server (e.g., nginx, Apache).
3. **Local preview** in a browser:
   ```bash
   flutter run -d chrome
   ```

---

## 2. Updating Images & Assets

All visual assets live in the `assets/` directory. When replacing or adding images (background, base maps, overlays, or legend keys), follow these steps:

1. **Prepare your PNG files**:

   - **Background**: `assets/background.png` (e.g., custom map background).
   - **Base continents**: `assets/<continent>.png` (e.g., `assets/greenland.png`).
   - **Overlays** (optional):
     - `assets/<continent>_fossils.png`
     - `assets/<continent>_glaciers.png`
     - `assets/<continent>_rocks.png`
   - **Legend keys**:
     - `assets/key_fossils.png`
     - `assets/key_glaciers.png`
     - `assets/key_rocks.png`
   - Ensure PNGs preserve transparency.

2. **Copy files** into your project’s `assets/` folder.

3. \*\*Update the assets listed in pubspec.yaml\*\*\`\`:

   ```yaml
   flutter:
     assets:
       - assets/background.png
       - assets/rotate_icon.png
       - assets/<continent>.png
       - assets/<continent>_fossils.png
       - assets/<continent>_glaciers.png
       - assets/<continent>_rocks.png
       - assets/key_fossils.png
       - assets/key_glaciers.png
       - assets/key_rocks.png
   ```

4. **Re-run the build**:

   ```bash
   flutter pub get
   flutter build web --no-tree-shake-icons
   ```

---

### Specifying Layers for Each Continent

In your Dart code (`pangea_map.dart`), you control which overlays appear on each continent by editing the `continents` list inside `_PangeaMapState`:

```dart
final List<Continent> continents = const [
  Continent('greenland', []),                      // no overlays
  Continent('north_america', ['rocks']),           // only rocks
  Continent('south_america', ['glaciers','fossils','rocks']),
  // ... remaining continents
];
```

Each string in the overlays list must match one of the available overlay asset suffixes:

- `fossils` → `assets/<continent>_fossils.png`
- `glaciers` → `assets/<continent>_glaciers.png`
- `rocks`    → `assets/<continent>_rocks.png`

After updating this list, rebuild the app to see the changes.

---

## 3. Dump Coords Button Note

When you significantly change continent images or overlays, re-calibrate starting positions:

1. In `pangea_map.dart`, uncomment the Dump Coords button in the Layers menu:
   ```dart
   ElevatedButton(
     onPressed: _dumpCoords,
     child: const Text('Dump coords'),
   ),
   ```
2. Run the app, click **Dump coords**, then copy the printed offsets into your `absoluteStart` or `normalizedStart` map.
3. Comment out or remove the Dump Coords button before deploying.

---

## 4. Deployment Options

### 4.1 GitHub Pages

1. **Build for web**:
   ```bash
   flutter build web --no-tree-shake-icons
   ```
2. **Create or clear** your `docs/` folder and **copy** the new build into it:
   ```bash
     if (Test-Path docs) {
    Remove-Item docs\* -Recurse -Force
    } else {
    New-Item -ItemType Directory docs
   }
     Copy-Item -Path build\web\* -Destination docs -Recurse
   ```
3. **Commit & push** to GitHub:
   ```bash
   git add docs/
   git commit -m "Update Pangea web build"
   git push
   ```
4. Your GitHub Pages site (configured to `docs/` on `main` or the `gh-pages` branch) will update automatically.

   **Note:** If you encounter a white or blank screen after deployment, open `docs/index.html` (or `build/web/index.html` before copying) and change:
   ```html
   <base href="/">
   ```
   to:
   ```html
   <base href="./">
   ```
   Also note: if you run `flutter run -d chrome` locally, the embedded `base href="./`" will cause the app to fail to compile, remove the "." before running the command to test locally.

### 4.2 WordPress

1. Upload `build/web/` to your WordPress server (via FTP or hosting panel) under a directory (e.g., `/pangea-app/`).
2. Embed in a page/post with an `<iframe>` shortcode:
   ```html
   <iframe src="https://your-domain.com/pangea-app/index.html"
           width="100%" height="800" frameborder="0"></iframe>
   ```
3. Adjust width/height as needed for responsiveness.

