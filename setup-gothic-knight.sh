#!/bin/bash

################################################################################
# Gothic Knight Hyprland - Complete Automated Installer
# 
# This script installs and configures a complete Gothic Knight themed
# Hyprland environment on Arch Linux, including all dependencies,
# configurations, and GTK theming.
#
# Usage: ./setup-gothic-knight.sh
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GOLD='\033[38;5;220m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
print_banner() {
    clear
    echo -e "${RED}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     ⚔️  GOTHIC KNIGHT HYPRLAND SETUP - COMPLETE INSTALL ⚔️    ║
║                                                               ║
║              Medieval Aesthetics • Modern Features            ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GOLD}  $1${NC}"
    echo -e "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Check if running on Arch Linux
check_arch() {
    if [ ! -f /etc/arch-release ]; then
        log_error "This script is designed for Arch Linux only!"
        exit 1
    fi
    log_success "Arch Linux detected"
}

# Check if running as root (we don't want that)
check_root() {
    if [ "$EUID" -eq 0 ]; then
        log_error "Please do NOT run this script as root!"
        log_info "Run as your normal user. Sudo will be used when needed."
        exit 1
    fi
    log_success "Running as user: $USER"
}

# Update system
update_system() {
    log_section "Updating System"
    log_info "Updating package database..."
    sudo pacman -Sy --noconfirm
    log_success "System updated"
}

# Install AUR helper if not present
install_aur_helper() {
    log_section "Checking AUR Helper"
    
    if command -v yay &> /dev/null; then
        log_success "yay is already installed"
        return 0
    elif command -v paru &> /dev/null; then
        log_success "paru is already installed"
        return 0
    fi
    
    log_info "No AUR helper found. Installing yay..."
    
    # Install dependencies for building yay
    sudo pacman -S --needed --noconfirm base-devel git
    
    # Clone and build yay
    cd /tmp
    if [ -d "yay" ]; then
        rm -rf yay
    fi
    
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    
    log_success "yay installed successfully"
}

# Determine which AUR helper to use
get_aur_helper() {
    if command -v yay &> /dev/null; then
        echo "yay"
    elif command -v paru &> /dev/null; then
        echo "paru"
    else
        echo ""
    fi
}

# Install all required packages
install_packages() {
    log_section "Installing Packages"
    
    log_info "Installing core Hyprland components..."
    sudo pacman -S --needed --noconfirm \
        hyprland \
        hyprpaper \
        hyprlock \
        hypridle \
        xdg-desktop-portal-hyprland \
        xdg-desktop-portal-gtk \
        qt5-wayland \
        qt6-wayland \
        qt5ct \
        qt6ct
    
    log_success "Core components installed"
    
    log_info "Installing status bar and utilities..."
    sudo pacman -S --needed --noconfirm \
        waybar \
        rofi-wayland \
        dunst \
        kitty \
        swaylock \
        swayidle
    
    log_success "Status bar and utilities installed"
    
    log_info "Installing applications..."
    sudo pacman -S --needed --noconfirm \
        firefox \
        nemo \
        nemo-fileroller \
        file-roller \
        pavucontrol \
        networkmanager \
        network-manager-applet \
        bluez \
        bluez-utils \
        blueman
    
    log_success "Applications installed"
    
    log_info "Installing system utilities..."
    sudo pacman -S --needed --noconfirm \
        polkit-gnome \
        brightnessctl \
        playerctl \
        wl-clipboard \
        cliphist \
        grim \
        slurp \
        imagemagick \
        jq \
        btop \
        htop \
        fastfetch \
        neovim \
        wget \
        curl
    
    log_success "System utilities installed"
    
    log_info "Installing fonts..."
    sudo pacman -S --needed --noconfirm \
        ttf-jetbrains-mono-nerd \
        ttf-font-awesome \
        noto-fonts \
        noto-fonts-emoji \
        noto-fonts-cjk \
        ttf-dejavu
    
    log_success "Fonts installed"
    
    log_info "Installing GTK and theming..."
    sudo pacman -S --needed --noconfirm \
        gtk3 \
        gtk4 \
        papirus-icon-theme \
        adwaita-icon-theme \
        gnome-themes-extra \
        lxappearance
    
    log_success "GTK and theming installed"
    
    # Install AUR packages if AUR helper is available
    local aur_helper=$(get_aur_helper)
    if [ -n "$aur_helper" ]; then
        log_info "Installing AUR packages..."
        $aur_helper -S --needed --noconfirm \
            grimblast-git \
            hyprpicker \
            wlogout 2>/dev/null || log_warning "Some AUR packages failed to install"
        log_success "AUR packages processed"
    else
        log_warning "No AUR helper available, skipping AUR packages"
    fi
}

