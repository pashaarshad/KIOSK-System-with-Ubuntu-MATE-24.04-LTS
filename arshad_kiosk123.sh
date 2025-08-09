#!/bin/bash
set -e

echo "🔧 Updating system & installing necessary packages..."
sudo apt update && sudo apt install -y \
  chromium-browser \
  x11-xserver-utils \
  dbus-x11 \
  lightdm \
  mate-desktop-environment-core

echo "👤 Creating 'kiosk' user..."
if ! id "kiosk" &>/dev/null; then
  sudo adduser --disabled-password --gecos "" kiosk
  echo "kiosk:123" | sudo chpasswd   # 🔹 Set password to 123
else
  echo "✅ User 'kiosk' already exists — resetting password to 123."
  echo "kiosk:123" | sudo chpasswd
fi

echo "🔐 Enabling auto-login for 'kiosk' in LightDM..."
sudo bash -c 'cat > /etc/lightdm/lightdm.conf' <<EOF
[Seat:*]
autologin-user=kiosk
autologin-user-timeout=0
user-session=mate
EOF

echo "📁 Creating kiosk HTML and autostart files..."
sudo -u kiosk mkdir -p /home/kiosk/kiosk-html /home/kiosk/.config/autostart

# Create smart refresh HTML file
cat <<EOF | sudo tee /home/kiosk/kiosk-html/index.html >/dev/null
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Kiosk Smart Refresh</title>
  <style>
    html, body {
      margin: 0;
      padding: 0;
      height: 100%;
      overflow: hidden;
    }
    iframe {
      border: none;
      width: 100%;
      height: 100%;
    }
  </style>
</head>
<body>
  <iframe id="mainFrame" src="https://sdclibary.netlify.app/"></iframe>
  <script>
    const iframe = document.getElementById("mainFrame");
    setInterval(() => {
      try {
        const currentURL = iframe.contentWindow.location.href;
        if (!currentURL.includes("sdclibary.netlify.app")) {
          iframe.contentWindow.location.reload();
        }
      } catch (e) {
        // Ignore cross-origin errors
      }
    }, 4000);
  </script>
</body>
</html>
EOF

# Create autostart desktop entry
cat <<EOF | sudo tee /home/kiosk/.config/autostart/kiosk.desktop >/dev/null
[Desktop Entry]
Type=Application
Name=Kiosk
Exec=bash -c "xset s off -dpms && chromium-browser --kiosk --noerrdialogs --incognito /home/kiosk/kiosk-html/index.html"
X-GNOME-Autostart-enabled=true
EOF

sudo chown -R kiosk:kiosk /home/kiosk/

echo "💤 Disabling power-saving and screensaver for MATE..."
sudo -u kiosk dbus-launch gsettings set org.mate.power-manager sleep-display-ac 0
sudo -u kiosk dbus-launch gsettings set org.mate.power-manager sleep-display-battery 0
sudo -u kiosk dbus-launch gsettings set org.mate.screensaver idle-activation-enabled false
sudo -u kiosk dbus-launch gsettings set org.mate.screensaver lock-enabled false

echo "✅ ✅ Kiosk setup completed successfully for Ubuntu MATE!"
echo "🔁 Rebooting system now..."
sudo reboot
