#!/usr/bin/env bash

# Complete Hyprland + Modus Installation Script
# For fresh Arch Linux terminal installations
# This script installs Hyprland, all dependencies, and then Modus

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Functions for colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Banner
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "    Complete Hyprland + Modus Installation Script"
    echo "    From Terminal Arch to Full Desktop Environment"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${NC}"
}

# Check if running on Arch Linux
check_system() {
    print_step "Checking system requirements..."
    
    if [ ! -f /etc/arch-release ]; then
        print_error "This script requires Arch Linux"
        exit 1
    fi
    
    if [ "$EUID" -eq 0 ]; then
        print_error "Do not run this script as root. Run as a normal user with sudo access."
        exit 1
    fi
    
    # Check if user has sudo access
    if ! sudo -v &> /dev/null; then
        print_error "This script requires sudo access"
        exit 1
    fi
    
    print_success "System check passed"
}

# Detect GPU and install appropriate drivers
detect_and_install_gpu_drivers() {
    print_step "Detecting GPU and installing drivers..."
    
    local GPU_TYPE=""
    
    # Detect GPU
    if lspci | grep -i "vga\|3d\|display" | grep -iq "nvidia"; then
        GPU_TYPE="nvidia"
        print_info "NVIDIA GPU detected"
    elif lspci | grep -i "vga\|3d\|display" | grep -iq "amd\|radeon"; then
        GPU_TYPE="amd"
        print_info "AMD GPU detected"
    elif lspci | grep -i "vga\|3d\|display" | grep -iq "intel"; then
        GPU_TYPE="intel"
        print_info "Intel GPU detected"
    else
        GPU_TYPE="generic"
        print_warning "Could not detect GPU, installing generic drivers"
    fi
    
    # Install appropriate drivers
    case $GPU_TYPE in
        nvidia)
            print_info "Installing NVIDIA drivers..."
            sudo pacman -S --needed --noconfirm nvidia nvidia-utils nvidia-settings
            
            # Enable kernel modules
            sudo sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
            sudo mkinitcpio -P
            
            # Set environment variables
            echo "export WLR_NO_HARDWARE_CURSORS=1" >> ~/.bashrc
            echo "export LIBVA_DRIVER_NAME=nvidia" >> ~/.bashrc
            echo "export GBM_BACKEND=nvidia-drm" >> ~/.bashrc
            echo "export __GLX_VENDOR_LIBRARY_NAME=nvidia" >> ~/.bashrc
            ;;
        amd)
            print_info "Installing AMD drivers..."
            sudo pacman -S --needed --noconfirm mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau
            ;;
        intel)
            print_info "Installing Intel drivers..."
            sudo pacman -S --needed --noconfirm mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver
            ;;
        generic)
            print_info "Installing generic drivers..."
            sudo pacman -S --needed --noconfirm mesa lib32-mesa
            ;;
    esac
    
    print_success "GPU drivers installed"
}

# Update system
update_system() {
    print_step "Updating system..."
    sudo pacman -Syu --noconfirm
    print_success "System updated"
}

# Install AUR helper
install_aur_helper() {
    print_step "Installing AUR helper..."
    
    if command -v paru &> /dev/null; then
        print_success "paru is already installed"
        AUR_HELPER="paru"
    elif command -v yay &> /dev/null; then
        print_success "yay is already installed"
        AUR_HELPER="yay"
    else
        print_info "Installing paru AUR helper..."
        sudo pacman -S --needed --noconfirm base-devel git
        
        cd /tmp
        rm -rf paru
        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg -si --noconfirm
        cd ~
        
        AUR_HELPER="paru"
        print_success "paru installed successfully"
    fi
}

