#!/bin/bash
#
# Everforest i3wm Setup Script for Arch Linux
# Optimized for AMD RX 7800 XT and AMD CPU
# Development & Gaming Desktop
#
# Run this script as root on a fresh Arch Linux TTY install
# Usage: sudo bash everforest-i3-setup.sh

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Everforest color palette (from your image)
declare -A COLORS=(
    [bg_dim]="#293136"
    [bg0]="#333C43"
    [bg1]="#3A464C"
    [bg2]="#434F55"
    [bg3]="#4D5960"
    [bg4]="#555F66"
    [bg5]="#5D6B66"
    [bg_red]="#5C3F4F"
    [bg_visual]="#59464C"
    [bg_yellow]="#55544A"
    [bg_green]="#48584E"
    [bg_blue]="#3F5865"
    [red]="#E67E80"
    [orange]="#E69875"
    [yellow]="#DBBC7F"
    [green]="#A7C080"
    [blue]="#7FBBB3"
    [aqua]="#83C092"
    [purple]="#D699B6"
    [fg]="#D3C6AA"
    [statusline1]="#A7C080"
    [statusline2]="#D3C6AA"
    [statusline3]="#E67E80"
    [gray0]="#7A8478"
    [gray1]="#859289"
    [gray2]="#9DA9A0"
)

print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# Get the actual user (not root)
ACTUAL_USER="${SUDO_USER:-$USER}"
if [ "$ACTUAL_USER" = "root" ]; then
    print_error "Please run with sudo, not as root directly"
    exit 1
fi

USER_HOME="/home/$ACTUAL_USER"

print_status "Starting Everforest i3wm setup for user: $ACTUAL_USER"

# Update system
print_status "Updating system..."
pacman -Syu --noconfirm

# Install base packages
print_status "Installing base packages..."
pacman -S --noconfirm \
    base-devel git wget curl unzip \
    xorg-server xorg-xinit xorg-xrandr xorg-xsetroot \
    i3-wm i3status i3blocks i3lock dmenu \
    lightdm lightdm-gtk-greeter \
    alacritty kitty \
    picom \
    feh \
    rofi \
    dunst libnotify \
    network-manager-applet \
    pulseaudio pavucontrol \
    thunar thunar-volman gvfs \
    firefox \
    ttf-jetbrains-mono ttf-font-awesome ttf-dejavu \
    noto-fonts noto-fonts-emoji \
    lxappearance \
    polkit-gnome \
    htop \
    fastfetch \
    networkmanager nm-connection-editor

# Install AMD GPU drivers
print_status "Installing AMD GPU drivers (RX 7800 XT)..."
pacman -S --noconfirm \
    mesa lib32-mesa \
    vulkan-radeon lib32-vulkan-radeon \
    libva-mesa-driver lib32-libva-mesa-driver \
    mesa-vdpau lib32-mesa-vdpau \
    xf86-video-amdgpu \
    vulkan-icd-loader lib32-vulkan-icd-loader \
    amd-ucode

# Install development tools
print_status "Installing development tools..."
pacman -S --noconfirm \
    neovim \
    tmux \
    zsh zsh-completions \
    python python-pip python-virtualenv \
    nodejs npm \
    docker docker-compose \
    git git-lfs \
    base-devel cmake \
    code \
    postgresql \
    ripgrep fd bat eza \
    lazygit

# Install gaming packages
print_status "Installing gaming packages..."
pacman -S --noconfirm \
    steam \
    lutris \
    wine-staging winetricks \
    lib32-gnutls lib32-libldap lib32-libgpg-error lib32-sqlite lib32-libpulse \
    gamemode lib32-gamemode \
    mangohud lib32-mangohud \
    discord

# Enable services
print_status "Enabling services..."
systemctl enable lightdm.service
systemctl enable NetworkManager.service
systemctl enable docker.service

# Add user to necessary groups
print_status "Adding user to groups..."
usermod -aG wheel,docker,video,audio,input,storage "$ACTUAL_USER"

# Create necessary directories
print_status "Creating directories..."
sudo -u "$ACTUAL_USER" mkdir -p "$USER_HOME"/.config/{i3,i3status,alacritty,rofi,dunst,picom,kitty}
sudo -u "$ACTUAL_USER" mkdir -p "$USER_HOME"/.local/share/backgrounds
sudo -u "$ACTUAL_USER" mkdir -p "$USER_HOME"/.fonts

