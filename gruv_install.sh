#!/bin/bash

#==============================================================================
#  Arch Linux Hyprland Installation Script - Gruvbox Edition
#==============================================================================
#  Author: Abdullah
#  Description: Automated installation of Hyprland with full Gruvbox theming,
#               development tools, and gaming support for AMD/Nvidia
#==============================================================================

set -e

# Colors for output (Gruvbox themed of course)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Gruvbox color palette reference
GRUVBOX_BG="#282828"
GRUVBOX_FG="#ebdbb2"
GRUVBOX_RED="#cc241d"
GRUVBOX_GREEN="#98971a"
GRUVBOX_YELLOW="#d79921"
GRUVBOX_BLUE="#458588"
GRUVBOX_PURPLE="#b16286"
GRUVBOX_AQUA="#689d6a"
GRUVBOX_ORANGE="#d65d0e"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
LOG_FILE="/tmp/hyprland-install.log"

#==============================================================================
# Helper Functions
#==============================================================================

print_banner() {
    echo -e "${YELLOW}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║                                                                       ║
    ║   █████╗ ██████╗  ██████╗██╗  ██╗    ██╗  ██╗██╗   ██╗██████╗ ██████╗ ║
    ║  ██╔══██╗██╔══██╗██╔════╝██║  ██║    ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗║
    ║  ███████║██████╔╝██║     ███████║    ███████║ ╚████╔╝ ██████╔╝██████╔╝║
    ║  ██╔══██║██╔══██╗██║     ██╔══██║    ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗║
    ║  ██║  ██║██║  ██║╚██████╗██║  ██║    ██║  ██║   ██║   ██║     ██║  ██║║
    ║  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝║
    ║                                                                       ║
    ║                    ═══ GRUVBOX EDITION ═══                            ║
    ║                                                                       ║
    ╚═══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[WARNING] $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR] $1" >> "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "[SUCCESS] $1" >> "$LOG_FILE"
}

section() {
    echo ""
    echo -e "${PURPLE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

#==============================================================================
# GPU Detection
#==============================================================================

detect_gpu() {
    section "Detecting GPU"
    
    if lspci | grep -i "nvidia" > /dev/null 2>&1; then
        GPU_TYPE="nvidia"
        log "NVIDIA GPU detected"
    elif lspci | grep -i "amd\|radeon" > /dev/null 2>&1; then
        GPU_TYPE="amd"
        log "AMD GPU detected"
    elif lspci | grep -i "intel" > /dev/null 2>&1; then
        GPU_TYPE="intel"
        log "Intel GPU detected"
    else
        GPU_TYPE="unknown"
        warn "Could not detect GPU type, defaulting to mesa drivers"
    fi
    
    echo -e "${CYAN}Detected GPU: ${GPU_TYPE}${NC}"
}

#==============================================================================
# Package Installation Functions
#==============================================================================

install_yay() {
    section "Installing yay AUR Helper"
    
    if command -v yay &> /dev/null; then
        log "yay is already installed"
        return
    fi
    
    log "Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    
    cd /tmp
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    
    success "yay installed successfully"
}

install_base_packages() {
    section "Installing Base System Packages"
    
    # First, update the system
    log "Updating system..."
    sudo pacman -Syu --noconfirm
    
    local packages=(
        # Hyprland core - THE MAIN WINDOW MANAGER
        hyprland
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
        xdg-utils
        
        # Wayland essentials
        wayland
        wayland-protocols
        qt5-wayland
        qt6-wayland
        libva
        
        # Audio
        pipewire
        pipewire-alsa
        pipewire-pulse
        pipewire-jack
        wireplumber
        pavucontrol
        playerctl
        
        # Display/Login Manager
        sddm
        
        # Networking
        networkmanager
        network-manager-applet
        
        # Bluetooth
        bluez
        bluez-utils
        blueman
        
        # Core utilities
        polkit-kde-agent
        gnome-keyring
        seahorse
        
        # Fonts
        ttf-jetbrains-mono-nerd
        ttf-font-awesome
        ttf-dejavu
        noto-fonts
        noto-fonts-emoji
        noto-fonts-cjk
        
        # Archive utilities
        unzip
        unrar
        p7zip
        
        # System utilities
        htop
        btop
        fastfetch
        wget
        curl
        man-db
        man-pages
        
        # Required for some operations
        imagemagick
        jq
    )
    
    log "Installing base packages including Hyprland..."
    sudo pacman -S --needed --noconfirm "${packages[@]}"
    
    success "Base packages installed (including Hyprland)"
}

setup_hyprland_session() {
    section "Setting Up Hyprland Session"
    
    # Ensure Hyprland desktop entry exists for SDDM
    log "Verifying Hyprland session entry..."
    
    # The hyprland package should create this, but let's ensure it exists
    if [ ! -f /usr/share/wayland-sessions/hyprland.desktop ]; then
        warn "Hyprland desktop entry not found, creating..."
        sudo mkdir -p /usr/share/wayland-sessions
        sudo tee /usr/share/wayland-sessions/hyprland.desktop << 'DESKTOP'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
DesktopNames=Hyprland
DESKTOP
    else
        log "Hyprland session entry exists"
    fi
    
    # Create user's hyprland wrapper script for environment setup
    log "Creating Hyprland startup wrapper..."
    mkdir -p "$HOME/.local/bin"
    cat > "$HOME/.local/bin/start-hyprland" << 'WRAPPER'
#!/bin/bash

# Hyprland Startup Script
# This ensures all environment variables are set before starting Hyprland

# XDG Base Directories
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# Wayland specific
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=qt6ct
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export GDK_BACKEND=wayland,x11
export SDL_VIDEODRIVER=wayland
export CLUTTER_BACKEND=wayland
export GTK_THEME=Gruvbox-Dark

# Cursor
export XCURSOR_SIZE=24
export XCURSOR_THEME=capitaine-cursors

# Start Hyprland
exec Hyprland
WRAPPER
    chmod +x "$HOME/.local/bin/start-hyprland"
    
    # Add local bin to PATH if not already there
    if ! grep -q 'PATH="$HOME/.local/bin:$PATH"' "$HOME/.profile" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
    fi
    
    success "Hyprland session configured"
}

install_hyprland_ecosystem() {
    section "Installing Hyprland Ecosystem"
    
    local packages=(
        # Bar and widgets
        waybar
        
        # Application launcher
        rofi-wayland
        
        # Notifications
        dunst
        libnotify
        
        # Terminal
        alacritty
        
        # File manager
        nemo
        nemo-fileroller
        
        # Web browser
        firefox
        
        # Screenshot and recording
        grim
        slurp
        swappy
        wf-recorder
        
        # Clipboard
        wl-clipboard
        cliphist
        
        # Wallpaper
        hyprpaper
        
        # Screen locker
        hyprlock
        hypridle
        
        # Image viewer
        imv
        
        # PDF viewer
        zathura
        zathura-pdf-mupdf
        
        # Media
        mpv
        
        # Brightness control
        brightnessctl
        
        # Cursor
        xcursor-themes
        
        # Polkit authentication agent (for GUI sudo prompts)
        polkit-kde-agent
    )
    
    log "Installing Hyprland ecosystem packages..."
    sudo pacman -S --needed --noconfirm "${packages[@]}"
    
    # AUR Hyprland packages
    log "Installing AUR Hyprland ecosystem packages..."
    yay -S --needed --noconfirm \
        hyprpicker \
        wlogout
    
    success "Hyprland ecosystem installed"
}

install_development_tools() {
    section "Installing Development Tools"
    
    local packages=(
        # Core development
        base-devel
        git
        git-lfs
        github-cli
        
        # Neovim and dependencies
        neovim
        ripgrep
        fd
        fzf
        lazygit
        tree-sitter
        tree-sitter-cli
        
        # Languages and runtimes
        python
        python-pip
        python-virtualenv
        nodejs
        npm
        rust
        go
        lua
        luarocks
        
        # C/C++
        gcc
        clang
        cmake
        make
        ninja
        gdb
        lldb
        
        # Database tools
        sqlite
        postgresql-libs
        
        # Containers
        docker
        docker-compose
        
        # Additional tools
        jq
        yq
        bat
        eza
        zoxide
        starship
        tmux
        
        # LSP and formatters
        lua-language-server
        pyright
        typescript-language-server
        rust-analyzer
        
        # SSH/Network
        openssh
    )
    
    log "Installing development tools..."
    sudo pacman -S --needed --noconfirm "${packages[@]}"
    
    # AUR development packages
    log "Installing AUR development packages..."
    yay -S --needed --noconfirm \
        visual-studio-code-bin \
        lazydocker \
        fnm-bin
    
    # Enable Docker
    sudo systemctl enable docker.service
    sudo usermod -aG docker "$USER"
    
    success "Development tools installed"
}

install_gpu_drivers() {
    section "Installing GPU Drivers"
    
    case "$GPU_TYPE" in
        nvidia)
            log "Installing NVIDIA drivers..."
            local nvidia_packages=(
                nvidia-dkms
                nvidia-utils
                lib32-nvidia-utils
                nvidia-settings
                libva-nvidia-driver
                egl-wayland
            )
            sudo pacman -S --needed --noconfirm "${nvidia_packages[@]}"
            
            # Add nvidia modules to mkinitcpio
            log "Configuring NVIDIA for Hyprland..."
            sudo sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
            sudo mkinitcpio -P
            
            # Create modprobe config
            echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf
            ;;
            
        amd)
            log "Installing AMD drivers..."
            local amd_packages=(
                mesa
                lib32-mesa
                vulkan-radeon
                lib32-vulkan-radeon
                libva-mesa-driver
                lib32-libva-mesa-driver
                mesa-vdpau
                lib32-mesa-vdpau
                xf86-video-amdgpu
            )
            sudo pacman -S --needed --noconfirm "${amd_packages[@]}"
            ;;
            
        intel)
            log "Installing Intel drivers..."
            local intel_packages=(
                mesa
                lib32-mesa
                vulkan-intel
                lib32-vulkan-intel
                intel-media-driver
            )
            sudo pacman -S --needed --noconfirm "${intel_packages[@]}"
            ;;
            
        *)
            log "Installing generic Mesa drivers..."
            sudo pacman -S --needed --noconfirm mesa lib32-mesa
            ;;
    esac
    
    success "GPU drivers installed"
}

