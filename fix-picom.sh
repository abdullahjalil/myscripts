#!/bin/bash
#
# Picom Fix Script for VM Rendering Issues
# Run this to fix the screen not updating problem
#

echo "Fixing picom compositor issues..."

# Kill existing picom
killall picom 2>/dev/null

# Backup old config
if [ -f ~/.config/picom/picom.conf ]; then
    cp ~/.config/picom/picom.conf ~/.config/picom/picom.conf.backup
    echo "✓ Backed up old config to ~/.config/picom/picom.conf.backup"
fi

# Create VM-optimized config
mkdir -p ~/.config/picom
cat > ~/.config/picom/picom.conf << 'EOF'
# Everforest Picom Config - VM Optimized
# This config uses xrender backend which is more compatible with VMs

# Backend - xrender is more stable for VMs than glx
backend = "xrender";

# VSync - disable for better VM compatibility
vsync = false;

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
    "100:class_g = 'Firefox'",
    "100:class_g = 'Discord'",
    "100:class_g = 'Steam'",
    "100:class_g = 'Google-chrome'",
    "100:class_g = 'Code'",
];

# Fading
fading = true;
fade-delta = 4;
fade-in-step = 0.03;
fade-out-step = 0.03;

# Corners - disable for VMs to avoid rendering issues
corner-radius = 0;

# Performance settings for VMs
# Disable features that can cause rendering issues
unredir-if-possible = false;
detect-transient = true;
detect-client-leader = true;
use-damage = true;
refresh-rate = 0;

# Window type settings
wintypes:
{
    tooltip = { fade = true; shadow = true; opacity = 0.95; focus = true; full-shadow = false; };
    dock = { shadow = false; clip-shadow-above = true; };
    dnd = { shadow = false; };
    popup_menu = { opacity = 0.95; };
    dropdown_menu = { opacity = 0.95; };
};

# Exclude certain windows from effects to improve stability
focus-exclude = [
    "class_g = 'Cairo-clock'",
];

blur-background-exclude = [
    "window_type = 'dock'",
    "window_type = 'desktop'",
    "_GTK_FRAME_EXTENTS@:c",
];
EOF

echo "✓ Created VM-optimized picom config"

# Restart picom
picom -b &
sleep 1

if pgrep -x "picom" > /dev/null; then
    echo "✓ Picom restarted successfully"
    echo ""
    echo "Try opening a terminal now (Super + Enter)"
    echo "If the problem persists, run: bash ~/disable-picom.sh"
else
    echo "⚠ Picom failed to start"
    echo "Run without compositor: bash ~/disable-picom.sh"
fi

# Also update i3 config to use the new picom settings
if [ -f ~/.config/i3/config ]; then
    sed -i 's/exec --no-startup-id picom -b/exec --no-startup-id picom --config ~\/.config\/picom\/picom.conf -b/' ~/.config/i3/config
    echo "✓ Updated i3 config"
fi

echo ""
echo "To apply changes immediately, restart i3: Super + Shift + R"
EOF

chmod +x fix-picom.sh
echo "Created fix-picom.sh"

# Create a script to disable picom if needed
cat > disable-picom.sh << 'EOF'
#!/bin/bash
#
# Disable Picom Compositor
# Use this if the rendering issues persist
#

echo "Disabling picom compositor..."

# Kill picom
killall picom 2>/dev/null

# Remove picom from i3 autostart
if [ -f ~/.config/i3/config ]; then
    sed -i 's/exec --no-startup-id picom.*$/# exec --no-startup-id picom (disabled for VM compatibility)/' ~/.config/i3/config
    echo "✓ Removed picom from i3 autostart"
fi

echo "✓ Picom disabled"
echo ""
echo "Restart i3 to apply: Super + Shift + R"
echo ""
echo "Note: You'll lose transparency effects, but everything will work normally."
echo "To re-enable picom later, run: bash ~/fix-picom.sh"
EOF

chmod +x disable-picom.sh
echo "Created disable-picom.sh"
