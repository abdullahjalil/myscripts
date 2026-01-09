#!/bin/bash
#
# Fix Picom Border Glitch
# Eliminates the flickering border when hovering between windows
#

echo "Fixing picom border glitch..."

# Kill existing picom
killall picom 2>/dev/null
sleep 1

# Create updated VM-optimized config without the border glitch
mkdir -p ~/.config/picom
cat > ~/.config/picom/picom.conf << 'EOF'
# Everforest Picom Config - VM Optimized (No Border Glitch)
# This config eliminates the shadow flicker when hovering between windows

# Backend - xrender is more stable for VMs than glx
backend = "xrender";

# VSync - disable for better VM compatibility
vsync = false;

# Shadows - disabled to prevent border glitch
shadow = false;

# If you want shadows, uncomment below and adjust
# shadow = true;
# shadow-radius = 8;
# shadow-offset-x = -8;
# shadow-offset-y = -8;
# shadow-opacity = 0.5;
# 
# # Exclude shadows on certain windows to prevent glitches
# shadow-exclude = [
#     "name = 'Notification'",
#     "class_g = 'Conky'",
#     "class_g ?= 'Notify-osd'",
#     "class_g = 'Cairo-clock'",
#     "_GTK_FRAME_EXTENTS@:c",
#     "class_g = 'i3-frame'",
#     "_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'"
# ];

# Opacity
inactive-opacity = 0.95;
active-opacity = 1.0;
frame-opacity = 1.0;
inactive-opacity-override = false;

opacity-rule = [
    "100:class_g = 'firefox'",
    "100:class_g = 'Firefox'",
    "100:class_g = 'Discord'",
    "100:class_g = 'Steam'",
    "100:class_g = 'Google-chrome'",
    "100:class_g = 'Code'",
];

# Fading - keep it subtle to avoid flicker
fading = true;
fade-delta = 6;
fade-in-step = 0.05;
fade-out-step = 0.05;

# No fade on these to prevent glitches
fade-exclude = [
    "class_g = 'i3-frame'"
];

# Corners - disable for VMs
corner-radius = 0;

# Performance settings for VMs
unredir-if-possible = false;
detect-transient = true;
detect-client-leader = true;
use-damage = true;

# Mark windows that request to be repainted
mark-wmwin-focused = true;
mark-ovredir-focused = true;

# Window type settings
wintypes:
{
    tooltip = { fade = true; shadow = false; opacity = 0.95; focus = true; };
    dock = { shadow = false; clip-shadow-above = true; };
    dnd = { shadow = false; };
    popup_menu = { opacity = 0.95; shadow = false; };
    dropdown_menu = { opacity = 0.95; shadow = false; };
};

# Focus handling - prevent glitches
focus-exclude = [
    "class_g = 'Cairo-clock'",
    "class_g = 'i3-frame'"
];
EOF

echo "✓ Created glitch-free picom config"

# Restart picom
picom --config ~/.config/picom/picom.conf -b &
sleep 2

if pgrep -x "picom" > /dev/null; then
    echo "✓ Picom restarted successfully"
    echo ""
    echo "The border glitch should be fixed now!"
    echo ""
    echo "If you want shadows back (might cause minor glitches):"
    echo "  Edit ~/.config/picom/picom.conf and set: shadow = true"
    echo "  Then restart picom: killall picom && picom -b"
else
    echo "⚠ Picom failed to start"
fi

# Update i3 config to use the correct config path
if [ -f ~/.config/i3/config ]; then
    # Remove old picom lines
    sed -i '/exec.*picom/d' ~/.config/i3/config
    
    # Add new picom line in the autostart section
    if ! grep -q "exec --no-startup-id picom --config" ~/.config/i3/config; then
        sed -i '/# Autostart applications/a exec --no-startup-id picom --config ~/.config/picom/picom.conf -b' ~/.config/i3/config
    fi
    
    echo "✓ Updated i3 config"
fi

echo ""
echo "Changes applied! The border glitch should be gone."
echo "If you still see any issues, you can completely disable picom with:"
echo "  bash ~/disable-picom.sh"
EOF

chmod +x fix-border-glitch.sh