install_gaming_packages() {
    section "Installing Gaming Packages"
    
    # Enable multilib repository
    log "Enabling multilib repository..."
    sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
    sudo pacman -Sy
    
    local gaming_packages=(
        # Steam and compatibility
        steam
        
        # Wine and Proton dependencies
        wine-staging
        wine-gecko
        wine-mono
        winetricks
        
        # Vulkan
        vulkan-icd-loader
        lib32-vulkan-icd-loader
        vulkan-tools
        
        # Game utilities
        gamemode
        lib32-gamemode
        mangohud
        lib32-mangohud
    )
    
    log "Installing gaming packages..."
    sudo pacman -S --needed --noconfirm "${gaming_packages[@]}"
    
    # AUR gaming packages
    log "Installing AUR gaming packages..."
    yay -S --needed --noconfirm \
        protonup-qt \
        heroic-games-launcher-bin \
        bottles \
        game-devices-udev
    
    success "Gaming packages installed"
}

install_theming_packages() {
    section "Installing Theming Packages"
    
    local theme_packages=(
        # GTK theming
        gtk3
        gtk4
        nwg-look
        
        # Qt theming
        qt5ct
        qt6ct
        kvantum
        kvantum-qt5
        
        # Icon themes
        papirus-icon-theme
        
        # Cursor themes
        capitaine-cursors
    )
    
    log "Installing theming packages..."
    sudo pacman -S --needed --noconfirm "${theme_packages[@]}"
    
    # AUR theming packages
    log "Installing Gruvbox themes from AUR..."
    yay -S --needed --noconfirm \
        gruvbox-dark-gtk \
        gruvbox-dark-icons-gtk \
        gruvbox-material-gtk-theme-git \
        gruvbox-material-icon-theme-git \
        kvantum-theme-gruvbox-git
    
    success "Theming packages installed"
}

#==============================================================================
# Configuration Functions
#==============================================================================

