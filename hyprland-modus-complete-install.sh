#!/usr/bin/env bash

# Complete Hyprland + Modus Installation Script
# Optimized for Parallels VM on Apple Silicon (ARM64)
# For Arch Linux ARM running on M4 Mac Mini

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
    echo "    Hyprland + Modus Installation Script"
    echo "    Optimized for Parallels VM on Apple Silicon (ARM64)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${NC}"
}

# Check if running on Arch Linux ARM in VM
check_system() {
    print_step "Checking system requirements..."
    
    if [ ! -f /etc/arch-release ]; then
        print_error "This script requires Arch Linux"
        exit 1
    fi
    
    # Check architecture
    ARCH=$(uname -m)
    if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
        print_warning "Not running on ARM64 architecture (detected: $ARCH)"
        print_warning "This script is optimized for Apple Silicon Macs"
        read -p "Continue anyway? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "ARM64 architecture detected: $ARCH"
    fi
    
    # Check if running in VM
    if systemd-detect-virt | grep -q "oracle\|kvm\|parallels"; then
        VM_TYPE=$(systemd-detect-virt)
        print_success "VM detected: $VM_TYPE"
    else
        print_warning "Could not detect VM environment"
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

# Install Parallels Tools (if available)
install_parallels_tools() {
    print_step "Checking for Parallels Tools..."
    
    # Check if we're in Parallels
    if systemd-detect-virt | grep -q "parallels"; then
        print_info "Parallels VM detected"
        
        # Install dependencies for Parallels Tools
        sudo pacman -S --needed --noconfirm linux-headers dkms
        
        print_info "To install Parallels Tools:"
        print_info "1. In Parallels Desktop: Actions > Install Parallels Tools"
        print_info "2. Mount the ISO and run the installer"
        print_info "3. Or continue without Parallels Tools (basic functionality will work)"
        
        read -p "Have you installed Parallels Tools? [Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_warning "Continuing without Parallels Tools"
            print_warning "Some features (shared folders, clipboard) may not work"
        fi
    else
        print_info "Not running in Parallels, skipping Parallels Tools"
    fi
}

# Setup VM graphics (no GPU drivers needed)
setup_vm_graphics() {
    print_step "Setting up VM graphics..."
    
    print_info "Installing graphics packages for VM environment..."
    
    local VM_GRAPHICS_PACKAGES=(
        mesa
        mesa-utils
        libva
        libva-mesa-driver
        vulkan-icd-loader
        vulkan-mesa-layers
    )
    
    sudo pacman -S --needed --noconfirm "${VM_GRAPHICS_PACKAGES[@]}"
    
    # Set environment variables for VM
    echo "export WLR_RENDERER=pixman" >> ~/.bashrc
    echo "export WLR_NO_HARDWARE_CURSORS=1" >> ~/.bashrc
    
    print_success "VM graphics configured"
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
        return
    elif command -v yay &> /dev/null; then
        print_success "yay is already installed"
        AUR_HELPER="yay"
        return
    fi
    
    print_warning "AUR helper installation on ARM64 may have limited package availability"
    
    print_info "Installing paru AUR helper..."
    sudo pacman -S --needed --noconfirm base-devel git rust
    
    cd /tmp
    rm -rf paru
    git clone https://aur.archlinux.org/paru.git
    cd paru
    
    # Build paru
    if makepkg -si --noconfirm; then
        cd ~
        AUR_HELPER="paru"
        print_success "paru installed successfully"
    else
        print_error "Failed to install paru"
        print_info "Trying yay instead..."
        cd /tmp
        rm -rf yay
        git clone https://aur.archlinux.org/yay.git
        cd yay
        if makepkg -si --noconfirm; then
            cd ~
            AUR_HELPER="yay"
            print_success "yay installed successfully"
        else
            print_error "Failed to install AUR helper. Some packages may not be available."
            AUR_HELPER=""
        fi
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
        # Core Hyprland (should work on ARM)
        hyprland
        xdg-desktop-portal-hyprland
        
        # Wayland essentials
        wayland
        wayland-protocols
        
        # XDG and session
        xdg-utils
        xdg-user-dirs
        polkit
        polkit-gnome
        
        # Display and graphics (VM compatible)
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
        
        # Development tools
        python
        python-pip
        python-gobject
        python-cairo
    )
    
    print_info "Installing ${#HYPRLAND_DEPS[@]} packages..."
    print_warning "This may take 10-15 minutes on a VM..."
    
    sudo pacman -S --needed --noconfirm "${HYPRLAND_DEPS[@]}"
    
    print_success "Hyprland and dependencies installed"
}