# Install Gothic GTK theme
install_gothic_theme() {
    log_section "Installing Gothic Theme"
    
    local theme_dir="$HOME/.themes/Gothic-Knight"
    local icon_theme="Papirus-Dark"
    
    mkdir -p "$HOME/.themes"
    mkdir -p "$HOME/.icons"
    
    # Create custom GTK3 theme based on Adwaita-dark with gothic colors
    log_info "Creating Gothic Knight GTK theme..."
    
    mkdir -p "$theme_dir/gtk-3.0"
    mkdir -p "$theme_dir/gtk-4.0"
    
    # GTK-3.0 CSS
    cat > "$theme_dir/gtk-3.0/gtk.css" << 'EOF'
/* Gothic Knight GTK3 Theme */

@define-color bg_color #0a0000;
@define-color fg_color #d4af37;
@define-color base_color #1a0000;
@define-color text_color #cccccc;
@define-color selected_bg_color #8b0000;
@define-color selected_fg_color #d4af37;
@define-color tooltip_bg_color #1a0000;
@define-color tooltip_fg_color #d4af37;

* {
    background-color: @bg_color;
    color: @fg_color;
}

window {
    background-color: @bg_color;
}

.titlebar {
    background: linear-gradient(to bottom, #1a0000, #0a0000);
    border-bottom: 2px solid #8b0000;
    color: @fg_color;
}

button {
    background: linear-gradient(to bottom, #450a0a, #1a0000);
    border: 1px solid #8b0000;
    color: @fg_color;
}

button:hover {
    background: linear-gradient(to bottom, #8b0000, #450a0a);
    border-color: #d4af37;
}

button:active {
    background: #8b0000;
}

entry {
    background-color: @base_color;
    color: @text_color;
    border: 1px solid #450a0a;
}

entry:focus {
    border-color: #8b0000;
}

scrollbar {
    background-color: @base_color;
}

scrollbar slider {
    background-color: #450a0a;
}

scrollbar slider:hover {
    background-color: #8b0000;
}
EOF

    # GTK-4.0 CSS
    cp "$theme_dir/gtk-3.0/gtk.css" "$theme_dir/gtk-4.0/gtk.css"
    
    log_success "Gothic Knight GTK theme created"
}

# Configure GTK settings
configure_gtk() {
    log_section "Configuring GTK"
    
    log_info "Setting up GTK-3.0 configuration..."
    mkdir -p "$HOME/.config/gtk-3.0"
    cat > "$HOME/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Gothic-Knight
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrainsMono Nerd Font 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
EOF
    log_success "GTK-3.0 configured"
    
    log_info "Setting up GTK-4.0 configuration..."
    mkdir -p "$HOME/.config/gtk-4.0"
    cat > "$HOME/.config/gtk-4.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Gothic-Knight
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrainsMono Nerd Font 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF
    log_success "GTK-4.0 configured"
    
    # GTK-2.0 configuration
    log_info "Setting up GTK-2.0 configuration..."
    cat > "$HOME/.gtkrc-2.0" << 'EOF'
gtk-theme-name="Adwaita-dark"
gtk-icon-theme-name="Papirus-Dark"
gtk-font-name="JetBrainsMono Nerd Font 10"
gtk-cursor-theme-name="Adwaita"
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
EOF
    log_success "GTK-2.0 configured"
}

# Create directory structure
create_directories() {
    log_section "Creating Directory Structure"
    
    log_info "Creating configuration directories..."
    mkdir -p "$HOME/.config/hypr"
    mkdir -p "$HOME/.config/hypr/scripts"
    mkdir -p "$HOME/.config/hypr/wallpapers"
    mkdir -p "$HOME/.config/waybar"
    mkdir -p "$HOME/.config/rofi"
    mkdir -p "$HOME/.config/dunst"
    mkdir -p "$HOME/.config/kitty"
    mkdir -p "$HOME/.config/swaylock"
    mkdir -p "$HOME/Pictures/Screenshots"
    
    log_success "Directories created"
}

# Create Hyprland configuration
create_hyprland_config() {
    log_section "Creating Hyprland Configuration"
    
    cat > "$HOME/.config/hypr/hyprland.conf" << 'EOF'
# Hyprland Configuration - Gothic Knight Theme

# Monitor configuration
monitor=,preferred,auto,1

# Autostart applications
exec-once = waybar
exec-once = dunst
exec-once = hyprpaper
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = swayidle -w timeout 300 'swaylock -f' timeout 600 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on'
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = nm-applet --indicator
exec-once = blueman-applet

# Environment variables
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Adwaita
env = QT_QPA_PLATFORMTHEME,qt6ct
env = QT_QPA_PLATFORM,wayland
env = GDK_BACKEND,wayland,x11
env = SDL_VIDEODRIVER,wayland
env = CLUTTER_BACKEND,wayland

# Input configuration
input {
    kb_layout = us
    follow_mouse = 1
    sensitivity = 0
    
    touchpad {
        natural_scroll = true
        disable_while_typing = true
    }
}

# Cursor configuration
cursor {
    no_hardware_cursors = false
    enable_hyprcursor = true
}

# General window properties
general {
    gaps_in = 8
    gaps_out = 12
    border_size = 3
    
    col.active_border = rgba(8b0000ff) rgba(450a0aff) 45deg
    col.inactive_border = rgba(1a1a1aaa)
    
    layout = dwindle
}

# Decoration settings
decoration {
    rounding = 6
    
    blur {
        enabled = true
        size = 6
        passes = 3
        vibrancy = 0.1696
        xray = true
        ignore_opacity = true
    }
    
    shadow {
        enabled = true
        range = 30
        render_power = 3
        color = rgba(8b0000ee)
        color_inactive = rgba(1a1a1aee)
    }
    
    dim_inactive = true
    dim_strength = 0.1
}

# Animations
animations {
    enabled = true
    
    bezier = knightBezier, 0.25, 0.9, 0.25, 1.0
    bezier = swordSwing, 0.68, -0.55, 0.27, 1.55
    bezier = heavyMove, 0.4, 0.0, 0.2, 1.0
    
    animation = windows, 1, 5, knightBezier, slide
    animation = windowsOut, 1, 5, default, popin 80%
    animation = border, 1, 8, default
    animation = borderangle, 1, 100, default, loop
    animation = fade, 1, 6, default
    animation = workspaces, 1, 5, heavyMove, slidevert
}

# Layout configuration
dwindle {
    pseudotile = true
    preserve_split = true
    smart_split = false
    smart_resizing = true
}

master {
    new_on_top = false
    mfact = 0.55
}

# Gestures
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
    workspace_swipe_distance = 300
}

# Miscellaneous settings
misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    mouse_move_enables_dpms = true
    key_press_enables_dpms = true
    enable_swallow = true
    swallow_regex = ^(kitty|alacritty)$
    vfr = true
}

# Window rules
windowrulev2 = opacity 0.95 0.85, class:^(kitty)$
windowrulev2 = opacity 0.95 0.85, class:^(Alacritty)$
windowrulev2 = opacity 0.92 0.82, class:^(Code)$
windowrulev2 = opacity 0.95 0.90, class:^(firefox)$
windowrulev2 = opacity 0.95 0.90, class:^(discord)$
windowrulev2 = opacity 0.95 0.90, class:^(nemo)$

windowrulev2 = float, class:^(pavucontrol)$
windowrulev2 = float, class:^(nm-connection-editor)$
windowrulev2 = float, class:^(blueman-manager)$
windowrulev2 = float, title:^(Picture-in-Picture)$

# Layer rules
layerrule = blur, waybar
layerrule = blur, rofi
layerrule = ignorezero, waybar

# Keybindings
$mainMod = SUPER

# Applications
bind = $mainMod, RETURN, exec, kitty
bind = $mainMod, B, exec, firefox
bind = $mainMod, E, exec, nemo
bind = $mainMod, D, exec, rofi -show drun
bind = $mainMod SHIFT, D, exec, rofi -show run
bind = $mainMod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy

# Window management
bind = $mainMod, Q, killactive
bind = $mainMod SHIFT, Q, exit
bind = $mainMod, F, fullscreen, 0
bind = $mainMod SHIFT, F, togglefloating
bind = $mainMod, P, pseudo
bind = $mainMod, J, togglesplit

# Lock screen
bind = $mainMod, L, exec, swaylock -f

# Screenshots
bind = , PRINT, exec, ~/.config/hypr/scripts/screenshot.sh clipboard-area
bind = SHIFT, PRINT, exec, ~/.config/hypr/scripts/screenshot.sh clipboard-full
bind = $mainMod, PRINT, exec, ~/.config/hypr/scripts/screenshot.sh area

# Focus movement (HJKL)
bind = $mainMod, H, movefocus, l
bind = $mainMod, L, movefocus, r
bind = $mainMod, K, movefocus, u
bind = $mainMod, J, movefocus, d

# Window movement
bind = $mainMod SHIFT, H, movewindow, l
bind = $mainMod SHIFT, L, movewindow, r
bind = $mainMod SHIFT, K, movewindow, u
bind = $mainMod SHIFT, J, movewindow, d

# Workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Scratchpad
bind = $mainMod, S, togglespecialworkspace, magic
bind = $mainMod SHIFT, S, movetoworkspace, special:magic

# Scroll workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Mouse bindings
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Resize mode
bind = $mainMod, R, submap, resize
submap = resize
binde = , H, resizeactive, -50 0
binde = , L, resizeactive, 50 0
binde = , K, resizeactive, 0 -50
binde = , J, resizeactive, 0 50
bind = , escape, submap, reset
submap = reset

# Media keys
bindel = , XF86AudioRaiseVolume, exec, ~/.config/hypr/scripts/volume.sh up
bindel = , XF86AudioLowerVolume, exec, ~/.config/hypr/scripts/volume.sh down
bindl = , XF86AudioMute, exec, ~/.config/hypr/scripts/volume.sh mute
bindl = , XF86AudioPlay, exec, playerctl play-pause
bindl = , XF86AudioNext, exec, playerctl next
bindl = , XF86AudioPrev, exec, playerctl previous

# Brightness
bindel = , XF86MonBrightnessUp, exec, ~/.config/hypr/scripts/brightness.sh up
bindel = , XF86MonBrightnessDown, exec, ~/.config/hypr/scripts/brightness.sh down
EOF
    
    log_success "Hyprland configuration created"
}

# Create Waybar configuration
create_waybar_config() {
    log_section "Creating Waybar Configuration"
    
    cat > "$HOME/.config/waybar/config" << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 38,
    "spacing": 8,
    
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "temperature", "battery", "tray"],
    
    "hyprland/workspaces": {
        "format": "⚔ {id}",
        "on-click": "activate",
        "all-outputs": true,
        "persistent-workspaces": {
            "1": [],
            "2": [],
            "3": [],
            "4": [],
            "5": []
        }
    },
    
    "hyprland/window": {
        "format": "{}",
        "max-length": 60,
        "separate-outputs": true
    },
    
    "clock": {
        "interval": 1,
        "format": "🗡️ {:%A, %B %d  %H:%M:%S}",
        "format-alt": "⚔️ {:%Y-%m-%d}",
        "tooltip-format": "<tt><small>{calendar}</small></tt>",
        "calendar": {
            "mode": "month",
            "mode-mon-col": 3,
            "weeks-pos": "right",
            "on-scroll": 1,
            "format": {
                "months": "<span color='#8b0000'><b>{}</b></span>",
                "days": "<span color='#cccccc'><b>{}</b></span>",
                "weeks": "<span color='#666666'><b>W{}</b></span>",
                "weekdays": "<span color='#8b0000'><b>{}</b></span>",
                "today": "<span color='#ff0000'><b><u>{}</u></b></span>"
            }
        }
    },
    
    "cpu": {
        "format": "⚙️ {usage}%",
        "interval": 2,
        "tooltip": true,
        "on-click": "kitty -e btop"
    },
    
    "memory": {
        "format": "🛡️ {percentage}%",
        "interval": 5,
        "tooltip-format": "RAM: {used:0.1f}G / {total:0.1f}G\nSwap: {swapUsed:0.1f}G / {swapTotal:0.1f}G",
        "on-click": "kitty -e btop"
    },
    
    "temperature": {
        "thermal-zone": 2,
        "hwmon-path": "/sys/class/hwmon/hwmon2/temp1_input",
        "critical-threshold": 80,
        "format": "🔥 {temperatureC}°C",
        "format-critical": "🔥 {temperatureC}°C"
    },
    
    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-charging": "⚡ {capacity}%",
        "format-plugged": "🔌 {capacity}%",
        "format-alt": "{icon} {time}",
        "format-icons": ["🗡️", "🗡️", "⚔️", "⚔️", "🛡️"]
    },
    
    "network": {
        "format-wifi": "📡 {essid}",
        "format-ethernet": "🏰 {ipaddr}/{cidr}",
        "format-disconnected": "⚠️ Disconnected",
        "tooltip-format": "{ifname} via {gwaddr}",
        "tooltip-format-wifi": "{essid} ({signalStrength}%)\n{ipaddr}/{cidr}",
        "on-click": "nm-connection-editor"
    },
    
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-bluetooth": "{icon} {volume}%",
        "format-muted": "🔇 Muted",
        "format-icons": {
            "headphone": "🎧",
            "hands-free": "🎧",
            "headset": "🎧",
            "phone": "📱",
            "portable": "📱",
            "car": "🚗",
            "default": ["🔊", "🔊", "🔊"]
        },
        "on-click": "pavucontrol",
        "on-click-right": "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    },
    
    "tray": {
        "icon-size": 18,
        "spacing": 10
    }
}
EOF
    
    cat > "$HOME/.config/waybar/style.css" << 'EOF'