create_directories() {
    section "Creating Configuration Directories"
    
    local dirs=(
        "$CONFIG_DIR/hypr"
        "$CONFIG_DIR/waybar"
        "$CONFIG_DIR/rofi"
        "$CONFIG_DIR/dunst"
        "$CONFIG_DIR/alacritty"
        "$CONFIG_DIR/nvim"
        "$CONFIG_DIR/gtk-3.0"
        "$CONFIG_DIR/gtk-4.0"
        "$CONFIG_DIR/qt5ct"
        "$CONFIG_DIR/qt6ct"
        "$CONFIG_DIR/Kvantum"
        "$CONFIG_DIR/hypr/scripts"
        "$HOME/.local/share/icons"
        "$HOME/.local/share/themes"
        "$HOME/Pictures/Wallpapers"
        "$HOME/Projects"
        "$HOME/Downloads"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        log "Created: $dir"
    done
    
    success "Directories created"
}

configure_hyprland() {
    section "Configuring Hyprland"
    
    cat > "$CONFIG_DIR/hypr/hyprland.conf" << 'HYPRCONF'
#==============================================================================
#  Hyprland Configuration - Gruvbox Theme
#==============================================================================

# Monitor configuration (auto-detect)
monitor=,preferred,auto,auto

# Execute at launch
exec-once = hyprpaper
exec-once = waybar
exec-once = dunst
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = nm-applet --indicator
exec-once = blueman-applet
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = hypridle

# Environment variables
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,capitaine-cursors
env = QT_QPA_PLATFORM,wayland
env = QT_QPA_PLATFORMTHEME,qt6ct
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = QT_AUTO_SCREEN_SCALE_FACTOR,1
env = GDK_BACKEND,wayland,x11
env = SDL_VIDEODRIVER,wayland
env = CLUTTER_BACKEND,wayland
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = GTK_THEME,Gruvbox-Dark

# NVIDIA specific (uncomment if using NVIDIA)
# env = LIBVA_DRIVER_NAME,nvidia
# env = __GLX_VENDOR_LIBRARY_NAME,nvidia
# env = WLR_NO_HARDWARE_CURSORS,1

#==============================================================================
# Input Configuration
#==============================================================================

input {
    kb_layout = us
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =
    follow_mouse = 1
    touchpad {
        natural_scroll = true
        tap-to-click = true
    }
    sensitivity = 0
}

#==============================================================================
# General Configuration
#==============================================================================

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(d79921ff) rgba(98971aff) 45deg
    col.inactive_border = rgba(504945ff)
    layout = dwindle
    allow_tearing = false
}

#==============================================================================
# Decoration (Gruvbox Themed)
#==============================================================================

decoration {
    rounding = 10
    blur {
        enabled = true
        size = 8
        passes = 2
        new_optimizations = true
        xray = false
    }
    shadow {
        enabled = true
        range = 15
        render_power = 3
        color = rgba(1d2021aa)
    }
}

#==============================================================================
# Animations
#==============================================================================

animations {
    enabled = true
    bezier = overshot, 0.13, 0.99, 0.29, 1.1
    bezier = smoothOut, 0.36, 0, 0.66, -0.56
    bezier = smoothIn, 0.25, 1, 0.5, 1
    
    animation = windows, 1, 5, overshot, slide
    animation = windowsOut, 1, 4, smoothOut, slide
    animation = windowsMove, 1, 4, default
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 5, smoothIn
    animation = fadeDim, 1, 5, smoothIn
    animation = workspaces, 1, 6, default
}

#==============================================================================
# Layouts
#==============================================================================

dwindle {
    pseudotile = true
    preserve_split = true
    force_split = 2
}

master {
    new_status = master
}

gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
}

misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
    disable_splash_rendering = true
    mouse_move_enables_dpms = true
    key_press_enables_dpms = true
}

#==============================================================================
# Window Rules
#==============================================================================

# Float specific windows
windowrulev2 = float, class:^(pavucontrol)$
windowrulev2 = float, class:^(blueman-manager)$
windowrulev2 = float, class:^(nm-connection-editor)$
windowrulev2 = float, class:^(nemo)$, title:^(.*Properties.*)$
windowrulev2 = float, class:^(nemo)$, title:^(File Operations)$
windowrulev2 = float, title:^(Picture-in-Picture)$
windowrulev2 = float, class:^(imv)$
windowrulev2 = float, class:^(org.gnome.Calculator)$

# Gaming rules
windowrulev2 = immediate, class:^(steam_app_)(.*)$
windowrulev2 = fullscreen, class:^(steam_app_)(.*)$

# Opacity rules (Gruvbox semi-transparent feel)
windowrulev2 = opacity 0.95 0.85, class:^(Alacritty)$
windowrulev2 = opacity 0.95 0.85, class:^(code)$

#==============================================================================
# Keybindings
#==============================================================================

$mainMod = SUPER

# Core applications
bind = $mainMod, Return, exec, alacritty
bind = $mainMod, E, exec, nemo
bind = $mainMod, B, exec, firefox
bind = $mainMod, C, exec, code

# Rofi menus
bind = $mainMod, D, exec, rofi -show drun -theme ~/.config/rofi/gruvbox.rasi
bind = $mainMod, R, exec, rofi -show run -theme ~/.config/rofi/gruvbox.rasi
bind = $mainMod, V, exec, cliphist list | rofi -dmenu -theme ~/.config/rofi/gruvbox.rasi | cliphist decode | wl-copy

# Window management
bind = $mainMod, Q, killactive,
bind = $mainMod SHIFT, Q, exit,
bind = $mainMod, F, fullscreen,
bind = $mainMod SHIFT, F, togglefloating,
bind = $mainMod, P, pseudo,
bind = $mainMod, S, togglesplit,

# Focus movement
bind = $mainMod, H, movefocus, l
bind = $mainMod, L, movefocus, r
bind = $mainMod, K, movefocus, u
bind = $mainMod, J, movefocus, d

# Window movement
bind = $mainMod SHIFT, H, movewindow, l
bind = $mainMod SHIFT, L, movewindow, r
bind = $mainMod SHIFT, K, movewindow, u
bind = $mainMod SHIFT, J, movewindow, d

# Resize mode
bind = $mainMod CTRL, H, resizeactive, -50 0
bind = $mainMod CTRL, L, resizeactive, 50 0
bind = $mainMod CTRL, K, resizeactive, 0 -50
bind = $mainMod CTRL, J, resizeactive, 0 50

# Workspace switching
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

# Move window to workspace
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

# Special workspace (scratchpad)
bind = $mainMod, grave, togglespecialworkspace, magic
bind = $mainMod SHIFT, grave, movetoworkspace, special:magic

# Scroll through workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Mouse bindings
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Screenshot
bind = , Print, exec, grim - | wl-copy
bind = SHIFT, Print, exec, grim -g "$(slurp)" - | wl-copy
bind = $mainMod, Print, exec, grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png

# Screen lock
bind = $mainMod SHIFT, X, exec, hyprlock

# Media keys
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bind = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

# Brightness keys
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Media playback
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous
HYPRCONF

    success "Hyprland configuration created"
}

configure_hyprpaper() {
    section "Configuring Hyprpaper"
    
    # Download a Gruvbox-themed wallpaper
    log "Downloading Gruvbox wallpaper..."
    curl -sL "https://raw.githubusercontent.com/lunik1/gruvbox-wallpapers/main/wallpapers/minimalistic/gruvbox_grid.png" \
        -o "$HOME/Pictures/Wallpapers/gruvbox-wallpaper.png" 2>/dev/null || {
        # Create a solid Gruvbox color wallpaper as fallback
        convert -size 1920x1080 "xc:#282828" "$HOME/Pictures/Wallpapers/gruvbox-wallpaper.png" 2>/dev/null || true
    }
    
    cat > "$CONFIG_DIR/hypr/hyprpaper.conf" << HYPRPAPER
preload = ~/Pictures/Wallpapers/gruvbox-wallpaper.png
wallpaper = ,~/Pictures/Wallpapers/gruvbox-wallpaper.png
splash = false
HYPRPAPER

    success "Hyprpaper configured"
}