# Install Polybar (better than i3status)
print_status "Installing Polybar..."
pacman -S --noconfirm polybar

# Create i3 config
print_status "Creating i3 config..."
cat > "$USER_HOME/.config/i3/config" << 'EOF'
# Everforest i3 config

# Set mod key (Mod4 = Super/Windows key)
set $mod Mod4

# Everforest color scheme
set $bg_dim     #293136
set $bg0        #333C43
set $bg1        #3A464C
set $bg2        #434F55
set $bg3        #4D5960
set $bg4        #555F66
set $bg5        #5D6B66
set $red        #E67E80
set $orange     #E69875
set $yellow     #DBBC7F
set $green      #A7C080
set $blue       #7FBBB3
set $aqua       #83C092
set $purple     #D699B6
set $fg         #D3C6AA
set $gray0      #7A8478
set $gray1      #859289
set $gray2      #9DA9A0

# Font
font pango:JetBrains Mono 10

# Use Mouse+$mod to drag floating windows
floating_modifier $mod

# Start a terminal
bindsym $mod+Return exec alacritty

# Kill focused window
bindsym $mod+Shift+q kill

# Start rofi (program launcher)
bindsym $mod+d exec --no-startup-id rofi -show drun
bindsym $mod+Shift+d exec --no-startup-id rofi -show run

# Change focus
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

# Alternatively, use cursor keys
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# Move focused window
bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

# Alternatively, use cursor keys
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# Split orientation
bindsym $mod+b split h
bindsym $mod+v split v

# Fullscreen
bindsym $mod+f fullscreen toggle

# Change container layout
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# Toggle tiling / floating
bindsym $mod+Shift+space floating toggle

# Change focus between tiling / floating windows
bindsym $mod+space focus mode_toggle

# Focus parent container
bindsym $mod+a focus parent

# Define workspaces
set $ws1 "1"
set $ws2 "2"
set $ws3 "3"
set $ws4 "4"
set $ws5 "5"
set $ws6 "6"
set $ws7 "7"
set $ws8 "8"
set $ws9 "9"
set $ws10 "10"

# Switch to workspace
bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3
bindsym $mod+4 workspace number $ws4
bindsym $mod+5 workspace number $ws5
bindsym $mod+6 workspace number $ws6
bindsym $mod+7 workspace number $ws7
bindsym $mod+8 workspace number $ws8
bindsym $mod+9 workspace number $ws9
bindsym $mod+0 workspace number $ws10

# Move focused container to workspace
bindsym $mod+Shift+1 move container to workspace number $ws1
bindsym $mod+Shift+2 move container to workspace number $ws2
bindsym $mod+Shift+3 move container to workspace number $ws3
bindsym $mod+Shift+4 move container to workspace number $ws4
bindsym $mod+Shift+5 move container to workspace number $ws5
bindsym $mod+Shift+6 move container to workspace number $ws6
bindsym $mod+Shift+7 move container to workspace number $ws7
bindsym $mod+Shift+8 move container to workspace number $ws8
bindsym $mod+Shift+9 move container to workspace number $ws9
bindsym $mod+Shift+0 move container to workspace number $ws10

# Reload configuration
bindsym $mod+Shift+c reload

# Restart i3
bindsym $mod+Shift+r restart

# Exit i3
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'Exit i3?' -B 'Yes' 'i3-msg exit'"

# Resize mode
mode "resize" {
    bindsym h resize shrink width 10 px or 10 ppt
    bindsym j resize grow height 10 px or 10 ppt
    bindsym k resize shrink height 10 px or 10 ppt
    bindsym l resize grow width 10 px or 10 ppt

    bindsym Left resize shrink width 10 px or 10 ppt
    bindsym Down resize grow height 10 px or 10 ppt
    bindsym Up resize shrink height 10 px or 10 ppt
    bindsym Right resize grow width 10 px or 10 ppt

    bindsym Return mode "default"
    bindsym Escape mode "default"
    bindsym $mod+r mode "default"
}
bindsym $mod+r mode "resize"

# Window colors
#                       border    background text      indicator   child_border
client.focused          $green    $bg2       $fg       $aqua       $green
client.focused_inactive $bg3      $bg1       $gray1    $bg3        $bg3
client.unfocused        $bg1      $bg0       $gray0    $bg1        $bg1
client.urgent           $red      $red       $bg0      $red        $red
client.placeholder      $bg0      $bg0       $gray0    $bg0        $bg0
client.background       $bg0

# Gaps
gaps inner 8
gaps outer 4