/* Gothic Knight Theme for Waybar */

* {
    font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free";
    font-size: 13px;
    font-weight: bold;
    border: none;
    border-radius: 0;
    min-height: 0;
}

window#waybar {
    background: linear-gradient(180deg, rgba(20, 0, 0, 0.95) 0%, rgba(40, 0, 0, 0.92) 100%);
    border-bottom: 3px solid #8b0000;
    color: #d4af37;
    transition: background-color 0.3s;
}

#workspaces {
    margin: 4px 8px;
}

#workspaces button {
    padding: 4px 12px;
    background: rgba(20, 0, 0, 0.8);
    color: #8b0000;
    border: 2px solid #450a0a;
    border-radius: 6px;
    margin: 0 3px;
    transition: all 0.3s cubic-bezier(0.4, 0.0, 0.2, 1);
}

#workspaces button:hover {
    background: rgba(139, 0, 0, 0.4);
    color: #d4af37;
    border-color: #8b0000;
    box-shadow: 0 0 10px rgba(139, 0, 0, 0.5);
}

#workspaces button.active {
    background: linear-gradient(135deg, #8b0000 0%, #450a0a 100%);
    color: #d4af37;
    border-color: #d4af37;
    box-shadow: 0 0 15px rgba(212, 175, 55, 0.6), inset 0 0 10px rgba(0, 0, 0, 0.5);
}