configure_hyprlock() {
    section "Configuring Hyprlock"
    
    cat > "$CONFIG_DIR/hypr/hyprlock.conf" << 'HYPRLOCK'
# Gruvbox themed Hyprlock configuration

general {
    disable_loading_bar = false
    hide_cursor = true
    grace = 0
    no_fade_in = false
}

background {
    monitor =
    path = screenshot
    blur_passes = 3
    blur_size = 8
    color = rgba(40, 40, 40, 1.0)
}

input-field {
    monitor =
    size = 300, 50
    outline_thickness = 3
    dots_size = 0.33
    dots_spacing = 0.15
    dots_center = true
    dots_rounding = -1
    outer_color = rgb(215, 153, 33)
    inner_color = rgb(40, 40, 40)
    font_color = rgb(235, 219, 178)
    fade_on_empty = true
    fade_timeout = 1000
    placeholder_text = <i>Enter Password...</i>
    hide_input = false
    rounding = 10
    check_color = rgb(152, 151, 26)
    fail_color = rgb(204, 36, 29)
    fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
    fail_transition = 300
    capslock_color = rgb(254, 128, 25)
    numlock_color = -1
    bothlock_color = -1
    invert_numlock = false
    swap_font_color = false
    position = 0, -20
    halign = center
    valign = center
}

label {
    monitor =
    text = $TIME
    text_align = center
    color = rgba(235, 219, 178, 1.0)
    font_size = 90
    font_family = JetBrainsMono Nerd Font
    rotate = 0
    position = 0, 150
    halign = center
    valign = center
}

label {
    monitor =
    text = Hi, $USER
    text_align = center
    color = rgba(215, 153, 33, 1.0)
    font_size = 20
    font_family = JetBrainsMono Nerd Font
    rotate = 0
    position = 0, 70
    halign = center
    valign = center
}
HYPRLOCK

    success "Hyprlock configured"
}

configure_hypridle() {
    section "Configuring Hypridle"
    
    cat > "$CONFIG_DIR/hypr/hypridle.conf" << 'HYPRIDLE'
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

listener {
    timeout = 300
    on-timeout = brightnessctl -s set 30
    on-resume = brightnessctl -r
}

listener {
    timeout = 600
    on-timeout = loginctl lock-session
}

listener {
    timeout = 660
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}

listener {
    timeout = 1800
    on-timeout = systemctl suspend
}
HYPRIDLE

    success "Hypridle configured"
}

configure_waybar() {
    section "Configuring Waybar"
    
    # Main config
    cat > "$CONFIG_DIR/waybar/config.jsonc" << 'WAYBARCONFIG'
{
    "layer": "top",
    "position": "top",
    "height": 36,
    "spacing": 0,
    "margin-top": 5,
    "margin-left": 10,
    "margin-right": 10,
    
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": ["tray", "pulseaudio", "network", "bluetooth", "cpu", "memory", "battery"],
    
    "hyprland/workspaces": {
        "format": "{icon}",
        "format-icons": {
            "1": "󰲠",
            "2": "󰲢",
            "3": "󰲤",
            "4": "󰲦",
            "5": "󰲨",
            "6": "󰲪",
            "7": "󰲬",
            "8": "󰲮",
            "9": "󰲰",
            "10": "󰿬",
            "urgent": "",
            "active": "",
            "default": ""
        },
        "on-click": "activate",
        "sort-by-number": true
    },
    
    "hyprland/window": {
        "format": "  {}",
        "max-length": 50,
        "separate-outputs": true
    },
    
    "clock": {
        "format": "  {:%H:%M}",
        "format-alt": "  {:%A, %B %d, %Y}",
        "tooltip-format": "<tt><small>{calendar}</small></tt>",
        "calendar": {
            "mode": "month",
            "mode-mon-col": 3,
            "weeks-pos": "right",
            "on-scroll": 1,
            "format": {
                "months": "<span color='#d79921'><b>{}</b></span>",
                "days": "<span color='#ebdbb2'><b>{}</b></span>",
                "weeks": "<span color='#98971a'><b>W{}</b></span>",
                "weekdays": "<span color='#d65d0e'><b>{}</b></span>",
                "today": "<span color='#cc241d'><b><u>{}</u></b></span>"
            }
        }
    },
    
    "tray": {
        "icon-size": 16,
        "spacing": 10
    },
    
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-bluetooth": "{icon} {volume}%",
        "format-muted": "󰝟 Muted",
        "format-icons": {
            "headphone": "󰋋",
            "hands-free": "󰋋",
            "headset": "󰋋",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["󰕿", "󰖀", "󰕾"]
        },
        "scroll-step": 5,
        "on-click": "pavucontrol"
    },
    
    "network": {
        "format-wifi": "󰤨 {signalStrength}%",
        "format-ethernet": "󰈀 Connected",
        "format-disconnected": "󰤭 Disconnected",
        "tooltip-format-wifi": "{essid} ({signalStrength}%)",
        "tooltip-format-ethernet": "{ifname}",
        "on-click": "nm-connection-editor"
    },
    
    "bluetooth": {
        "format": "󰂯",
        "format-connected": "󰂱 {device_alias}",
        "format-disabled": "󰂲",
        "tooltip-format": "{controller_alias}\t{controller_address}",
        "tooltip-format-connected": "{controller_alias}\t{controller_address}\n\n{device_enumerate}",
        "tooltip-format-enumerate-connected": "{device_alias}\t{device_address}",
        "on-click": "blueman-manager"
    },
    
    "cpu": {
        "format": "󰻠 {usage}%",
        "interval": 2,
        "on-click": "alacritty -e btop"
    },
    
    "memory": {
        "format": "󰍛 {percentage}%",
        "interval": 2,
        "on-click": "alacritty -e btop"
    },
    
    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-charging": "󰂄 {capacity}%",
        "format-plugged": "󰚥 {capacity}%",
        "format-icons": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    }
}
WAYBARCONFIG

    # Waybar CSS (Gruvbox themed)
    cat > "$CONFIG_DIR/waybar/style.css" << 'WAYBARCSS'
/* Gruvbox Color Palette */
@define-color bg0 #282828;
@define-color bg1 #3c3836;
@define-color bg2 #504945;
@define-color bg3 #665c54;
@define-color fg0 #fbf1c7;
@define-color fg1 #ebdbb2;
@define-color fg2 #d5c4a1;
@define-color red #cc241d;
@define-color green #98971a;
@define-color yellow #d79921;
@define-color blue #458588;
@define-color purple #b16286;
@define-color aqua #689d6a;
@define-color orange #d65d0e;

* {
    font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free";
    font-size: 13px;
    font-weight: bold;
    min-height: 0;
}

window#waybar {
    background: alpha(@bg0, 0.9);
    border-radius: 10px;
    color: @fg1;
}

#workspaces {
    background: @bg1;
    border-radius: 10px;
    margin: 5px;
    padding: 0 10px;
}

#workspaces button {
    color: @fg2;
    padding: 0 8px;
    border-radius: 5px;
    transition: all 0.3s ease;
}

#workspaces button:hover {
    background: @bg2;
    color: @fg0;
}

#workspaces button.active {
    background: @yellow;
    color: @bg0;
}