# Border
default_border pixel 2
default_floating_border pixel 2

# Autostart applications
exec_always --no-startup-id ~/.config/polybar/launch.sh
exec --no-startup-id picom -b
exec --no-startup-id dunst
exec --no-startup-id nitrogen --restore || feh --bg-scale ~/.local/share/backgrounds/everforest1.jpg
exec --no-startup-id nm-applet
exec --no-startup-id /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

# Screenshots
bindsym Print exec --no-startup-id maim -s | xclip -selection clipboard -t image/png
bindsym $mod+Print exec --no-startup-id maim | xclip -selection clipboard -t image/png

# Lock screen
bindsym $mod+x exec --no-startup-id i3lock -c 333C43

# Volume controls
bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle

# Brightness controls (if laptop)
bindsym XF86MonBrightnessUp exec --no-startup-id xbacklight -inc 10
bindsym XF86MonBrightnessDown exec --no-startup-id xbacklight -dec 10

# Application shortcuts
bindsym $mod+Shift+f exec firefox
bindsym $mod+Shift+t exec thunar

# Floating windows
for_window [class="Pavucontrol"] floating enable
for_window [class="Lxappearance"] floating enable
for_window [class="Nitrogen"] floating enable
EOF

chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config/i3/config"

# Create Polybar config
print_status "Creating Polybar config..."
cat > "$USER_HOME/.config/polybar/config.ini" << 'EOF'
;==========================================================
;
;   Everforest Polybar Config
;
;==========================================================

[colors]
bg_dim = #293136
bg0 = #333C43
bg1 = #3A464C
bg2 = #434F55
bg3 = #4D5960
bg4 = #555F66
bg5 = #5D6B66
red = #E67E80
orange = #E69875
yellow = #DBBC7F
green = #A7C080
blue = #7FBBB3
aqua = #83C092
purple = #D699B6
fg = #D3C6AA
gray0 = #7A8478
gray1 = #859289
gray2 = #9DA9A0

background = ${colors.bg0}
foreground = ${colors.fg}
primary = ${colors.green}
secondary = ${colors.blue}
alert = ${colors.red}

[bar/main]
width = 100%
height = 24
radius = 0
fixed-center = true

background = ${colors.background}
foreground = ${colors.foreground}

line-size = 2
border-size = 0
padding-left = 1
padding-right = 1
module-margin-left = 1
module-margin-right = 1

font-0 = JetBrains Mono:size=10;2
font-1 = Font Awesome 6 Free:style=Solid:size=10;2
font-2 = Font Awesome 6 Free:style=Regular:size=10;2
font-3 = Font Awesome 6 Brands:size=10;2

modules-left = i3
modules-center = date
modules-right = pulseaudio memory cpu temperature network

tray-position = right
tray-padding = 2

cursor-click = pointer
cursor-scroll = ns-resize

[module/i3]
type = internal/i3
format = <label-state> <label-mode>
index-sort = true
wrapping-scroll = false

label-mode-padding = 2
label-mode-foreground = ${colors.bg0}
label-mode-background = ${colors.yellow}

label-focused = %index%
label-focused-background = ${colors.bg2}
label-focused-foreground = ${colors.green}
label-focused-underline = ${colors.green}
label-focused-padding = 2

label-unfocused = %index%
label-unfocused-padding = 2
label-unfocused-foreground = ${colors.gray1}

label-visible = %index%
label-visible-background = ${colors.bg1}
label-visible-padding = 2

label-urgent = %index%
label-urgent-background = ${colors.red}
label-urgent-foreground = ${colors.bg0}
label-urgent-padding = 2

[module/cpu]
type = internal/cpu
interval = 2
format-prefix = " "
format-prefix-foreground = ${colors.aqua}
label = %percentage:2%%

[module/memory]
type = internal/memory
interval = 2
format-prefix = " "
format-prefix-foreground = ${colors.purple}
label = %percentage_used%%

[module/network]
type = internal/network
interface-type = wired
interval = 3.0

format-connected = <label-connected>
format-connected-prefix = "󰈀 "
format-connected-prefix-foreground = ${colors.blue}
label-connected = %downspeed:9%

format-disconnected = <label-disconnected>
label-disconnected = 󰈂
label-disconnected-foreground = ${colors.gray0}

[module/date]
type = internal/date
interval = 1

date = %Y-%m-%d
time = %H:%M:%S

format-prefix = " "
format-prefix-foreground = ${colors.yellow}
label = %date% %time%

