#!/bin/bash

# Update & install required packages
sudo apt update && sudo apt install -y xorg openbox chromium-browser

# Create autostart directory
mkdir -p ~/.config/openbox

# Create autostart file for kiosk mode with automation
cat > ~/.config/openbox/autostart << 'EOF'
# Launch Chromium in kiosk mode with Website A
chromium-browser --kiosk --disable-infobars --noerrdialogs --disable-session-crashed-bubble --app=https://sdclibary.netlify.app &

# Wait 1.5 seconds then switch to Website B and fill form
sleep 1.5 && xdotool key ctrl+t && \
sleep 0.5 && xdotool type --delay 100 'https://mycampuz.co.in/visitor' && xdotool key Return

# Wait for website B to load, then fill and submit form via JavaScript
sleep 3 && \
xdotool key ctrl+shift+i && sleep 0.5 && \
xdotool type --delay 10 "setTimeout(() => {
  const input = document.querySelector('input[name=\"memid\"]');
  if (input) {
    input.value = '123';
    input.dispatchEvent(new Event('input', { bubbles: true }));
  }
  const button = document.querySelector('button[type=\"submit\"]');
  if (button) {
    button.click();
  }
}, 2000);" && \
xdotool key Return ctrl+shift+i
EOF

# Set Openbox to start at login
echo 'exec openbox-session' > ~/.xinitrc

# Add auto-login and GUI start (for systems using lightdm)
sudo bash -c 'echo "[Seat:*]
autologin-user=$USER
autologin-session=openbox" > /etc/lightdm/lightdm.conf'

# Enable lightdm
sudo systemctl enable lightdm

# Reboot to apply everything
sudo reboot