#workspaces button.urgent {
    background: @red;
    color: @fg0;
}

#window {
    color: @fg1;
    margin: 5px;
    padding: 0 15px;
}

#clock {
    background: @bg1;
    color: @yellow;
    border-radius: 10px;
    margin: 5px;
    padding: 0 15px;
}

#tray {
    background: @bg1;
    border-radius: 10px;
    margin: 5px;
    padding: 0 10px;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background: @red;
}

#pulseaudio,
#network,
#bluetooth,
#cpu,
#memory,
#battery {
    background: @bg1;
    border-radius: 10px;
    margin: 5px 2px;
    padding: 0 12px;
}

#pulseaudio {
    color: @aqua;
}

#pulseaudio.muted {
    color: @red;
}

#network {
    color: @blue;
}

#network.disconnected {
    color: @red;
}

#bluetooth {
    color: @purple;
}

#bluetooth.disabled {
    color: @bg3;
}

#cpu {
    color: @orange;
}

#memory {
    color: @green;
}

#battery {
    color: @green;
}

#battery.warning {
    color: @yellow;
}

#battery.critical {
    color: @red;
    animation: blink 0.5s linear infinite alternate;
}

#battery.charging {
    color: @aqua;
}

@keyframes blink {
    to {
        background-color: @red;
        color: @fg0;
    }
}

tooltip {
    background: @bg0;
    border: 2px solid @yellow;
    border-radius: 10px;
}

tooltip label {
    color: @fg1;
}
WAYBARCSS

    success "Waybar configured"
}

configure_rofi() {
    section "Configuring Rofi"
    
    cat > "$CONFIG_DIR/rofi/gruvbox.rasi" << 'ROFICONF'
/* Gruvbox theme for Rofi */

* {
    /* Gruvbox colors */
    bg0:        #282828;
    bg1:        #3c3836;
    bg2:        #504945;
    bg3:        #665c54;
    fg0:        #fbf1c7;
    fg1:        #ebdbb2;
    fg2:        #d5c4a1;
    red:        #cc241d;
    green:      #98971a;
    yellow:     #d79921;
    blue:       #458588;
    purple:     #b16286;
    aqua:       #689d6a;
    orange:     #d65d0e;
    
    /* Theme colors */
    background-color:   @bg0;
    text-color:         @fg1;
    
    font: "JetBrainsMono Nerd Font 12";
}

window {
    background-color:   @bg0;
    border:             3px solid;
    border-color:       @yellow;
    border-radius:      12px;
    width:              600px;
    padding:            20px;
}

mainbox {
    background-color:   transparent;
    children:           [ inputbar, listview ];
    spacing:            15px;
}

inputbar {
    background-color:   @bg1;
    border-radius:      8px;
    padding:            12px;
    children:           [ prompt, entry ];
    spacing:            10px;
}

prompt {
    background-color:   @yellow;
    text-color:         @bg0;
    border-radius:      6px;
    padding:            6px 12px;
    font:               "JetBrainsMono Nerd Font Bold 12";
}

entry {
    background-color:   transparent;
    text-color:         @fg1;
    placeholder:        "Search...";
    placeholder-color:  @bg3;
    padding:            6px;
}

listview {
    background-color:   transparent;
    columns:            1;
    lines:              8;
    spacing:            5px;
    scrollbar:          false;
}

element {
    background-color:   transparent;
    text-color:         @fg1;
    border-radius:      8px;
    padding:            10px 15px;
}

element normal.normal {
    background-color:   transparent;
    text-color:         @fg1;
}

element selected.normal {
    background-color:   @bg2;
    text-color:         @yellow;
}

element alternate.normal {
    background-color:   transparent;
    text-color:         @fg1;
}

element-icon {
    size:               24px;
    margin:             0 10px 0 0;
}

element-text {
    background-color:   transparent;
    text-color:         inherit;
    vertical-align:     0.5;
}

scrollbar {
    handle-color:       @yellow;
    handle-width:       8px;
    border-radius:      4px;
}
ROFICONF

    # Config file
    cat > "$CONFIG_DIR/rofi/config.rasi" << 'ROFICONFIG'
configuration {
    modi: "drun,run,window";
    show-icons: true;
    icon-theme: "Gruvbox-Material-Dark";
    terminal: "alacritty";
    drun-display-format: "{name}";
    disable-history: false;
    sidebar-mode: false;
}

@theme "~/.config/rofi/gruvbox.rasi"
ROFICONFIG

    success "Rofi configured"
}

configure_dunst() {
    section "Configuring Dunst"
    
    cat > "$CONFIG_DIR/dunst/dunstrc" << 'DUNSTCONF'
[global]
    monitor = 0
    follow = mouse
    
    # Geometry
    width = 350
    height = 150
    origin = top-right
    offset = 15x50
    
    # Progress bar
    progress_bar = true
    progress_bar_height = 10
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 300
    
    # Display
    indicate_hidden = yes
    shrink = no
    transparency = 0
    separator_height = 2
    padding = 15
    horizontal_padding = 15
    text_icon_padding = 15
    frame_width = 2
    frame_color = "#d79921"
    separator_color = frame
    sort = yes
    idle_threshold = 120
    
    # Text
    font = JetBrainsMono Nerd Font 10
    line_height = 0
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
    
    # Icons
    icon_position = left
    min_icon_size = 0
    max_icon_size = 48
    icon_path = /usr/share/icons/Gruvbox-Material-Dark/16x16/status/:/usr/share/icons/Gruvbox-Material-Dark/16x16/devices/:/usr/share/icons/Gruvbox-Material-Dark/16x16/apps/
    
    # History
    sticky_history = yes
    history_length = 20
    
    # Misc
    dmenu = /usr/bin/rofi -dmenu -theme ~/.config/rofi/gruvbox.rasi
    browser = /usr/bin/firefox
    always_run_script = true
    title = Dunst
    class = Dunst
    corner_radius = 10
    ignore_dbusclose = false
    
    # Mouse
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

[urgency_low]
    background = "#282828"
    foreground = "#ebdbb2"
    frame_color = "#98971a"
    timeout = 5

[urgency_normal]
    background = "#282828"
    foreground = "#ebdbb2"
    frame_color = "#d79921"
    timeout = 10

[urgency_critical]
    background = "#282828"
    foreground = "#ebdbb2"
    frame_color = "#cc241d"
    timeout = 0
DUNSTCONF

    success "Dunst configured"
}