#workspaces button.urgent {
    background: #ff0000;
    color: #000000;
    animation: blink 1s linear infinite;
}

@keyframes blink {
    0% {
        opacity: 1;
    }
    50% {
        opacity: 1;
    }
    51% {
        opacity: 0.5;
    }
    100% {
        opacity: 0.5;
    }
}

#window {
    padding: 6px 16px;
    background: rgba(139, 0, 0, 0.3);
    color: #cccccc;
    border: 2px solid #450a0a;
    border-radius: 6px;
    margin: 4px 0;
    font-style: italic;
}

#clock {
    padding: 6px 20px;
    background: linear-gradient(135deg, rgba(139, 0, 0, 0.7) 0%, rgba(69, 10, 10, 0.7) 100%);
    color: #d4af37;
    border: 2px solid #d4af37;
    border-radius: 8px;
    margin: 4px 0;
    font-size: 14px;
    font-weight: bold;
    box-shadow: 0 0 20px rgba(212, 175, 55, 0.4), inset 0 0 10px rgba(0, 0, 0, 0.5);
    text-shadow: 0 0 5px rgba(212, 175, 55, 0.8);
}

#cpu,
#memory,
#temperature,
#battery,
#network,
#pulseaudio {
    padding: 6px 14px;
    background: rgba(20, 0, 0, 0.8);
    color: #d4af37;
    border: 2px solid #450a0a;
    border-radius: 6px;
    margin: 4px 4px;
    transition: all 0.3s;
}