# Install Hyprland and core dependencies
install_hyprland() {
    print_step "Installing Hyprland and core dependencies..."
    
    # Check if Hyprland is already installed
    if command -v Hyprland &> /dev/null || command -v hyprland &> /dev/null; then
        print_warning "Hyprland is already installed, skipping installation"
        return
    fi
    
    print_info "Installing Hyprland core packages..."
    
    local HYPRLAND_DEPS=(
        # Core Hyprland
        hyprland
        hyprpaper
        hyprlock
        hypridle
        xdg-desktop-portal-hyprland
        
        # Wayland essentials
        wayland
        wayland-protocols
        wlroots
        
        # XDG and session
        xdg-utils
        xdg-user-dirs
        polkit
        polkit-gnome
        
        # Display and graphics
        mesa
        cairo
        pango
        gdk-pixbuf2
        
        # GTK
        gtk3
        gtk4
        gtk-layer-shell
        
        # Audio
        pipewire
        pipewire-alsa
        pipewire-pulse
        pipewire-jack
        wireplumber
        pavucontrol
        
        # Network
        networkmanager
        network-manager-applet
        
        # Bluetooth
        bluez
        bluez-utils
        blueman
        
        # Notifications
        dunst
        libnotify
        
        # Terminal
        kitty
        
        # File manager
        thunar
        thunar-archive-plugin
        thunar-volman
        tumbler
        file-roller
        
        # Core utilities
        brightnessctl
        playerctl
        pamixer
        grim
        slurp
        wl-clipboard
        cliphist
        
        # Fonts
        ttf-font-awesome
        ttf-jetbrains-mono
        ttf-jetbrains-mono-nerd
        noto-fonts
        noto-fonts-emoji
        noto-fonts-cjk
        
        # Qt support
        qt5-wayland
        qt6-wayland
        qt5ct
        qt6ct
        
        # Archives
        p7zip
        unzip
        unrar
        
        # Development tools
        python
        python-pip
        python-gobject
        python-cairo
    )
    
    print_info "Installing ${#HYPRLAND_DEPS[@]} packages..."
    sudo pacman -S --needed --noconfirm "${HYPRLAND_DEPS[@]}"
    
    print_success "Hyprland and dependencies installed"
}

# Install additional utilities and applications
install_utilities() {
    print_step "Installing additional utilities..."
    
    local UTILITIES=(
        # Browsers (optional)
        firefox
        
        # Image viewer
        imv
        
        # PDF viewer
        zathura
        zathura-pdf-mupdf
        
        # Text editor
        nano
        vim
        
        # System monitor
        htop
        btop
        
        # Screenshot and screen recording
        wf-recorder
        
        # Clipboard manager
        wl-clipboard
        
        # Wallpaper setter
        swaybg
        
        # Application launcher (alternative to Modus launcher)
        wofi
    )
    
    print_info "Do you want to install additional utilities? (firefox, image viewer, PDF reader, etc.)"
    read -p "Install utilities? [Y/n]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        sudo pacman -S --needed --noconfirm "${UTILITIES[@]}"
        print_success "Utilities installed"
    else
        print_info "Skipping utilities installation"
    fi
}

# Install AUR packages for Hyprland
install_hyprland_aur_packages() {
    print_step "Installing AUR packages for Hyprland..."
    
    local AUR_PACKAGES=(
        # Hyprland extras
        hyprpicker
        
        # Themes and appearance
        apple-fonts
    )
    
    print_info "Installing AUR packages..."
    $AUR_HELPER -S --needed --noconfirm "${AUR_PACKAGES[@]}"
    
    print_success "AUR packages installed"
}

# Install Modus dependencies
install_modus_dependencies() {
    print_step "Installing Modus-specific dependencies..."
    
    local MODUS_DEPS_PACMAN=(
        python-pyotp
        python-pillow
        python-ijson
        python-setproctitle
        cinnamon-desktop
    )
    
    local MODUS_DEPS_AUR=(
        glace-git
        gtk-session-lock
    )
    
    print_info "Installing Modus pacman dependencies..."
    sudo pacman -S --needed --noconfirm "${MODUS_DEPS_PACMAN[@]}"
    
    print_info "Installing Modus AUR dependencies..."
    $AUR_HELPER -S --needed --noconfirm "${MODUS_DEPS_AUR[@]}"
    
    print_success "Modus dependencies installed"
}

# Setup XDG user directories
setup_xdg_dirs() {
    print_step "Setting up XDG user directories..."
    
    xdg-user-dirs-update
    
    # Create common directories if they don't exist
    mkdir -p ~/Pictures/Screenshots
    mkdir -p ~/Pictures/Wallpapers
    mkdir -p ~/Documents
    mkdir -p ~/Downloads
    mkdir -p ~/Music
    mkdir -p ~/Videos
    
    print_success "XDG directories created"
}

# Enable system services
enable_services() {
    print_step "Enabling system services..."
    
    # NetworkManager
    if ! systemctl is-enabled NetworkManager &> /dev/null; then
        sudo systemctl enable NetworkManager
        sudo systemctl start NetworkManager
        print_success "Enabled NetworkManager"
    fi
    
    # Bluetooth
    if ! systemctl is-enabled bluetooth &> /dev/null; then
        sudo systemctl enable bluetooth
        sudo systemctl start bluetooth
        print_success "Enabled Bluetooth"
    fi
    
    print_success "System services configured"
}