configure_alacritty() {
    section "Configuring Alacritty"
    
    cat > "$CONFIG_DIR/alacritty/alacritty.toml" << 'ALACRITTYCONF'
# Alacritty Configuration - Gruvbox Theme

[env]
TERM = "xterm-256color"

[window]
padding = { x = 15, y = 15 }
decorations = "None"
opacity = 0.95
dynamic_title = true
class = { instance = "Alacritty", general = "Alacritty" }

[scrolling]
history = 10000
multiplier = 3

[font]
normal = { family = "JetBrainsMono Nerd Font", style = "Regular" }
bold = { family = "JetBrainsMono Nerd Font", style = "Bold" }
italic = { family = "JetBrainsMono Nerd Font", style = "Italic" }
bold_italic = { family = "JetBrainsMono Nerd Font", style = "Bold Italic" }
size = 12.0

[cursor]
style = { shape = "Block", blinking = "On" }
blink_interval = 750
unfocused_hollow = true

[selection]
save_to_clipboard = true

# Gruvbox Dark Theme
[colors.primary]
background = "#282828"
foreground = "#ebdbb2"

[colors.cursor]
text = "#282828"
cursor = "#ebdbb2"

[colors.vi_mode_cursor]
text = "#282828"
cursor = "#ebdbb2"

[colors.selection]
text = "CellForeground"
background = "#504945"

[colors.normal]
black = "#282828"
red = "#cc241d"
green = "#98971a"
yellow = "#d79921"
blue = "#458588"
magenta = "#b16286"
cyan = "#689d6a"
white = "#a89984"

[colors.bright]
black = "#928374"
red = "#fb4934"
green = "#b8bb26"
yellow = "#fabd2f"
blue = "#83a598"
magenta = "#d3869b"
cyan = "#8ec07c"
white = "#ebdbb2"
ALACRITTYCONF

    success "Alacritty configured"
}

configure_gtk() {
    section "Configuring GTK Theming"
    
    # GTK 3.0
    cat > "$CONFIG_DIR/gtk-3.0/settings.ini" << 'GTK3'
[Settings]
gtk-theme-name=Gruvbox-Dark
gtk-icon-theme-name=Gruvbox-Material-Dark
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-cursor-theme-name=capitaine-cursors
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
GTK3

    # GTK 4.0
    mkdir -p "$CONFIG_DIR/gtk-4.0"
    cat > "$CONFIG_DIR/gtk-4.0/settings.ini" << 'GTK4'
[Settings]
gtk-theme-name=Gruvbox-Dark
gtk-icon-theme-name=Gruvbox-Material-Dark
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-cursor-theme-name=capitaine-cursors
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
gtk-hint-font-metrics=1
GTK4

    # Set environment variables for GTK
    cat >> "$HOME/.profile" << 'PROFILE'
# GTK Theming
export GTK_THEME=Gruvbox-Dark
export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
PROFILE

    # GTK 2.0
    cat > "$HOME/.gtkrc-2.0" << 'GTK2'
gtk-theme-name="Gruvbox-Dark"
gtk-icon-theme-name="Gruvbox-Material-Dark"
gtk-font-name="JetBrainsMono Nerd Font 11"
gtk-cursor-theme-name="capitaine-cursors"
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintfull"
gtk-xft-rgba="rgb"
GTK2

    success "GTK theming configured"
}

configure_qt() {
    section "Configuring Qt Theming"
    
    # Qt5ct configuration
    mkdir -p "$CONFIG_DIR/qt5ct"
    cat > "$CONFIG_DIR/qt5ct/qt5ct.conf" << 'QT5CT'
[Appearance]
color_scheme_path=/usr/share/qt5ct/colors/darker.conf
custom_palette=true
icon_theme=Gruvbox-Material-Dark
standard_dialogs=default
style=kvantum-dark

[Fonts]
fixed="JetBrainsMono Nerd Font,11,-1,5,50,0,0,0,0,0"
general="JetBrainsMono Nerd Font,11,-1,5,50,0,0,0,0,0"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3

[SettingsWindow]
geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\x3\x85\0\0\x1\x11\0\0\x5\x84\0\0\x3\xc0\0\0\x3\x86\0\0\x1\x12\0\0\x5\x83\0\0\x3\xbf\0\0\0\0\0\0\0\0\a\x80\0\0\x3\x86\0\0\x1\x12\0\0\x5\x83\0\0\x3\xbf)
QT5CT

    # Qt6ct configuration
    mkdir -p "$CONFIG_DIR/qt6ct"
    cat > "$CONFIG_DIR/qt6ct/qt6ct.conf" << 'QT6CT'
[Appearance]
color_scheme_path=
custom_palette=true
icon_theme=Gruvbox-Material-Dark
standard_dialogs=default
style=kvantum-dark

[Fonts]
fixed="JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
general="JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3
QT6CT

    # Environment variables for Qt
    cat >> "$HOME/.profile" << 'QTPROFILE'

# Qt Theming
export QT_QPA_PLATFORMTHEME=qt6ct
export QT_STYLE_OVERRIDE=kvantum-dark
QTPROFILE

    success "Qt theming configured"
}

configure_kvantum() {
    section "Configuring Kvantum"
    
    mkdir -p "$CONFIG_DIR/Kvantum"
    cat > "$CONFIG_DIR/Kvantum/kvantum.kvconfig" << 'KVANTUM'
[General]
theme=gruvbox-kvantum
KVANTUM

    success "Kvantum configured"
}

configure_cursor() {
    section "Configuring Cursor Theme"
    
    mkdir -p "$HOME/.local/share/icons/default"
    cat > "$HOME/.local/share/icons/default/index.theme" << 'CURSOR'
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=capitaine-cursors
CURSOR

    success "Cursor theme configured"
}

configure_sddm() {
    section "Configuring SDDM Display Manager"
    
    # Install Gruvbox SDDM theme from AUR
    log "Installing SDDM theme..."
    yay -S --needed --noconfirm sddm-theme-corners-git 2>/dev/null || true
    
    # Configure SDDM
    sudo mkdir -p /etc/sddm.conf.d
    
    # Main SDDM configuration
    sudo tee /etc/sddm.conf.d/default.conf << 'SDDMCONF'
[General]
InputMethod=
Numlock=on

[Theme]
Current=corners
CursorTheme=capitaine-cursors
CursorSize=24

[Users]
MaximumUid=60513
MinimumUid=1000
RememberLastSession=true
RememberLastUser=true

[Wayland]
SessionDir=/usr/share/wayland-sessions
SessionCommand=/usr/share/sddm/scripts/wayland-session
SDDMCONF

    # Create Hyprland-specific SDDM config
    sudo tee /etc/sddm.conf.d/hyprland.conf << 'HYPRLANDSDDM'
[General]
Session=hyprland.desktop

[Autologin]
# Uncomment below lines for auto-login (replace USERNAME with your username)
# User=USERNAME
# Session=hyprland.desktop
HYPRLANDSDDM

    # Ensure wayland-sessions directory exists and has proper permissions
    sudo mkdir -p /usr/share/wayland-sessions
    
    # Enable SDDM service
    log "Enabling SDDM service..."
    sudo systemctl enable sddm.service
    
    # Disable any other display managers that might conflict
    sudo systemctl disable gdm.service 2>/dev/null || true
    sudo systemctl disable lightdm.service 2>/dev/null || true
    
    success "SDDM configured for Hyprland"
}