#cpu:hover,
#memory:hover,
#temperature:hover,
#battery:hover,
#network:hover,
#pulseaudio:hover {
    background: rgba(139, 0, 0, 0.6);
    border-color: #8b0000;
    box-shadow: 0 0 10px rgba(139, 0, 0, 0.6);
}

#cpu {
    color: #8b0000;
}

#memory {
    color: #d4af37;
}

#temperature {
    color: #ff4500;
}

#temperature.critical {
    background: rgba(255, 0, 0, 0.5);
    color: #ffffff;
    animation: blink 0.5s linear infinite;
}

#battery {
    color: #90ee90;
}

#battery.charging {
    color: #ffff00;
}

#battery.warning:not(.charging) {
    background: rgba(255, 165, 0, 0.3);
    color: #ff8c00;
}

#battery.critical:not(.charging) {
    background: rgba(255, 0, 0, 0.5);
    color: #ffffff;
    animation: blink 0.5s linear infinite;
}

#network {
    color: #87ceeb;
}

#network.disconnected {
    background: rgba(128, 128, 128, 0.3);
    color: #808080;
}

#pulseaudio {
    color: #dda0dd;
}

#pulseaudio.muted {
    background: rgba(128, 0, 0, 0.3);
    color: #666666;
}

#tray {
    padding: 4px 10px;
    background: rgba(20, 0, 0, 0.8);
    border: 2px solid #450a0a;
    border-radius: 6px;
    margin: 4px 8px;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    animation: blink 1s linear infinite;
}

tooltip {
    background: rgba(20, 0, 0, 0.95);
    color: #d4af37;
    border: 2px solid #8b0000;
    border-radius: 6px;
    padding: 10px;
}

tooltip label {
    color: #d4af37;
}
EOF
    
    log_success "Waybar configuration created"
}

# Create remaining config files (continuing in next part due to length)
create_rofi_config() {
    log_section "Creating Rofi Configuration"
    
    cat > "$HOME/.config/rofi/config.rasi" << 'EOF'
configuration {
    font: "JetBrainsMono Nerd Font Bold 12";
}

@theme "gothic-knight"
EOF
    
    cat > "$HOME/.config/rofi/gothic-knight.rasi" << 'EOF'
* {
    background-color: transparent;
    text-color: #d4af37;
    font: "JetBrainsMono Nerd Font Bold 12";
}

window {
    transparency: "real";
    background-color: rgba(20, 0, 0, 0.95);
    border: 3px solid;
    border-color: #8b0000;
    border-radius: 8px;
    padding: 20px;
    width: 600px;
}

mainbox {
    background-color: transparent;
    children: [ inputbar, message, listview ];
    spacing: 15px;
}

inputbar {
    background-color: rgba(139, 0, 0, 0.3);
    border: 2px solid;
    border-color: #8b0000;
    border-radius: 6px;
    padding: 12px 16px;
    spacing: 10px;
    children: [ prompt, entry ];
}

prompt {
    text-color: #d4af37;
    background-color: transparent;
    font: "JetBrainsMono Nerd Font Bold 13";
}

entry {
    placeholder: "Search...";
    placeholder-color: rgba(212, 175, 55, 0.5);
    text-color: #ffffff;
    background-color: transparent;
    cursor: text;
}

message {
    background-color: rgba(139, 0, 0, 0.2);
    border: 2px solid;
    border-color: #450a0a;
    border-radius: 6px;
    padding: 10px;
}

textbox {
    text-color: #d4af37;
    background-color: transparent;
}

listview {
    background-color: transparent;
    spacing: 4px;
    scrollbar: true;
    lines: 10;
}

scrollbar {
    width: 4px;
    border: 0;
    handle-color: #8b0000;
    handle-width: 8px;
    padding: 0;
    background-color: rgba(69, 10, 10, 0.5);
}

element {
    background-color: rgba(20, 0, 0, 0.5);
    text-color: #cccccc;
    border: 2px solid;
    border-color: rgba(69, 10, 10, 0.5);
    border-radius: 6px;
    padding: 10px 14px;
    spacing: 10px;
}

element normal.normal {
    background-color: rgba(20, 0, 0, 0.5);
    text-color: #cccccc;
}

element normal.urgent {
    background-color: rgba(255, 0, 0, 0.3);
    text-color: #ffffff;
}

element normal.active {
    background-color: rgba(139, 0, 0, 0.5);
    text-color: #d4af37;
}

element selected.normal {
    background-color: rgba(139, 0, 0, 0.8);
    text-color: #d4af37;
    border-color: #d4af37;
    box-shadow: 0 0 10px rgba(212, 175, 55, 0.5);
}

element selected.urgent {
    background-color: rgba(255, 0, 0, 0.8);
    text-color: #ffffff;
}

element selected.active {
    background-color: rgba(139, 0, 0, 0.8);
    text-color: #ffffff;
}

element-icon {
    size: 24px;
    background-color: transparent;
}

element-text {
    background-color: transparent;
    text-color: inherit;
    vertical-align: 0.5;
}
EOF
    
    log_success "Rofi configuration created"
}