# Create basic Hyprland configuration
create_basic_hyprland_config() {
    print_step "Creating basic Hyprland configuration..."
    
    mkdir -p ~/.config/hypr
    
    # Backup existing config if it exists
    if [ -f ~/.config/hypr/hyprland.conf ]; then
        BACKUP_FILE="~/.config/hypr/hyprland.conf.backup.$(date +%Y%m%d_%H%M%S)"
        cp ~/.config/hypr/hyprland.conf "$BACKUP_FILE"
        print_info "Backed up existing config to: $BACKUP_FILE"
    fi
    
    # Create a basic Hyprland config
    cat > ~/.config/hypr/hyprland.conf << 'EOF'
# Hyprland Configuration
# Generated by installation script

# Monitor configuration
monitor=,preferred,auto,1

# Startup applications
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = hyprpaper
exec-once = dunst

# Environment variables
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = GDK_BACKEND,wayland,x11
env = QT_QPA_PLATFORM,wayland;xcb
env = QT_QPA_PLATFORMTHEME,qt5ct
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = MOZ_ENABLE_WAYLAND,1
env = SDL_VIDEODRIVER,wayland
env = CLUTTER_BACKEND,wayland

# Input configuration
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = true
        tap-to-click = true
    }
    sensitivity = 0
}

# General settings
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

# Decorations
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
    drop_shadow = true
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Animations
animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Layouts
dwindle {
    pseudotile = true
    preserve_split = true
}

master {
    new_is_master = true
}

# Gestures
gestures {
    workspace_swipe = true
}

# Window rules
windowrulev2 = opacity 0.90 0.90,class:^(kitty)$
windowrulev2 = opacity 0.90 0.90,class:^(thunar)$

# Keybindings
$mainMod = SUPER

# Basic bindings
bind = $mainMod, RETURN, exec, kitty
bind = $mainMod, Q, killactive
bind = $mainMod, M, exit
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating
bind = $mainMod, P, pseudo
bind = $mainMod, J, togglesplit
bind = $mainMod, F, fullscreen

# Application launcher (will be replaced by Modus)
bind = $mainMod, SPACE, exec, wofi --show drun

# Move focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Switch workspaces
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

# Move active window to workspace
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

# Scroll through workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move/resize windows
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Screenshots
bind = , Print, exec, grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png
bind = SHIFT, Print, exec, grim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png

# Media controls
bindl = , XF86AudioPlay, exec, playerctl play-pause
bindl = , XF86AudioNext, exec, playerctl next
bindl = , XF86AudioPrev, exec, playerctl previous
bindl = , XF86AudioStop, exec, playerctl stop

# Volume controls
bindl = , XF86AudioRaiseVolume, exec, pamixer -i 5
bindl = , XF86AudioLowerVolume, exec, pamixer -d 5
bindl = , XF86AudioMute, exec, pamixer -t

# Brightness controls
bindl = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
bindl = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
EOF
    
    print_success "Basic Hyprland configuration created"
}

# Clone and setup Modus
setup_modus() {
    print_step "Setting up Modus shell..."
    
    # Backup existing config if it exists
    if [ -d "$HOME/.config/Modus" ]; then
        print_warning "Existing Modus configuration found"
        BACKUP_DIR="$HOME/.config/Modus.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$HOME/.config/Modus" "$BACKUP_DIR"
        print_info "Backed up to: $BACKUP_DIR"
    fi
    
    # Clone Modus repository
    print_info "Cloning Modus repository..."
    git clone https://github.com/S4NKALP/Modus.git "$HOME/.config/Modus"
    
    cd "$HOME/.config/Modus"
    
    print_success "Modus repository cloned"
}

# Setup Python virtual environment for Modus
setup_python_env() {
    print_step "Setting up Python virtual environment for Modus..."
    
    cd "$HOME/.config/Modus"
    
    # Create virtual environment
    python -m venv .venv
    
    # Activate virtual environment
    source .venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install requirements
    print_info "Installing Python dependencies..."
    if [ -f requirements.txt ]; then
        pip install -r requirements.txt
    fi
    
    # Install Fabric
    print_info "Installing Fabric framework..."
    pip install --no-deps git+https://github.com/Fabric-Development/fabric.git
    
    # Install additional packages
    pip install loguru psutil
    
    deactivate
    
    print_success "Python environment configured"
}