[module/pulseaudio]
type = internal/pulseaudio

format-volume = <ramp-volume> <label-volume>
label-volume = %percentage%%
label-volume-foreground = ${colors.foreground}

label-muted =  muted
label-muted-foreground = ${colors.gray0}

ramp-volume-0 = 
ramp-volume-1 = 
ramp-volume-2 = 
ramp-volume-foreground = ${colors.orange}

[module/temperature]
type = internal/temperature
thermal-zone = 0
warn-temperature = 80

format = <ramp> <label>
format-warn = <ramp> <label-warn>

label = %temperature-c%
label-warn = %temperature-c%
label-warn-foreground = ${colors.red}

ramp-0 = 
ramp-1 = 
ramp-2 = 
ramp-foreground = ${colors.green}

[settings]
screenchange-reload = true

[global/wm]
margin-top = 0
margin-bottom = 0
EOF

chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config/polybar/config.ini"

# Create Polybar launch script
cat > "$USER_HOME/.config/polybar/launch.sh" << 'EOF'
#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch Polybar
polybar main 2>&1 | tee -a /tmp/polybar.log & disown

echo "Polybar launched..."
EOF

chmod +x "$USER_HOME/.config/polybar/launch.sh"
chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config/polybar/launch.sh"

# Create Alacritty config
print_status "Creating Alacritty config..."
cat > "$USER_HOME/.config/alacritty/alacritty.toml" << 'EOF'
[window]
padding = { x = 10, y = 10 }
opacity = 0.95

[font]
normal = { family = "JetBrains Mono", style = "Regular" }
bold = { family = "JetBrains Mono", style = "Bold" }
italic = { family = "JetBrains Mono", style = "Italic" }
size = 11.0

[colors.primary]
background = "#333C43"
foreground = "#D3C6AA"

[colors.normal]
black = "#4B565C"
red = "#E67E80"
green = "#A7C080"
yellow = "#DBBC7F"
blue = "#7FBBB3"
magenta = "#D699B6"
cyan = "#83C092"
white = "#D3C6AA"

[colors.bright]
black = "#5D6B66"
red = "#E67E80"
green = "#A7C080"
yellow = "#DBBC7F"
blue = "#7FBBB3"
magenta = "#D699B6"
cyan = "#83C092"
white = "#D3C6AA"
EOF

chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config/alacritty/alacritty.toml"

# Create Rofi config
print_status "Creating Rofi config..."
cat > "$USER_HOME/.config/rofi/config.rasi" << 'EOF'
configuration {
    modi: "drun,run,window";
    font: "JetBrains Mono 11";
    show-icons: true;
    display-drun: "";
    display-run: "";
    display-window: "";
    drun-display-format: "{name}";
}

* {
    bg0: #333C43;
    bg1: #3A464C;
    bg2: #434F55;
    fg: #D3C6AA;
    green: #A7C080;
    red: #E67E80;
    
    background-color: @bg0;
    text-color: @fg;
}

window {
    width: 600px;
    border: 2px;
    border-color: @green;
    padding: 20px;
}

mainbox {
    children: [inputbar, listview];
}

inputbar {
    children: [prompt, entry];
    padding: 10px;
    background-color: @bg1;
    margin: 0 0 10px 0;
}

prompt {
    text-color: @green;
    padding: 0 10px 0 0;
}

entry {
    placeholder: "Search...";
    placeholder-color: #7A8478;
}

listview {
    lines: 8;
    scrollbar: false;
}

element {
    padding: 8px;
    spacing: 8px;
}

element selected {
    background-color: @bg2;
    text-color: @green;
}

element-icon {
    size: 24px;
}
EOF

chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config/rofi/config.rasi"

# Create Picom config
print_status "Creating Picom config..."
cat > "$USER_HOME/.config/picom/picom.conf" << 'EOF'
# Everforest Picom Config

# Backend
backend = "glx";
glx-no-stencil = true;
glx-copy-from-front = false;

# Shadows
shadow = true;
shadow-radius = 12;
shadow-offset-x = -12;
shadow-offset-y = -12;
shadow-opacity = 0.6;

# Opacity
inactive-opacity = 0.95;
active-opacity = 1.0;
frame-opacity = 1.0;
inactive-opacity-override = false;

opacity-rule = [
    "100:class_g = 'firefox'",
    "100:class_g = 'Discord'",
    "100:class_g = 'Steam'",
];