# Install additional utilities and applications
install_utilities() {
    print_step "Installing additional utilities..."
    
    local UTILITIES=(
        # Browsers
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
        
        # Wallpaper setter
        swaybg
        
        # Application launcher
        wofi
    )
    
    print_info "Do you want to install additional utilities?"
    print_info "(firefox, image viewer, PDF reader, etc.)"
    read -p "Install utilities? [Y/n]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        sudo pacman -S --needed --noconfirm "${UTILITIES[@]}" || print_warning "Some utilities may not be available"
        print_success "Utilities installed"
    else
        print_info "Skipping utilities installation"
    fi
}

# Install AUR packages (with ARM compatibility check)
install_aur_packages() {
    print_step "Installing AUR packages..."
    
    if [ -z "$AUR_HELPER" ]; then
        print_warning "No AUR helper available, skipping AUR packages"
        print_warning "Some features may not work (hyprpicker, etc.)"
        return
    fi
    
    # These packages may or may not work on ARM
    local AUR_PACKAGES=(
        hyprpicker
    )
    
    print_warning "Note: Some AUR packages may not be available for ARM64"
    print_info "Attempting to install AUR packages (may fail)..."
    
    for pkg in "${AUR_PACKAGES[@]}"; do
        print_info "Installing $pkg..."
        if ! $AUR_HELPER -S --needed --noconfirm "$pkg" 2>/dev/null; then
            print_warning "Failed to install $pkg (may not be available for ARM64)"
        fi
    done
    
    print_success "AUR packages installation completed (with possible warnings)"
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
    
    print_info "Installing Modus pacman dependencies..."
    sudo pacman -S --needed --noconfirm "${MODUS_DEPS_PACMAN[@]}"
    
    # AUR dependencies - may not work on ARM
    if [ -n "$AUR_HELPER" ]; then
        print_info "Attempting to install Modus AUR dependencies..."
        print_warning "These may not be available for ARM64..."
        
        # Try glace-git
        if ! $AUR_HELPER -S --needed --noconfirm glace-git 2>/dev/null; then
            print_warning "glace-git not available, some features may not work"
        fi
        
        # Try gtk-session-lock
        if ! $AUR_HELPER -S --needed --noconfirm gtk-session-lock 2>/dev/null; then
            print_warning "gtk-session-lock not available, lock screen may not work"
            print_info "Will use alternative lock screen method"
        fi
        
        # Try apple-fonts
        if ! $AUR_HELPER -S --needed --noconfirm apple-fonts 2>/dev/null; then
            print_warning "apple-fonts not available, will use default fonts"
        fi
    fi
    
    print_success "Modus dependencies installation completed"
}