configure_neovim() {
    section "Configuring Neovim"
    
    # Create base neovim config with Gruvbox
    cat > "$CONFIG_DIR/nvim/init.lua" << 'NVIMCONF'
-- Neovim Configuration - Gruvbox Theme

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.showmode = false
vim.opt.clipboard = "unnamedplus"
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split"
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.hlsearch = true
vim.opt.termguicolors = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Plugins
require("lazy").setup({
    -- Gruvbox colorscheme
    {
        "ellisonleao/gruvbox.nvim",
        priority = 1000,
        config = function()
            require("gruvbox").setup({
                terminal_colors = true,
                undercurl = true,
                underline = true,
                bold = true,
                italic = {
                    strings = true,
                    emphasis = true,
                    comments = true,
                    operators = false,
                    folds = true,
                },
                strikethrough = true,
                invert_selection = false,
                invert_signs = false,
                invert_tabline = false,
                invert_intend_guides = false,
                inverse = true,
                contrast = "hard",
                palette_overrides = {},
                overrides = {},
                dim_inactive = false,
                transparent_mode = false,
            })
            vim.cmd("colorscheme gruvbox")
        end,
    },

    -- File explorer
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        config = function()
            require("neo-tree").setup({
                close_if_last_window = true,
                window = {
                    width = 30,
                },
            })
            vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { silent = true })
        end,
    },

    -- Statusline
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = {
                    theme = "gruvbox",
                    component_separators = { left = "", right = "" },
                    section_separators = { left = "", right = "" },
                },
            })
        end,
    },

    -- Fuzzy finder
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.5",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
            vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
        end,
    },

    -- Treesitter
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "bash", "c", "cpp", "css", "go", "html", "javascript",
                    "json", "lua", "markdown", "python", "rust", "typescript",
                    "vim", "vimdoc", "yaml"
                },
                highlight = { enable = true },
                indent = { enable = true },
            })
        end,
    },

    -- LSP
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
        },
        config = function()
            require("mason").setup()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls", "pyright", "ts_ls", "rust_analyzer", "clangd"
                },
            })
            
            local lspconfig = require("lspconfig")
            local servers = { "lua_ls", "pyright", "ts_ls", "rust_analyzer", "clangd" }
            
            for _, lsp in ipairs(servers) do
                lspconfig[lsp].setup({})
            end
            
            -- LSP keybindings
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
            vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})
        end,
    },

    -- Autocompletion
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            
            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = cmp.mapping.select_next_item(),
                    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "buffer" },
                    { name = "path" },
                }),
            })
        end,
    },

    -- Git integration
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup()
        end,
    },

    -- Autopairs
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true,
    },

    -- Comments
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup()
        end,
    },

    -- Indent guides
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        opts = {},
    },

    -- Which key
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        config = function()
            require("which-key").setup()
        end,
    },
})
NVIMCONF

    success "Neovim configured with Gruvbox and plugins"
}

configure_shell() {
    section "Configuring Shell"
    
    # Add shell enhancements to .bashrc
    cat >> "$HOME/.bashrc" << 'BASHRC'

# Gruvbox Hyprland Shell Configuration

# Starship prompt
eval "$(starship init bash)"

# Zoxide
eval "$(zoxide init bash)"

# FNM (Fast Node Manager)
eval "$(fnm env --use-on-cd)"

# Aliases
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias la='eza -a --icons --group-directories-first'
alias lt='eza --tree --icons --group-directories-first'
alias cat='bat --theme=gruvbox-dark'
alias vim='nvim'
alias vi='nvim'
alias ..='cd ..'
alias ...='cd ../..'
alias g='git'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gs='git status'
alias gd='git diff'
alias lg='lazygit'
alias ld='lazydocker'

# PATH
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Editor
export EDITOR=nvim
export VISUAL=nvim

# Man pages with bat
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
BASHRC

    # Configure Starship prompt with Gruvbox colors
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_DIR/starship.toml" << 'STARSHIP'
# Starship Prompt - Gruvbox Theme

format = """
[░▒▓](#d79921)\
$os\
$username\
[](bg:#98971a fg:#d79921)\
$directory\
[](fg:#98971a bg:#458588)\
$git_branch\
$git_status\
[](fg:#458588 bg:#689d6a)\
$c\
$rust\
$golang\
$nodejs\
$python\
[](fg:#689d6a bg:#b16286)\
$docker_context\
[](fg:#b16286 bg:#d65d0e)\
$time\
[ ](fg:#d65d0e)\
"""

# Disable the blank line at the start of the prompt
add_newline = false

[os]
disabled = false
style = "bg:#d79921 fg:#282828"

[os.symbols]
Arch = "󰣇"
Debian = "󰣚"
Fedora = "󰣛"
Linux = "󰌽"
Macos = "󰀵"
Ubuntu = "󰕈"
Windows = "󰍲"

[username]
show_always = true
style_user = "bg:#d79921 fg:#282828"
style_root = "bg:#d79921 fg:#282828"
format = '[$user ]($style)'
disabled = false

[directory]
style = "bg:#98971a fg:#282828"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[directory.substitutions]
"Documents" = "󰈙 "
"Downloads" = " "
"Music" = " "
"Pictures" = " "
"Projects" = "󰲋 "

[git_branch]
symbol = ""
style = "bg:#458588 fg:#ebdbb2"
format = '[ $symbol $branch ]($style)'

[git_status]
style = "bg:#458588 fg:#ebdbb2"
format = '[$all_status$ahead_behind ]($style)'

[c]
symbol = " "
style = "bg:#689d6a fg:#282828"
format = '[ $symbol ($version) ]($style)'

[rust]
symbol = ""
style = "bg:#689d6a fg:#282828"
format = '[ $symbol ($version) ]($style)'

[golang]
symbol = ""
style = "bg:#689d6a fg:#282828"
format = '[ $symbol ($version) ]($style)'

[nodejs]
symbol = ""
style = "bg:#689d6a fg:#282828"
format = '[ $symbol ($version) ]($style)'

[python]
symbol = ""
style = "bg:#689d6a fg:#282828"
format = '[ $symbol ($version) ]($style)'

[docker_context]
symbol = ""
style = "bg:#b16286 fg:#ebdbb2"
format = '[ $symbol $context ]($style)'

[time]
disabled = false
time_format = "%R"
style = "bg:#d65d0e fg:#ebdbb2"
format = '[ ♥ $time ]($style)'
STARSHIP

    success "Shell configured with Starship and aliases"
}

enable_services() {
    section "Enabling System Services"
    
    log "Enabling essential services..."
    
    # Network
    sudo systemctl enable NetworkManager.service
    
    # Bluetooth
    sudo systemctl enable bluetooth.service
    
    # Audio
    systemctl --user enable pipewire.service
    systemctl --user enable pipewire-pulse.service
    systemctl --user enable wireplumber.service
    
    success "Services enabled"
}