# Fading
fading = true;
fade-delta = 4;
fade-in-step = 0.03;
fade-out-step = 0.03;

# Corners
corner-radius = 8;
rounded-corners-exclude = [
    "window_type = 'dock'",
    "window_type = 'desktop'",
];

# Window type settings
wintypes:
{
    tooltip = { fade = true; shadow = true; opacity = 0.95; focus = true; full-shadow = false; };
    dock = { shadow = false; };
    dnd = { shadow = false; };
};
EOF

chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config/picom/picom.conf"

# Create Dunst config
print_status "Creating Dunst config..."
cat > "$USER_HOME/.config/dunst/dunstrc" << 'EOF'
[global]
    font = JetBrains Mono 10
    format = "<b>%s</b>\n%b"
    sort = yes
    indicate_hidden = yes
    alignment = left
    bounce_freq = 0
    show_age_threshold = 60
    word_wrap = yes
    ignore_newline = no
    geometry = "300x5-30+50"
    transparency = 10
    idle_threshold = 120
    monitor = 0
    follow = mouse
    sticky_history = yes
    line_height = 0
    separator_height = 2
    padding = 10
    horizontal_padding = 10
    separator_color = frame
    startup_notification = false
    frame_width = 2
    corner_radius = 8

[urgency_low]
    background = "#333C43"
    foreground = "#D3C6AA"
    frame_color = "#A7C080"
    timeout = 5

[urgency_normal]
    background = "#333C43"
    foreground = "#D3C6AA"
    frame_color = "#7FBBB3"
    timeout = 10

[urgency_critical]
    background = "#333C43"
    foreground = "#D3C6AA"
    frame_color = "#E67E80"
    timeout = 0
EOF

chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config/dunst/dunstrc"

# Configure LightDM GTK Greeter
print_status "Configuring LightDM..."
cat > /etc/lightdm/lightdm-gtk-greeter.conf << 'EOF'
[greeter]
theme-name = Everforest-Dark
icon-theme-name = Papirus-Dark
background = /usr/share/backgrounds/everforest-background.jpg
font-name = JetBrains Mono 11
position = 50%,center 50%,center
EOF

# Download Everforest wallpaper
print_status "Downloading wallpapers..."
cd "$USER_HOME/.local/share/backgrounds"
sudo -u "$ACTUAL_USER" wget -q https://raw.githubusercontent.com/sainnhe/everforest-wallpapers/master/wallpapers/everforest_forest.jpg -O everforest1.jpg || true
sudo -u "$ACTUAL_USER" wget -q https://raw.githubusercontent.com/sainnhe/everforest-wallpapers/master/wallpapers/everforest_lake.jpg -O everforest2.jpg || true

# Set a default wallpaper
if [ -f "$USER_HOME/.local/share/backgrounds/everforest1.jpg" ]; then
    cp "$USER_HOME/.local/share/backgrounds/everforest1.jpg" /usr/share/backgrounds/everforest-background.jpg
    # Set wallpaper with feh for immediate use
    sudo -u "$ACTUAL_USER" DISPLAY=:0 feh --bg-scale "$USER_HOME/.local/share/backgrounds/everforest1.jpg" 2>/dev/null || true
    
    # Create nitrogen config for when it's installed
    mkdir -p "$USER_HOME/.config/nitrogen"
    cat > "$USER_HOME/.config/nitrogen/bg-saved.cfg" << NITROGEN_EOF
[xin_-1]
file=$USER_HOME/.local/share/backgrounds/everforest1.jpg
mode=5
bgcolor=#333C43
NITROGEN_EOF
    chown -R "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config/nitrogen"
fi

# Create .xinitrc for manual startx
print_status "Creating .xinitrc..."
cat > "$USER_HOME/.xinitrc" << 'EOF'
#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps
if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

exec i3
EOF

chmod +x "$USER_HOME/.xinitrc"
chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.xinitrc"

# Install GTK theme
print_status "Installing GTK Everforest theme..."
cd /tmp
sudo -u "$ACTUAL_USER" git clone --depth=1 https://github.com/Fausto-Korpsvart/Everforest-GTK-Theme.git || true
if [ -d "Everforest-GTK-Theme" ]; then
    cd Everforest-GTK-Theme/themes
    mkdir -p /usr/share/themes
    cp -r Everforest-Dark-BL /usr/share/themes/ || true
    ln -sf /usr/share/themes/Everforest-Dark-BL /usr/share/themes/Everforest-Dark || true