# Create other config files
create_other_configs() {
    log_section "Creating Additional Configurations"
    
    # Dunst
    log_info "Creating Dunst configuration..."
    cat > "$HOME/.config/dunst/dunstrc" << 'EOF'
[global]
    monitor = 0
    follow = mouse
    width = (300, 400)
    height = 300
    origin = top-right
    offset = 15x50
    transparency = 10
    separator_height = 3
    padding = 16
    horizontal_padding = 16
    frame_width = 3
    frame_color = "#8b0000"
    separator_color = frame
    font = JetBrainsMono Nerd Font Bold 11
    line_height = 4
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 60
    word_wrap = yes
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    icon_position = left
    min_icon_size = 48
    max_icon_size = 64
    sticky_history = yes
    history_length = 20
    dmenu = /usr/bin/rofi -dmenu -p dunst:
    browser = /usr/bin/firefox --new-tab
    mouse_left_click = do_action, close_current
    mouse_middle_click = close_all
    mouse_right_click = close_current
    corner_radius = 8
    progress_bar = true
    progress_bar_height = 14
    progress_bar_frame_width = 2
    progress_bar_min_width = 150
    progress_bar_max_width = 300

[urgency_low]
    background = "#140000"
    foreground = "#cccccc"
    frame_color = "#450a0a"
    timeout = 5

[urgency_normal]
    background = "#1a0000"
    foreground = "#d4af37"
    frame_color = "#8b0000"
    timeout = 10

[urgency_critical]
    background = "#450a0a"
    foreground = "#ffffff"
    frame_color = "#ff0000"
    timeout = 0
EOF
    log_success "Dunst configured"
    
    # Kitty
    log_info "Creating Kitty configuration..."
    cat > "$HOME/.config/kitty/kitty.conf" << 'EOF'
# Gothic Knight Theme for Kitty

font_family      JetBrainsMono Nerd Font
bold_font        JetBrainsMono Nerd Font Bold
italic_font      JetBrainsMono Nerd Font Italic
bold_italic_font JetBrainsMono Nerd Font Bold Italic
font_size 11.0

cursor_shape block
cursor_blink_interval 0.5
cursor_stop_blinking_after 15.0

scrollback_lines 10000
mouse_hide_wait 3.0
url_color #d4af37
url_style curly
copy_on_select yes

repaint_delay 10
input_delay 3
sync_to_monitor yes

remember_window_size  yes
initial_window_width  1200
initial_window_height 700
window_padding_width 10
window_padding_height 10
placement_strategy center

tab_bar_edge top
tab_bar_style powerline
tab_powerline_style slanted

foreground #d4af37
background #0a0000
selection_foreground #000000
selection_background #d4af37

cursor #d4af37
cursor_text_color #000000

active_tab_foreground   #d4af37
active_tab_background   #450a0a
active_tab_font_style   bold
inactive_tab_foreground #666666
inactive_tab_background #140000
inactive_tab_font_style normal

color0 #1a0000
color8 #450a0a
color1 #8b0000
color9 #ff0000
color2  #006400
color10 #00ff00
color3  #d4af37
color11 #ffd700
color4  #00008b
color12 #4169e1
color5  #8b008b
color13 #ff00ff
color6  #008b8b
color14 #00ffff
color7  #cccccc
color15 #ffffff

background_opacity 0.92
dynamic_background_opacity yes

shell .
editor .
close_on_child_death no
allow_remote_control yes
update_check_interval 0
EOF
    log_success "Kitty configured"
    
    # Swaylock
    log_info "Creating Swaylock configuration..."
    cat > "$HOME/.config/swaylock/config" << 'EOF'
image=~/.config/hypr/wallpapers/knight-lock.jpg
scaling=fill
color=000000
ring-color=450a0a
inside-color=1a0000
line-color=000000
separator-color=8b0000
key-hl-color=d4af37
bs-hl-color=8b0000
ring-ver-color=8b0000
inside-ver-color=450a0a
text-ver-color=d4af37
ring-wrong-color=ff0000
inside-wrong-color=450a0a
text-wrong-color=ffffff
ring-clear-color=666666
inside-clear-color=1a0000
text-clear-color=cccccc
text-color=d4af37
text-caps-lock-color=ff0000
font=JetBrainsMono Nerd Font
font-size=24
indicator-radius=120
indicator-thickness=15
indicator
clock
timestr=%H:%M:%S
datestr=%A, %B %d
ignore-empty-password
show-failed-attempts
EOF
    log_success "Swaylock configured"
    
    # Hyprpaper
    log_info "Creating Hyprpaper configuration..."
    cat > "$HOME/.config/hypr/hyprpaper.conf" << 'EOF'
preload = ~/.config/hypr/wallpapers/knight-main.jpg
wallpaper = ,~/.config/hypr/wallpapers/knight-main.jpg
splash = false
ipc = on
EOF
    log_success "Hyprpaper configured"
}