# Setup XDG user directories
setup_xdg_dirs() {
    print_step "Setting up XDG user directories..."
    
    xdg-user-dirs-update
    
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

# Create Hyprland configuration optimized for VM
create_hyprland_config() {
    print_step "Creating Hyprland configuration (VM optimized)..."
    
    mkdir -p ~/.config/hypr
    
    # Backup existing config
    if [ -f ~/.config/hypr/hyprland.conf ]; then
        BACKUP_FILE="~/.config/hypr/hyprland.conf.backup.$(date +%Y%m%d_%H%M%S)"
        cp ~/.config/hypr/hyprland.conf "$BACKUP_FILE"
        print_info "Backed up existing config to: $BACKUP_FILE"
    fi
    
    # Create VM-optimized Hyprland config
    cat > ~/.config/hypr/hyprland.conf << 'EOF'
# Hyprland Configuration
# Optimized for Parallels VM on Apple Silicon

# Monitor configuration
monitor=,preferred,auto,1

# Startup applications
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = swaybg -i ~/Pictures/Wallpapers/default.jpg -m fill
exec-once = dunst

# Environment variables (VM optimized)
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = GDK_BACKEND,wayland,x11
env = QT_QPA_PLATFORM,wayland;xcb
env = QT_QPA_PLATFORMTHEME,qt5ct
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = MOZ_ENABLE_WAYLAND,1
env = SDL_VIDEODRIVER,wayland
env = WLR_RENDERER,pixman
env = WLR_NO_HARDWARE_CURSORS,1

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

# General settings (lighter for VM)
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

# Decorations (reduced for VM performance)
decoration {
    rounding = 8
    blur {
        enabled = false  # Disabled for VM performance
        size = 3
        passes = 1
    }
    drop_shadow = true
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Animations (reduced for VM)
animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 5, myBezier  # Faster for VM
    animation = windowsOut, 1, 5, default, popin 80%
    animation = border, 1, 8, default
    animation = borderangle, 1, 6, default
    animation = fade, 1, 5, default
    animation = workspaces, 1, 4, default  # Faster for VM
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
windowrulev2 = opacity 0.95 0.95,class:^(kitty)$
windowrulev2 = opacity 0.95 0.95,class:^(thunar)$

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

# Application launcher
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

# Volume controls
bindl = , XF86AudioRaiseVolume, exec, pamixer -i 5
bindl = , XF86AudioLowerVolume, exec, pamixer -d 5
bindl = , XF86AudioMute, exec, pamixer -t

# Brightness controls
bindl = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
bindl = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
EOF
    
    print_success "VM-optimized Hyprland configuration created"
}

# Clone and setup Modus
setup_modus() {
    print_step "Setting up Modus shell..."
    
    if [ -d "$HOME/.config/Modus" ]; then
        print_warning "Existing Modus configuration found"
        BACKUP_DIR="$HOME/.config/Modus.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$HOME/.config/Modus" "$BACKUP_DIR"
        print_info "Backed up to: $BACKUP_DIR"
    fi
    
    print_info "Cloning Modus repository..."
    git clone https://github.com/S4NKALP/Modus.git "$HOME/.config/Modus"
    
    cd "$HOME/.config/Modus"
    
    print_success "Modus repository cloned"
}

# Setup Python virtual environment for Modus
setup_python_env() {
    print_step "Setting up Python virtual environment for Modus..."
    
    cd "$HOME/.config/Modus"
    
    print_info "Creating virtual environment..."
    python -m venv .venv
    
    print_info "Activating virtual environment..."
    source .venv/bin/activate
    
    print_info "Upgrading pip..."
    pip install --upgrade pip
    
    print_info "Installing Python dependencies..."
    if [ -f requirements.txt ]; then
        pip install -r requirements.txt
    fi
    
    print_info "Installing Fabric framework..."
    pip install --no-deps git+https://github.com/Fabric-Development/fabric.git
    
    pip install loguru psutil
    
    deactivate
    
    print_success "Python environment configured"
}

# Install themes (optional)
install_themes() {
    print_step "Theme installation..."
    
    print_info "Do you want to install MacTahoe themes?"
    print_warning "Note: Themes may take a while to install on a VM"
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
            
            # Cursors
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
gtk-font-name=Noto Sans 10
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
gtk-font-name=Noto Sans 10
gtk-cursor-theme-name=MacTahoe-cursors
gtk-cursor-theme-size=24
EOF
    
    print_success "GTK settings configured"
}

# Create Modus launcher scripts
create_launchers() {
    print_step "Creating launcher scripts..."
    
    mkdir -p ~/.local/bin
    
    cat > ~/.local/bin/modus << 'EOF'
#!/usr/bin/env bash
cd ~/.config/Modus
source .venv/bin/activate
python main.py "$@"
EOF
    chmod +x ~/.local/bin/modus
    
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
    
    if [ -f ~/.config/hypr/hyprland.conf ]; then
        if ! grep -q "exec-once = modus" ~/.config/hypr/hyprland.conf; then
            cat >> ~/.config/hypr/hyprland.conf << EOF

# ============================================
# Modus Shell Configuration
# ============================================
# Note: Modus config may not exist yet - will be created on first run
# source = ~/.config/Modus/config/hypr/modus.conf

# Autostart Modus
exec-once = modus

# Lock screen binding
bind = SUPER, L, exec, modus-lock

# Cursor theme
env = XCURSOR_THEME,MacTahoe-cursors
env = XCURSOR_SIZE,24
EOF
            print_success "Modus integrated into Hyprland"
        fi
    fi
}

# Setup wallpaper
setup_wallpaper() {
    print_step "Setting up wallpaper..."
    
    mkdir -p ~/Pictures/Wallpapers
    
    print_info "Downloading a default wallpaper..."
    # Download a simple default wallpaper
    if command -v wget &> /dev/null; then
        wget -O ~/Pictures/Wallpapers/default.jpg "https://raw.githubusercontent.com/dharmx/walls/main/mountain.jpg" 2>/dev/null || \
        print_warning "Could not download wallpaper. Add your own to ~/Pictures/Wallpapers/default.jpg"
    else
        print_warning "wget not found. Add your wallpaper to ~/Pictures/Wallpapers/default.jpg"
    fi
    
    print_success "Wallpaper configuration created"
}

# Final setup
final_setup() {
    print_step "Running final setup..."
    
    mkdir -p ~/.config/environment.d
    cat > ~/.config/environment.d/hyprland.conf << EOF
# Hyprland environment variables (VM optimized)
XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_TYPE=wayland
XDG_SESSION_DESKTOP=Hyprland
WLR_RENDERER=pixman
WLR_NO_HARDWARE_CURSORS=1

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
    
    print_info "Updating font cache..."
    fc-cache -fv > /dev/null 2>&1
    
    print_success "Final setup complete"
}

# Print installation summary
print_summary() {
    clear
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}    Installation Complete!${NC}"
    echo -e "${GREEN}    Optimized for Parallels VM on Apple Silicon${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}What was installed:${NC}"
    echo "  ✓ Hyprland (ARM64 compatible)"
    echo "  ✓ Modus shell"
    echo "  ✓ VM-optimized graphics settings"
    echo "  ✓ Essential applications"
    echo "  ✓ Audio, Network, Bluetooth support"
    echo ""
    echo -e "${YELLOW}VM-Specific Optimizations:${NC}"
    echo "  • Blur effects disabled for performance"
    echo "  • Reduced animation speeds"
    echo "  • Pixman renderer for compatibility"
    echo "  • Hardware cursor disabled"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo ""
    echo -e "${CYAN}1.${NC} Logout or reboot:"
    echo "   logout  # or sudo reboot"
    echo ""
    echo -e "${CYAN}2.${NC} Start Hyprland:"
    echo "   Hyprland"
    echo ""
    echo -e "${CYAN}3.${NC} Modus should start automatically"
    echo "   If not, run: modus"
    echo ""
    echo -e "${YELLOW}Important Notes for VM:${NC}"
    echo "  • Performance may be slower than native hardware"
    echo "  • Some visual effects are reduced for better performance"
    echo "  • Shared folders: Install Parallels Tools if not done yet"
    echo "  • Copy/paste: Requires Parallels Tools"
    echo ""
    echo -e "${YELLOW}Useful Commands:${NC}"
    echo "  modus      - Start Modus shell"
    echo "  modus-lock - Lock screen"
    echo "  Hyprland   - Start Hyprland"
    echo ""
    echo -e "${YELLOW}Default Keybindings:${NC}"
    echo "  SUPER + RETURN  - Terminal"
    echo "  SUPER + Q       - Close window"
    echo "  SUPER + E       - File manager"
    echo "  SUPER + SPACE   - App launcher"
    echo "  SUPER + L       - Lock screen"
    echo ""
    echo -e "${CYAN}Parallels Tips:${NC}"
    echo "  • Set VM RAM to at least 4GB (8GB recommended)"
    echo "  • Enable 3D acceleration in VM settings"
    echo "  • Allocate 2+ CPU cores"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Support:${NC}"
    echo "  Modus: https://github.com/S4NKALP/Modus"
    echo "  Hyprland: https://wiki.hyprland.org"
    echo ""
    echo -e "${YELLOW}Enjoy Hyprland on your M4 Mac! 🎉${NC}"
    echo ""
}

# Main installation
main() {
    print_banner
    
    print_warning "This script will install Hyprland + Modus on your Parallels VM"
    print_warning "Optimized for Apple Silicon (ARM64)"
    echo ""
    read -p "Do you want to continue? [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
        print_error "Installation cancelled"
        exit 0
    fi
    
    echo ""
    
    # Run installation
    check_system
    install_parallels_tools
    update_system
    setup_vm_graphics
    install_aur_helper
    install_hyprland
    install_utilities
    install_aur_packages
    install_modus_dependencies
    setup_xdg_dirs
    enable_services
    create_hyprland_config
    setup_modus
    setup_python_env
    install_themes
    configure_gtk
    create_launchers
    integrate_modus_with_hyprland
    setup_wallpaper
    final_setup
    
    print_summary
}

# Run it
main
