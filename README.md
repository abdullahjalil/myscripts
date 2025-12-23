# ⚔️ Gothic Knight Hyprland - One-Click Installer

A complete, automated installer for a gothic knight-themed Hyprland environment on Arch Linux. Install everything with a single script - from bare metal to a fully themed desktop.

## 🎯 What This Does

This script performs a **complete automated installation** including:

✅ All required packages (Hyprland, Waybar, Rofi, etc.)  
✅ AUR helper (yay) if not present  
✅ Custom Gothic Knight GTK theme  
✅ GTK configuration matching the Hyprland theme  
✅ All configuration files (Hyprland, Waybar, Rofi, Dunst, Kitty, Swaylock)  
✅ Utility scripts (volume, brightness, screenshots)  
✅ Nemo file manager integration  
✅ System services (NetworkManager, Bluetooth)  
✅ Sample wallpapers  
✅ Session file for login managers  

**No manual configuration needed!**

## 🚀 Quick Start

### One-Line Install

```bash
curl -O https://your-url/setup-gothic-knight.sh
chmod +x setup-gothic-knight.sh
./setup-gothic-knight.sh
```

### Or Download and Run

```bash
# Download the script
# Make it executable
chmod +x setup-gothic-knight.sh

# Run it
./setup-gothic-knight.sh
```

That's it! The script will:
1. Check your system
2. Install all packages
3. Configure everything
4. Set up themes
5. Create all config files

## 📋 Requirements