# Create utility scripts
create_scripts() {
    log_section "Creating Utility Scripts"
    
    # Volume script
    log_info "Creating volume control script..."
    cat > "$HOME/.config/hypr/scripts/volume.sh" << 'EOF'
#!/bin/bash

get_volume() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'
}

is_muted() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED"
}

send_notification() {
    volume=$(get_volume)
    
    if is_muted; then
        dunstify -u normal -h string:x-dunst-stack-tag:volume \
                 -h int:value:0 \
                 "🔇 Volume Muted" \
                 "Audio output silenced"
    else
        if [ "$volume" -ge 70 ]; then
            icon="🔊"
        elif [ "$volume" -ge 40 ]; then
            icon="🔉"
        else
            icon="🔈"
        fi
        
        dunstify -u normal -h string:x-dunst-stack-tag:volume \
                 -h int:value:"$volume" \
                 "$icon Volume: $volume%" \
                 "Audio level adjusted"
    fi
}

case $1 in
    up)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
        send_notification
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        send_notification
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        send_notification
        ;;
esac
EOF
    chmod +x "$HOME/.config/hypr/scripts/volume.sh"
    log_success "Volume script created"
    
    # Brightness script
    log_info "Creating brightness control script..."
    cat > "$HOME/.config/hypr/scripts/brightness.sh" << 'EOF'
#!/bin/bash

get_brightness() {
    brightnessctl get
}

get_max_brightness() {
    brightnessctl max
}

get_brightness_percent() {
    current=$(get_brightness)
    max=$(get_max_brightness)
    echo $((current * 100 / max))
}

send_notification() {
    brightness=$(get_brightness_percent)
    
    if [ "$brightness" -ge 80 ]; then
        icon="☀️"
    elif [ "$brightness" -ge 50 ]; then
        icon="🌤️"
    elif [ "$brightness" -ge 20 ]; then
        icon="🌥️"
    else
        icon="🌙"
    fi
    
    dunstify -u normal -h string:x-dunst-stack-tag:brightness \
             -h int:value:"$brightness" \
             "$icon Brightness: $brightness%" \
             "Screen illumination adjusted"
}

case $1 in
    up)
        brightnessctl set 5%+
        send_notification
        ;;
    down)
        brightnessctl set 5%-
        send_notification
        ;;
esac
EOF
    chmod +x "$HOME/.config/hypr/scripts/brightness.sh"
    log_success "Brightness script created"
    
    # Screenshot script
    log_info "Creating screenshot script..."
    cat > "$HOME/.config/hypr/scripts/screenshot.sh" << 'EOF'
#!/bin/bash

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

timestamp=$(date +%Y%m%d_%H%M%S)

send_notification() {
    local file=$1
    local mode=$2
    
    if [ -f "$file" ]; then
        dunstify -u normal \
                 -i "$file" \
                 "⚔️ Screenshot Captured" \
                 "Mode: $mode\nSaved to: $(basename $file)"
    else
        dunstify -u critical \
                 "❌ Screenshot Failed" \
                 "Could not capture screenshot"
    fi
}

case $1 in
    full)
        file="$SCREENSHOT_DIR/screenshot_full_$timestamp.png"
        grim "$file"
        send_notification "$file" "Full Screen"
        ;;
    area)
        file="$SCREENSHOT_DIR/screenshot_area_$timestamp.png"
        grim -g "$(slurp)" "$file"
        send_notification "$file" "Selected Area"
        ;;
    clipboard-full)
        grim - | wl-copy
        dunstify -u normal "📋 Screenshot Copied" "Full screen copied to clipboard"
        ;;
    clipboard-area)
        grim -g "$(slurp)" - | wl-copy
        dunstify -u normal "📋 Screenshot Copied" "Selected area copied to clipboard"
        ;;
esac
EOF
    chmod +x "$HOME/.config/hypr/scripts/screenshot.sh"
    log_success "Screenshot script created"
}

# Download sample wallpapers
setup_wallpapers() {
    log_section "Setting Up Wallpapers"
    
    log_info "Creating sample solid color wallpapers..."
    
    # Create dark red gradient wallpaper using ImageMagick
    convert -size 1920x1080 gradient:#0a0000-#450a0a \
        "$HOME/.config/hypr/wallpapers/knight-main.jpg" 2>/dev/null || \
        convert -size 1920x1080 xc:#1a0000 "$HOME/.config/hypr/wallpapers/knight-main.jpg"
    
    convert -size 1920x1080 gradient:#450a0a-#8b0000 \
        "$HOME/.config/hypr/wallpapers/knight-alt.jpg" 2>/dev/null || \
        convert -size 1920x1080 xc:#450a0a "$HOME/.config/hypr/wallpapers/knight-alt.jpg"
    
    cp "$HOME/.config/hypr/wallpapers/knight-main.jpg" \
       "$HOME/.config/hypr/wallpapers/knight-lock.jpg"
    
    log_success "Sample wallpapers created"
    log_warning "These are placeholder wallpapers. Download gothic knight images from:"
    echo "          - Unsplash.com (search: dark medieval knight)"
    echo "          - Wallhaven.cc (search: gothic knight)"
    echo "          Place them in: ~/.config/hypr/wallpapers/"
}