create_scripts() {
    section "Creating Helper Scripts"
    
    # Screenshot script
    cat > "$CONFIG_DIR/hypr/scripts/screenshot.sh" << 'SCREENSHOT'
#!/bin/bash

case "$1" in
    "full")
        grim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png
        notify-send "Screenshot" "Full screen captured"
        ;;
    "area")
        grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png
        notify-send "Screenshot" "Area captured"
        ;;
    "window")
        grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png
        notify-send "Screenshot" "Window captured"
        ;;
esac
SCREENSHOT
    chmod +x "$CONFIG_DIR/hypr/scripts/screenshot.sh"
    
    # Volume control script
    cat > "$CONFIG_DIR/hypr/scripts/volume.sh" << 'VOLUME'
#!/bin/bash

case "$1" in
    "up")
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    "down")
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    "mute")
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
esac

# Show notification
VOLUME=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')
MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o MUTED)

if [ "$MUTED" ]; then
    notify-send -h int:value:$VOLUME -h string:x-canonical-private-synchronous:volume "Volume" "Muted"
else
    notify-send -h int:value:$VOLUME -h string:x-canonical-private-synchronous:volume "Volume" "${VOLUME}%"
fi
VOLUME
    chmod +x "$CONFIG_DIR/hypr/scripts/volume.sh"
    
    # Power menu script
    cat > "$CONFIG_DIR/hypr/scripts/powermenu.sh" << 'POWERMENU'
#!/bin/bash

OPTIONS="󰌾 Lock\n󰍃 Logout\n󰤄 Suspend\n󰜉 Reboot\n󰐥 Shutdown"

CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -p "Power" -theme ~/.config/rofi/gruvbox.rasi)

case "$CHOICE" in
    "󰌾 Lock")
        hyprlock
        ;;
    "󰍃 Logout")
        hyprctl dispatch exit
        ;;
    "󰤄 Suspend")
        systemctl suspend
        ;;
    "󰜉 Reboot")
        systemctl reboot
        ;;
    "󰐥 Shutdown")
        systemctl poweroff
        ;;
esac
POWERMENU
    chmod +x "$CONFIG_DIR/hypr/scripts/powermenu.sh"
    
    mkdir -p "$HOME/Pictures/Screenshots"
    
    success "Helper scripts created"
}

verify_installation() {
    section "Verifying Installation"
    
    local errors=0
    
    # Check Hyprland
    if command -v Hyprland &> /dev/null; then
        log "✓ Hyprland is installed: $(Hyprland --version 2>&1 | head -n1)"
    else
        error "✗ Hyprland is NOT installed!"
        ((errors++))
    fi
    
    # Check session file
    if [ -f /usr/share/wayland-sessions/hyprland.desktop ]; then
        log "✓ Hyprland session file exists"
    else
        error "✗ Hyprland session file missing!"
        ((errors++))
    fi
    
    # Check SDDM
    if systemctl is-enabled sddm.service &> /dev/null; then
        log "✓ SDDM is enabled"
    else
        error "✗ SDDM is not enabled!"
        ((errors++))
    fi
    
    # Check config files
    if [ -f "$CONFIG_DIR/hypr/hyprland.conf" ]; then
        log "✓ Hyprland config exists"
    else
        error "✗ Hyprland config missing!"
        ((errors++))
    fi
    
    # Check waybar
    if command -v waybar &> /dev/null; then
        log "✓ Waybar is installed"
    else
        warn "⚠ Waybar not found"
    fi
    
    # Check terminal
    if command -v alacritty &> /dev/null; then
        log "✓ Alacritty is installed"
    else
        warn "⚠ Alacritty not found"
    fi
    
    # Check launcher
    if command -v rofi &> /dev/null; then
        log "✓ Rofi is installed"
    else
        warn "⚠ Rofi not found"
    fi
    
    # Check GPU driver
    case "$GPU_TYPE" in
        nvidia)
            if pacman -Qs nvidia-dkms &> /dev/null; then
                log "✓ NVIDIA drivers installed"
            else
                warn "⚠ NVIDIA drivers may not be properly installed"
            fi
            ;;
        amd)
            if pacman -Qs mesa &> /dev/null; then
                log "✓ AMD Mesa drivers installed"
            fi
            ;;
    esac
    
    echo ""
    if [ $errors -eq 0 ]; then
        success "All critical components verified!"
    else
        error "Found $errors critical issues. Please review the log."
    fi
}

#==============================================================================
# Main Installation
#==============================================================================

main() {
    print_banner
    
    echo ""
    echo -e "${CYAN}This script will install Hyprland with a complete Gruvbox theme${NC}"
    echo -e "${CYAN}including development tools and gaming support.${NC}"
    echo ""
    echo -e "${YELLOW}Please ensure you have:${NC}"
    echo "  - A fresh Arch Linux installation"
    echo "  - An active internet connection"
    echo "  - Sudo privileges"
    echo ""
    read -p "Press ENTER to continue or Ctrl+C to cancel..."
    
    # Detect GPU first
    detect_gpu
    
    # Start logging
    echo "Installation started at $(date)" > "$LOG_FILE"
    
    # Installation steps
    install_yay
    install_base_packages
    setup_hyprland_session
    install_hyprland_ecosystem
    install_development_tools
    install_gpu_drivers
    install_gaming_packages
    install_theming_packages
    
    # Configuration steps
    create_directories
    configure_hyprland
    configure_hyprpaper
    configure_hyprlock
    configure_hypridle
    configure_waybar
    configure_rofi
    configure_dunst
    configure_alacritty
    configure_gtk
    configure_qt
    configure_kvantum
    configure_cursor
    configure_sddm
    configure_neovim
    configure_shell
    create_scripts
    enable_services
    
    # Verify Hyprland installation
    verify_installation
    
    section "Installation Complete!"
    
    echo -e "${GREEN}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║                    Installation Complete!                             ║
    ║                                                                       ║
    ║   Your Gruvbox-themed Hyprland desktop is ready!                      ║
    ║                                                                       ║
    ║   Key bindings:                                                       ║
    ║   - SUPER + Enter      : Terminal (Alacritty)                         ║
    ║   - SUPER + D          : Application launcher (Rofi)                  ║
    ║   - SUPER + E          : File manager (Nemo)                          ║
    ║   - SUPER + Q          : Close window                                 ║
    ║   - SUPER + F          : Fullscreen                                   ║
    ║   - SUPER + 1-0        : Switch workspaces                            ║
    ║   - SUPER + SHIFT + Q  : Exit Hyprland                                ║
    ║                                                                       ║
    ║   Please reboot your system to start using Hyprland.                  ║
    ║                                                                       ║
    ╚═══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo ""
    echo -e "${YELLOW}Log file saved to: $LOG_FILE${NC}"
    echo ""
    read -p "Would you like to reboot now? (y/N): " REBOOT
    if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
        sudo reboot
    fi
}

# Run main function
main "$@"