- **Arch Linux** (or Arch-based distro)
- **Internet connection** (for package downloads)
- **Normal user account** (don't run as root!)
- **Sudo access** (you'll be prompted for password)

## 🎨 What You Get

### Visual Theme
- **Color Scheme**: Deep crimsons (#8b0000), blacks, and gold (#d4af37)
- **Aesthetic**: Medieval gothic knight theme
- **Transparency**: Subtle window opacity for depth
- **Animations**: Smooth, weighty transitions (like armor)

### Components Installed

#### Core Compositor
- Hyprland (latest version)
- Hyprpaper (wallpaper)
- Hyprlock/Swaylock (screen lock)
- XDG Desktop Portal

#### User Interface
- Waybar (themed status bar)
- Rofi (gothic app launcher)
- Dunst (notification daemon)
- Kitty (GPU-accelerated terminal)

#### Applications
- Firefox (web browser)
- Nemo (file manager with gothic theme)
- Pavucontrol (audio control)
- Network Manager
- Blueman (Bluetooth)

#### Utilities
- Brightnessctl (brightness control)
- Playerctl (media control)
- Grim + Slurp (screenshots)
- Cliphist (clipboard manager)
- Btop/Htop (system monitors)

### GTK Theme
Custom "Gothic-Knight" GTK theme automatically applied to:
- GTK-2.0 applications
- GTK-3.0 applications  
- GTK-4.0 applications
- Papirus-Dark icons
- Consistent color scheme throughout

## 🎮 Key Features

### Modern Hyprland Features
- Dynamic tiling with dwindle layout
- Smooth bezier curve animations
- Blur effects on bars and menus
- Custom shadow effects
- Workspace gestures
- Window swallowing (terminal)

### Gothic Styling
- Crimson and gold color palette
- Medieval-inspired icons (⚔️ 🛡️ 🗡️)
- Ornamental borders and gradients
- Dark atmospheric backgrounds
- Consistent theming across all apps

### Practical Features
- Volume/brightness notifications
- Screenshot utilities (multiple modes)
- Clipboard history
- Media key support
- Battery monitoring
- Temperature sensors
- Network status

## ⌨️ Key Bindings

### Essential
```
SUPER + Return       → Terminal
SUPER + D           → App launcher
SUPER + B           → Browser
SUPER + E           → File manager
SUPER + L           → Lock screen
SUPER + Q           → Close window
```

### Window Navigation (Vim-style)
```
SUPER + H/J/K/L     → Move focus
SUPER + SHIFT + H/J/K/L → Move window
```

### Workspaces
```
SUPER + 1-9         → Switch workspace
SUPER + SHIFT + 1-9 → Move to workspace
SUPER + S           → Scratchpad
```

### Screenshots
```
Print Screen        → Area to clipboard
SHIFT + Print       → Full screen to clipboard
SUPER + Print       → Save area to file
```

Full key binding list available after installation in `~/gothic-knight-quickstart.txt`

## 🔧 What Gets Installed

### Official Packages
```
Core: hyprland, waybar, rofi-wayland, dunst, kitty, swaylock, swayidle
Apps: firefox, nemo, pavucontrol, blueman
Utils: brightnessctl, playerctl, wl-clipboard, grim, slurp
Fonts: jetbrains-mono-nerd, font-awesome, noto-fonts
Theme: gtk3, gtk4, papirus-icon-theme, lxappearance
```

### AUR Packages (optional, if yay/paru available)
```
grimblast-git, hyprpicker, wlogout
```

### Custom Components
```
Gothic-Knight GTK theme (created by script)
All configuration files
Utility scripts
```

## 📂 File Structure After Install

```
~/.config/
├── hypr/
│   ├── hyprland.conf          # Main config
│   ├── hyprpaper.conf         # Wallpaper config
│   ├── scripts/
│   │   ├── volume.sh          # Volume control
│   │   ├── brightness.sh      # Brightness control
│   │   └── screenshot.sh      # Screenshot utility
│   └── wallpapers/
│       ├── knight-main.jpg    # Main wallpaper
│       ├── knight-alt.jpg     # Alt wallpaper
│       └── knight-lock.jpg    # Lock screen
├── waybar/
│   ├── config                 # Waybar modules
│   └── style.css              # Gothic styling
├── rofi/
│   ├── config.rasi
│   └── gothic-knight.rasi     # Theme
├── dunst/
│   └── dunstrc                # Notifications
├── kitty/
│   └── kitty.conf             # Terminal theme
├── swaylock/
│   └── config                 # Lock screen
└── gtk-3.0/
    └── settings.ini           # GTK theme

~/.themes/
└── Gothic-Knight/             # Custom GTK theme
    ├── gtk-3.0/
    └── gtk-4.0/
```

## 🎨 Customization

### Change Colors

Edit `~/.config/hypr/hyprland.conf`:
```conf
# Find these lines and change colors:
col.active_border = rgba(8b0000ff) rgba(450a0aff) 45deg  # Crimson gradient
```

Edit `~/.config/waybar/style.css`:
```css
/* Main colors */
#8b0000  /* Dark crimson */
#d4af37  /* Gold */
#0a0000  /* Near black */
```

### Change Wallpapers

Replace images in `~/.config/hypr/wallpapers/`:
- `knight-main.jpg` - Main desktop wallpaper
- `knight-alt.jpg` - Alternative wallpaper
- `knight-lock.jpg` - Lock screen background

**Recommended sources:**
- Unsplash: "dark medieval knight"
- Wallhaven: "gothic knight armor"
- ArtStation: "dark fantasy knight"

### Modify GTK Theme

Edit `~/.themes/Gothic-Knight/gtk-3.0/gtk.css` to customize colors.

Then run: `lxappearance` to apply changes.

## 🐛 Troubleshooting

### Script fails with "not found"
```bash
# Make sure you're on Arch Linux
cat /etc/arch-release

# Make script executable
chmod +x setup-gothic-knight.sh
```

### Hyprland won't start
```bash
# Check logs
journalctl --user -u hyprland

# Verify installation
which Hyprland

# Try from TTY (Ctrl+Alt+F2)
Hyprland
```

### Waybar not appearing
```bash
# Restart waybar
killall waybar
waybar &

# Check for errors
waybar 2>&1 | grep error
```

### GTK theme not applying
```bash
# Run theme selector
lxappearance

# Select "Gothic-Knight" theme
# Select "Papirus-Dark" icons
```

### No wallpaper
```bash
# Check hyprpaper
killall hyprpaper
hyprpaper &

# Verify wallpaper exists
ls ~/.config/hypr/wallpapers/
```

### Audio not working
```bash
# Open audio control
pavucontrol

# Or check with
wpctl status
```

## 🔄 Updating

To update configurations:
```bash
# Re-run the script (safe - won't duplicate)
./setup-gothic-knight.sh

# Or manually update specific configs
nano ~/.config/hypr/hyprland.conf
hyprctl reload
```

## 🗑️ Uninstalling

To remove Gothic Knight setup:
```bash
# Remove configurations
rm -rf ~/.config/hypr
rm -rf ~/.config/waybar
rm -rf ~/.config/rofi
rm -rf ~/.config/dunst
rm -rf ~/.config/kitty
rm -rf ~/.config/swaylock
rm -rf ~/.themes/Gothic-Knight

# Remove packages (optional)
sudo pacman -Rns hyprland waybar rofi-wayland dunst kitty

# Restore default GTK settings
gtk3-demo  # Will use default theme
```

## 📖 Additional Resources

- **Hyprland Wiki**: https://wiki.hyprland.org
- **Waybar Wiki**: https://github.com/Alexays/Waybar/wiki
- **r/unixporn**: For inspiration and community support
- **Quick Reference**: Check `~/gothic-knight-quickstart.txt` after install

## 🤝 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review logs: `journalctl --user -u hyprland`
3. Verify all files were created: `ls ~/.config/hypr`
4. Re-run the script (it's idempotent)

## ✨ Features Highlights

### What Makes This Special

1. **Truly One-Click**: Single script does everything
2. **Complete Theme**: GTK apps match Hyprland perfectly
3. **Production Ready**: All utilities and scripts included
4. **Idempotent**: Safe to run multiple times
5. **Modern**: Uses latest Hyprland syntax (2025)
6. **Portable**: Works on any Arch-based system

### Why Gothic Knight Theme?

- **Unique Aesthetic**: Stand out from generic blue/purple rices
- **Professional**: Dark theme easy on the eyes
- **Cohesive**: Every element matches the theme
- **Practical**: Not just pretty, fully functional

## 📜 License

Free to use, modify, and distribute. No attribution required but appreciated.

## ⚔️ Final Words

This installer brings the medieval aesthetic of knights and castles to modern Linux desktops. Every detail, from the crimson borders to the gold highlights, has been carefully crafted to create a cohesive, atmospheric experience.

Whether you're a tiling window manager enthusiast or new to Hyprland, this setup provides a complete, ready-to-use environment that's both beautiful and functional.

**May your workflow be as legendary as the knights of old!**

---

*"Not all who wander in tiling window managers are lost"*

## 🎬 Quick Start Video Script

```bash
# 1. Download script
curl -O [url]/setup-gothic-knight.sh

# 2. Make executable
chmod +x setup-gothic-knight.sh

# 3. Run
./setup-gothic-knight.sh

# 4. Enter password when prompted
# 5. Wait for completion
# 6. Log out
# 7. Select "Hyprland" at login
# 8. Enjoy!
```

Total time: ~10-15 minutes depending on internet speed.