# Enable services
enable_services() {
    log_section "Enabling System Services"
    
    log_info "Enabling NetworkManager..."
    sudo systemctl enable NetworkManager
    sudo systemctl start NetworkManager 2>/dev/null || true
    log_success "NetworkManager enabled"
    
    log_info "Enabling Bluetooth..."
    sudo systemctl enable bluetooth
    sudo systemctl start bluetooth 2>/dev/null || true
    log_success "Bluetooth enabled"
}

# Create session file
create_session_file() {
    log_section "Creating Hyprland Session File"
    
    sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=Gothic Knight Hyprland
Exec=Hyprland
Type=Application
EOF
    
    log_success "Session file created"
}

# Final instructions
print_final_instructions() {
    log_section "Installation Complete!"
    
    cat << EOF

${GREEN}╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║              ⚔️  GOTHIC KNIGHT SETUP COMPLETE ⚔️              ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝${NC}

${GOLD}🏰 Next Steps:${NC}

1. ${YELLOW}Log out of your current session${NC}

2. ${YELLOW}At the login screen, select "Hyprland" as your session${NC}

3. ${YELLOW}Log in and enjoy your Gothic Knight setup!${NC}

${GOLD}📚 Key Bindings:${NC}
   SUPER + Return       : Terminal
   SUPER + D           : Application launcher
   SUPER + B           : Browser
   SUPER + E           : File manager (Nemo)
   SUPER + L           : Lock screen
   SUPER + Q           : Close window
   SUPER + H/J/K/L     : Move focus (Vim style)
   SUPER + 1-9         : Switch workspace

${GOLD}🎨 Customization:${NC}
   - Wallpapers: ~/.config/hypr/wallpapers/
   - Hyprland config: ~/.config/hypr/hyprland.conf
   - Waybar: ~/.config/waybar/
   - GTK Theme: ~/.config/gtk-3.0/settings.ini

${GOLD}📖 Documentation:${NC}
   - Quick reference: Created in ~/gothic-knight-quickstart.txt
   - Hyprland wiki: https://wiki.hyprland.org

${RED}⚔️ May your workflow be swift and your windows perfectly tiled! ⚔️${NC}

EOF

    # Create quick reference file
    cat > "$HOME/gothic-knight-quickstart.txt" << 'REFEOF'
╔═══════════════════════════════════════════════════════════════╗
║          GOTHIC KNIGHT HYPRLAND - QUICK REFERENCE             ║
╚═══════════════════════════════════════════════════════════════╝

ESSENTIAL KEYBINDINGS:
━━━━━━━━━━━━━━━━━━━━━
SUPER + Return       → Open terminal
SUPER + D           → Application launcher
SUPER + B           → Web browser
SUPER + E           → File manager
SUPER + L           → Lock screen
SUPER + Q           → Close window
SUPER + SHIFT + Q   → Exit Hyprland
SUPER + F           → Fullscreen
SUPER + SHIFT + F   → Toggle floating

WINDOW NAVIGATION (Vim Style):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SUPER + H           → Focus left
SUPER + J           → Focus down
SUPER + K           → Focus up
SUPER + L           → Focus right
SUPER + SHIFT + H/J/K/L → Move window

WORKSPACES:
━━━━━━━━━━━
SUPER + 1-9         → Switch to workspace
SUPER + SHIFT + 1-9 → Move window to workspace
SUPER + S           → Toggle scratchpad

SCREENSHOTS:
━━━━━━━━━━━━
Print Screen        → Copy area to clipboard
SHIFT + Print       → Copy full screen to clipboard
SUPER + Print       → Save area to file

CONFIGURATION FILES:
━━━━━━━━━━━━━━━━━━━━
~/.config/hypr/hyprland.conf     → Main config
~/.config/waybar/                → Status bar
~/.config/rofi/                  → App launcher
~/.config/gtk-3.0/settings.ini   → GTK theme

CUSTOMIZATION:
━━━━━━━━━━━━━━
- Download gothic knight wallpapers and place in:
  ~/.config/hypr/wallpapers/
  (knight-main.jpg, knight-alt.jpg, knight-lock.jpg)

- Edit colors in hyprland.conf:
  Search for color definitions like #8b0000 (crimson)
  and #d4af37 (gold) to customize the theme

TROUBLESHOOTING:
━━━━━━━━━━━━━━━━
- Reload config: SUPER + SHIFT + R (or restart Hyprland)
- Check logs: journalctl --user -u hyprland
- Restart waybar: killall waybar && waybar &
- Test config: hyprctl reload

⚔️ Enjoy your Gothic Knight setup!
REFEOF
}

# Main installation function
main() {
    print_banner
    
    log_info "Starting Gothic Knight Hyprland installation..."
    log_info "This will install all required packages and configurations"
    echo ""
    read -p "Press Enter to continue or Ctrl+C to cancel..."
    
    check_arch
    check_root
    update_system
    install_aur_helper
    install_packages
    install_gothic_theme
    configure_gtk
    create_directories
    create_hyprland_config
    create_waybar_config
    create_rofi_config
    create_other_configs
    create_scripts
    setup_wallpapers
    enable_services
    create_session_file
    print_final_instructions
    
    log_success "All done! Reboot or log out to start using Hyprland."
}

# Run main function
main