# Install themes
install_themes() {
    print_step "Installing recommended themes..."
    
    print_info "Do you want to install MacTahoe themes? (GTK, Icons, Cursors)"
    read -p "Install themes? [Y/n]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        cd /tmp
        
        # MacTahoe GTK Theme
        if [ ! -d "$HOME/.themes/MacTahoe" ]; then
            print_info "Installing MacTahoe GTK theme..."
            rm -rf MacTahoe-gtk-theme
            git clone https://github.com/vinceliuice/MacTahoe-gtk-theme.git
            cd MacTahoe-gtk-theme
            ./install.sh
            cd ..
        fi
        
        # MacTahoe Icon Theme
        if [ ! -d "$HOME/.icons/MacTahoe" ]; then
            print_info "Installing MacTahoe icon theme..."
            rm -rf MacTahoe-icon-theme
            git clone https://github.com/vinceliuice/MacTahoe-icon-theme.git
            cd MacTahoe-icon-theme
            ./install.sh
            cd ..
            
            # Install cursors
            cd MacTahoe-icon-theme/cursors
            ./install.sh
            cd ../../
        fi
        
        cd ~
        
        print_success "Themes installed"
    else
        print_info "Skipping theme installation"
    fi
}

# Configure GTK settings
configure_gtk() {
    print_step "Configuring GTK settings..."
    
    mkdir -p ~/.config/gtk-3.0
    mkdir -p ~/.config/gtk-4.0
    
    cat > ~/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-theme-name=MacTahoe-dark
gtk-icon-theme-name=MacTahoe
gtk-font-name=SF Pro Display 10
gtk-cursor-theme-name=MacTahoe-cursors
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
EOF
    
    cat > ~/.config/gtk-4.0/settings.ini << EOF
[Settings]
gtk-theme-name=MacTahoe-dark
gtk-icon-theme-name=MacTahoe
gtk-font-name=SF Pro Display 10
gtk-cursor-theme-name=MacTahoe-cursors
gtk-cursor-theme-size=24
EOF
    
    print_success "GTK settings configured"
}

# Create Modus launcher scripts
create_launchers() {
    print_step "Creating launcher scripts..."
    
    mkdir -p ~/.local/bin
    
    # Create Modus launcher
    cat > ~/.local/bin/modus << 'EOF'
#!/usr/bin/env bash
cd ~/.config/Modus
source .venv/bin/activate
python main.py "$@"
EOF
    chmod +x ~/.local/bin/modus
    
    # Create lock screen launcher
    cat > ~/.local/bin/modus-lock << 'EOF'
#!/usr/bin/env bash
cd ~/.config/Modus
source .venv/bin/activate
python lock.py "$@"
EOF
    chmod +x ~/.local/bin/modus-lock
    
    # Add to PATH
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        if [ -f ~/.zshrc ]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
        fi
    fi
    
    print_success "Launcher scripts created"
}

# Integrate Modus with Hyprland
integrate_modus_with_hyprland() {
    print_step "Integrating Modus with Hyprland..."
    
    # Add Modus to Hyprland autostart
    if [ -f ~/.config/hypr/hyprland.conf ]; then
        # Remove wofi launcher and add Modus
        if ! grep -q "exec-once = modus" ~/.config/hypr/hyprland.conf; then
            cat >> ~/.config/hypr/hyprland.conf << EOF

# ============================================
# Modus Shell Configuration
# ============================================
source = ~/.config/Modus/config/hypr/modus.conf

# Autostart Modus
exec-once = modus

# Lock screen binding
bind = SUPER, L, exec, modus-lock

# Cursor theme
env = XCURSOR_THEME,MacTahoe-cursors
env = XCURSOR_SIZE,24
EOF
            print_success "Modus integrated into Hyprland configuration"
        else
            print_info "Modus already integrated"
        fi
    fi
}

# Setup display manager (optional)
setup_display_manager() {
    print_step "Display Manager Setup"
    
    print_info "Do you want to install a display manager (SDDM)?"
    print_info "If you choose 'No', you'll need to start Hyprland manually from TTY"
    read -p "Install SDDM? [Y/n]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        print_info "Installing SDDM..."
        sudo pacman -S --needed --noconfirm sddm
        sudo systemctl enable sddm
        
        print_success "SDDM installed and enabled"
        print_info "SDDM will start on next boot"
    else
        print_info "Skipping display manager installation"
        print_info "You can start Hyprland manually with the 'Hyprland' command from TTY"
        
        # Create a simple launcher script
        cat > ~/.local/bin/start-hyprland << 'EOF'
#!/usr/bin/env bash
# Start Hyprland
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland
Hyprland
EOF
        chmod +x ~/.local/bin/start-hyprland
        
        print_info "Created 'start-hyprland' command for manual launch"
    fi
}