fi

# Install icon theme
print_status "Installing Papirus icon theme..."
pacman -S --noconfirm papirus-icon-theme

# Install screenshot tool
print_status "Installing screenshot tools..."
pacman -S --noconfirm maim xclip

# Install yay (AUR helper)
print_status "Installing yay..."
cd /tmp
sudo -u "$ACTUAL_USER" git clone https://aur.archlinux.org/yay.git || true
cd yay
sudo -u "$ACTUAL_USER" makepkg -si --noconfirm || true

# Install additional AUR packages
# Note: nitrogen, gtk-engine-murrine are in AUR, not official repos
print_status "Installing AUR packages..."
sudo -u "$ACTUAL_USER" yay -S --noconfirm \
    nitrogen \
    gtk-engine-murrine \
    neofetch \
    spotify \
    visual-studio-code-bin \
    google-chrome \
    slack-desktop || true

# Configure GTK settings
print_status "Configuring GTK..."
mkdir -p "$USER_HOME/.config/gtk-3.0"
cat > "$USER_HOME/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Everforest-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrains Mono 10
gtk-cursor-theme-name=Adwaita
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
EOF

chown -R "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config/gtk-3.0"

# Install Oh My Zsh
print_status "Installing Oh My Zsh..."
sudo -u "$ACTUAL_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true

# Configure Zsh
cat > "$USER_HOME/.zshrc" << 'EOF'
# Path to oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="agnoster"

# Plugins
plugins=(git docker docker-compose npm node python)

source $ZSH/oh-my-zsh.sh

# Aliases
alias vim='nvim'
alias ll='eza -la --icons'
alias cat='bat'
alias grep='rg'
alias find='fd'

# Start X at login
if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
  exec startx
fi
EOF

chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.zshrc"

# Set Zsh as default shell
print_status "Setting Zsh as default shell..."
chsh -s /bin/zsh "$ACTUAL_USER"

# Create a README with keybindings
print_status "Creating keybindings reference..."
cat > "$USER_HOME/KEYBINDINGS.md" << 'EOF'
# Everforest i3wm Keybindings

## Basic
- `Super + Enter` - Open terminal (Alacritty)
- `Super + Shift + Q` - Close window
- `Super + D` - Application launcher (Rofi)
- `Super + Shift + E` - Exit i3

## Window Management
- `Super + H/J/K/L` - Move focus (Vim keys)
- `Super + Shift + H/J/K/L` - Move window
- `Super + B` - Horizontal split
- `Super + V` - Vertical split
- `Super + F` - Fullscreen toggle
- `Super + Shift + Space` - Toggle floating
- `Super + R` - Resize mode

## Workspaces
- `Super + 1-9` - Switch workspace
- `Super + Shift + 1-9` - Move window to workspace

## Applications
- `Super + Shift + F` - Firefox
- `Super + Shift + T` - File manager (Thunar)

## System
- `Super + X` - Lock screen
- `Print` - Screenshot (selection)
- `Super + Print` - Screenshot (full screen)

## Audio
- `XF86AudioRaiseVolume` - Volume up
- `XF86AudioLowerVolume` - Volume down
- `XF86AudioMute` - Mute toggle

## Gaming
- Launch Steam from Rofi
- Use Lutris for non-Steam games
- GameMode is enabled for better performance
EOF

chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/KEYBINDINGS.md"

# Final touches
print_status "Applying final configurations..."

# Set proper permissions
chown -R "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config"

# Create desktop entry for i3
mkdir -p /usr/share/xsessions
cat > /usr/share/xsessions/i3.desktop << 'EOF'
[Desktop Entry]
Name=i3
Comment=improved dynamic tiling window manager
Exec=i3
Type=Application
EOF

print_status "============================================"
print_status "Installation complete!"
print_status "============================================"
echo ""
print_status "Next steps:"
echo "1. Reboot your system: reboot"
echo "2. Select i3 session at login"
echo "3. Read ~/KEYBINDINGS.md for keyboard shortcuts"
echo ""
print_status "Notes:"
echo "- AMD drivers are configured for RX 7800 XT"
echo "- Everforest theme applied system-wide"
echo "- Development tools: VS Code, Node.js, Python, Docker"
echo "- Gaming: Steam, Lutris, GameMode, MangoHud"
echo "- Use 'Super + D' to launch applications"
echo "- Wallpaper set with feh (nitrogen available after AUR install)"
echo ""
print_warning "Rebooting is recommended!"
