#!/bin/bash

# Author: Arshad Pasha
# Purpose: Setup Ubuntu in kiosk mode with auto-login, browser launch, and JavaScript injection.

echo "=== Updating System ==="
sudo apt update && sudo apt upgrade -y

echo "=== Installing Required Packages ==="
sudo apt install -y chromium-browser xdotool unclutter lightdm

echo "=== Creating Kiosk Script ==="
cat << 'EOF' | sudo tee /usr/local/bin/kiosk-start.sh
#!/bin/bash
xset -dpms       # Disable Display Power Management
xset s off       # Disable screen saver
xset s noblank   # Prevent screen blanking
unclutter -idle 0.5 -root &  # Hide mouse cursor when idle

# Start Chromium in kiosk mode with both websites
chromium-browser --kiosk --incognito \
  --new-window 'https://sdclibary.netlify.app' \
  --new-tab 'https://mycampuz.co.in/visitor' &

# Wait for the browser to open, then inject JavaScript into the second tab
sleep 8

# Find the Chromium window with mycampuz and inject JS
WINDOW_ID=$(xdotool search --name 'mycampuz' | head -n 1)
if [ -n "$WINDOW_ID" ]; then
  xdotool windowactivate $WINDOW_ID
  xdotool key ctrl+shift+i  # Open DevTools (not always reliable)
  sleep 1
  xdotool key ctrl+shift+j  # Open console directly (more reliable)
  sleep 2

  # Inject JS using xdotool
  xdotool type --delay 20 "setTimeout(() => { const input = document.querySelector('input[name=\"memid\"]'); if (input) { input.value = '123'; input.dispatchEvent(new Event('input', { bubbles: true })); } const button = document.querySelector('button[type=\"submit\"]'); if (button) { button.click(); } }, 2000);"
  xdotool key Return
fi
EOF

echo "=== Making Kiosk Script Executable ==="
sudo chmod +x /usr/local/bin/kiosk-start.sh

echo "=== Configuring Auto-Login ==="
sudo mkdir -p /etc/lightdm/lightdm.conf.d
cat << EOF | sudo tee /etc/lightdm/lightdm.conf.d/50-myconfig.conf
[Seat:*]
autologin-user=$USER
autologin-user-timeout=0
user-session=ubuntu
greeter-session=lightdm-gtk-greeter
EOF

echo "=== Creating autostart entry ==="
mkdir -p ~/.config/autostart
cat << EOF > ~/.config/autostart/kiosk.desktop
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/kiosk-start.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Kiosk Mode
EOF

echo "=== Setup Complete ==="
echo "Please REBOOT your system to enter kiosk mode automatically."