# Create wallpaper configuration
setup_wallpaper() {
    print_step "Setting up wallpaper..."
    
    mkdir -p ~/Pictures/Wallpapers
    
    # Create hyprpaper config
    mkdir -p ~/.config/hypr
    cat > ~/.config/hypr/hyprpaper.conf << EOF
preload = ~/Pictures/Wallpapers/default.jpg
wallpaper = ,~/Pictures/Wallpapers/default.jpg
splash = false
EOF
    
    print_info "Place your wallpaper at: ~/Pictures/Wallpapers/default.jpg"
    print_success "Wallpaper configuration created"
}

# Final system setup
final_setup() {
    print_step "Running final setup..."
    
    # Create environment variables file
    mkdir -p ~/.config/environment.d
    cat > ~/.config/environment.d/hyprland.conf << EOF
# Hyprland environment variables
XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_TYPE=wayland
XDG_SESSION_DESKTOP=Hyprland

# GTK
GTK_THEME=MacTahoe-dark

# QT
QT_QPA_PLATFORM=wayland
QT_QPA_PLATFORMTHEME=qt5ct
QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# Mozilla
MOZ_ENABLE_WAYLAND=1

# SDL
SDL_VIDEODRIVER=wayland
EOF
    
    # Update font cache
    print_info "Updating font cache..."
    fc-cache -fv > /dev/null 2>&1
    
    print_success "Final setup complete"
}

# Print installation summary and next steps
print_summary() {
    clear
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}    Installation Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}What was installed:${NC}"
    echo "  ✓ Hyprland window manager"
    echo "  ✓ GPU drivers (auto-detected)"
    echo "  ✓ Modus shell for Hyprland"
    echo "  ✓ Essential applications (terminal, file manager, etc.)"
    echo "  ✓ Audio (PipeWire), Network (NetworkManager), Bluetooth"
    echo "  ✓ MacTahoe themes (if selected)"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo ""
    
    if systemctl is-enabled sddm &> /dev/null; then
        echo -e "${CYAN}1.${NC} Reboot your system:"
        echo "   sudo reboot"
        echo ""
        echo -e "${CYAN}2.${NC} Select Hyprland from the SDDM login screen"
        echo ""
    else
        echo -e "${CYAN}1.${NC} Reboot or logout:"
        echo "   sudo reboot"
        echo ""
        echo -e "${CYAN}2.${NC} Start Hyprland from TTY:"
        echo "   start-hyprland"
        echo "   (or just run: Hyprland)"
        echo ""
    fi
    
    echo -e "${CYAN}3.${NC} Add a wallpaper:"
    echo "   cp your-wallpaper.jpg ~/Pictures/Wallpapers/default.jpg"
    echo ""
    echo -e "${CYAN}4.${NC} Customize your setup:"
    echo "   Edit: ~/.config/hypr/hyprland.conf"
    echo "   Modus: ~/.config/Modus/"
    echo ""
    echo -e "${YELLOW}Useful Commands:${NC}"
    echo "  modus           - Start Modus shell"
    echo "  modus-lock      - Lock screen"
    echo "  start-hyprland  - Start Hyprland (if no DM)"
    echo ""
    echo -e "${YELLOW}Keybindings (default):${NC}"
    echo "  SUPER + RETURN  - Terminal (kitty)"
    echo "  SUPER + Q       - Close window"
    echo "  SUPER + E       - File manager (thunar)"
    echo "  SUPER + SPACE   - Application launcher"
    echo "  SUPER + L       - Lock screen (Modus)"
    echo "  SUPER + 1-9     - Switch workspace"
    echo "  Print           - Screenshot (selection)"
    echo "  SHIFT + Print   - Screenshot (full screen)"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Support:${NC}"
    echo "  GitHub: https://github.com/S4NKALP/Modus"
    echo "  Discord: https://discord.gg/tRFxkbQ3Zq"
    echo ""
    echo -e "${YELLOW}Enjoy your new Hyprland + Modus setup! 🎉${NC}"
    echo ""
}

# Main installation process
main() {
    print_banner
    
    # Confirmation
    print_warning "This script will install Hyprland, Modus, and all dependencies."
    print_warning "It will modify system configurations and install many packages."
    echo ""
    read -p "Do you want to continue? [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
        print_error "Installation cancelled"
        exit 0
    fi
    
    echo ""
    
    # Run installation steps
    check_system
    update_system
    detect_and_install_gpu_drivers
    install_aur_helper
    install_hyprland
    install_utilities
    install_hyprland_aur_packages
    install_modus_dependencies
    setup_xdg_dirs
    enable_services
    create_basic_hyprland_config
    setup_modus
    setup_python_env
    install_themes
    configure_gtk
    create_launchers
    integrate_modus_with_hyprland
    setup_wallpaper
    setup_display_manager
    final_setup
    
    # Show summary
    print_summary
}

# Run the installation
main
