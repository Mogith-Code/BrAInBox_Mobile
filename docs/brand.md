# Brand

<p align="center"><img src="logo_horizontal_1200.png" width="420" alt="BrAInBox logo"></p>

The original brand pack is in [`design/brand/`](../design/brand/README.md).
**Don't redraw or recolour the logo.** Use the files and the `AppLogo` widget.

## The one rule

> **Never render the wordmark SVGs in Flutter.**
> `brainbox-logo-horizontal*.svg` and `brainbox-logo-stacked*.svg` contain
> SVG `<text>`. flutter_svg can't use Poppins there, so the wordmark would
> show in the wrong font. In the apps, always use `AppLogo`. It draws the icon
> from `brainbox-icon.svg` and builds the wordmark in Flutter with Poppins Bold.
> The wordmark SVGs and PNGs are only for docs and the web.

Inside Flutter, only `brainbox-icon.svg` and `brainbox-mark.svg` are rendered.
Both are bundled in `brainbox_core` (paths in `BrandAssets`).

## `AppLogo` – which variant where

```dart
const AppLogo(variant: AppLogoVariant.stacked, size: 72);
const AppLogo(variant: AppLogoVariant.stacked, onDark: true, showTagline: true, size: 96);
const BrandAppBarTitle('Learn'); // small icon + title in an app bar
```

| Variant | Looks like | Use it for |
|---|---|---|
| `icon` | Gradient rounded square | App bars (`BrandAppBarTitle`), collapsed admin sidebar, small spaces |
| `mark` | Box + sprout, no background | Illustrations: `EmptyState` (default), `AiGeneratingLoader` |
| `horizontal` | Icon + wordmark side by side | Onboarding header, expanded admin sidebar |
| `stacked` | Icon above wordmark | Splash, auth screens, admin login, Settings → About |

- `size` is the height of the icon part. The wordmark and tagline scale with
  it, in the same proportions as the brand SVGs.
- `onDark: true` on dark or gradient backgrounds: the wordmark is white, with "AI" in `#A5F3FC`.
- `showTagline: true` adds "Study smarter. Fix what matters." (Inter Medium).
- The logo ignores the system text scale, so its proportions never change.

## Where the logo appears

| App | Place | What |
|---|---|---|
| Mobile | Launcher icon | Adaptive icon (Android 8+), from `apps/mobile/assets/brand/` |
| Mobile | Native splash | `#4F46E5` + `splash_logo_512.png` (also the Android 12 splash API) |
| Mobile | Flutter splash | Brand gradient + `stacked`, `onDark`, tagline, size 96, fade/scale-in |
| Mobile | Onboarding | `horizontal`, size 32, in the app bar |
| Mobile | Login, sign up, forgot password, verify email | `stacked`, size 72, above the form |
| Mobile | Home app bar | `BrandAppBarTitle('BrAInBox')` |
| Mobile | Learn / Practice / Insights / Community app bars | `BrandAppBarTitle(<tab title>)` |
| Mobile | Settings → About | `stacked` + tagline + app version |
| Mobile | Android app name | `android:label="BrAInBox"` |
| Admin | Browser tab | `web/favicon.png`, title "BrAInBox Admin" |
| Admin | PWA | `web/icons/*` and `web/manifest.json` (short name "BrAInBox") |
| Admin | Before Flutter loads | Stacked logo on `#F8FAFC` in `web/index.html`, removed on the first frame |
| Admin | Login | `stacked`, size 80, + "Admin portal" |
| Admin | Sidebar | `horizontal` 32 when expanded, `icon` 32 when collapsed |
| Admin | Top bar (small widths) | `icon` + page title |

If a Figma design places the logo differently, follow the Figma design.

## Colours

| Name | Hex | `AppColors` |
|---|---|---|
| Teal (gradient start) | `#0EA5A4` | `secondary` |
| Indigo (gradient end, primary) | `#4F46E5` | `primary` |
| Mint | `#6EE7B7` | `mint` |
| Amber (AI spark) | `#FCD34D` | `amber` |
| Ink (wordmark, text) | `#1E1B4B` | `ink` |
| Muted (tagline) | `#64748B` | `muted` |
| "AI" on dark | `#A5F3FC` | `aiHighlightOnDark` |
| Tagline on dark | `#E0E7FF` | `taglineOnDark` |
| Background | `#F8FAFC` | `background` |

Brand gradient: teal → indigo at 135° (top-left to bottom-right),
`AppColors.brandGradient`.

Fonts: **Poppins Bold** for the wordmark and headings, **Inter** for body
text and the tagline (via `google_fonts`).

## Regenerating icons and splash

The Android launcher icon and native splash are generated from
`apps/mobile/assets/brand/`, using `flutter_launcher_icons.yaml` and
`flutter_native_splash.yaml`:

```bash
melos run brand:generate
```

Commit the files it changes under `apps/mobile/android/app/src/main/res/`.

The admin web icons (`apps/admin/web/favicon.png` and `web/icons/*`) are
plain copies and resizes of the brand PNGs:

| File | Made from |
|---|---|
| `favicon.png` | `favicon_32.png` |
| `Icon-192.png` | `favicon_192.png` |
| `Icon-512.png` | `app_icon_1024.png`, resized |
| `Icon-maskable-*.png` | `adaptive_background_1024.png` + `adaptive_foreground_1024.png`, combined and resized |

If the brand pack changes, redo these with any image tool.
