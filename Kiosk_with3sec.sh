#!/bin/bash
set -e

echo "🔧 Updating system & installing necessary packages..."
sudo apt update && sudo apt install -y \
  x11-xserver-utils \
  dbus-x11 \
  lightdm \
  mate-desktop-environment-core \
  wget

echo "🌐 Installing Google Chrome..."
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

echo "👤 Creating 'kiosk' user..."
if ! id "kiosk" &>/dev/null; then
  sudo adduser --disabled-password --gecos "" kiosk
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

# ✅ SMART HTML with redirect + auto-refresh
cat <<EOF | sudo tee /home/kiosk/kiosk-html/index.html >/dev/null
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Kiosk Redirect + Refresh</title>
  <script>
    const websiteA = "https://sdclibary.netlify.app";
    const websiteB = "https://mycampuz.co.in/visitor/#/visitor";

    function redirectToB() {
      document.body.innerHTML = "<iframe id='siteFrame' src='" + websiteB + "' width='100%' height='100%' frameborder='0'></iframe>";
      const iframe = document.getElementById("siteFrame");

      // Refresh website B every 3 seconds
      setInterval(() => {
        iframe.src = websiteB;
      }, 3000);
    }

    // Load website A for 5 seconds, then go to website B
    window.onload = () => {
      document.body.innerHTML = "<iframe src='" + websiteA + "' width='100%' height='100%' frameborder='0'></iframe>";
      setTimeout(redirectToB, 5000);
    };
  </script>
  <style>
    html, body {
      margin: 0;
      padding: 0;
      height: 100%;
      overflow: hidden;
    }
  </style>
</head>
<body></body>
</html>
EOF

# 🔁 Autostart Google Chrome in kiosk mode
cat <<EOF | sudo tee /home/kiosk/.config/autostart/kiosk.desktop >/dev/null
[Desktop Entry]
Type=Application
Name=Kiosk
Exec=bash -c "xset s off -dpms && google-chrome --kiosk --noerrdialogs --incognito /home/kiosk/kiosk-html/index.html"
X-GNOME-Autostart-enabled=true
EOF

sudo chown -R kiosk:kiosk /home/kiosk/

echo "💤 Disabling screen sleep & screensaver..."
sudo -u kiosk dbus-launch gsettings set org.mate.power-manager sleep-display-ac 0
sudo -u kiosk dbus-launch gsettings set org.mate.power-manager sleep-display-battery 0
sudo -u kiosk dbus-launch gsettings set org.mate.screensaver idle-activation-enabled false
sudo -u kiosk dbus-launch gsettings set org.mate.screensaver lock-enabled false

echo "✅ Kiosk Setup Complete!"
echo "🔁 Rebooting system now..."
sudo reboot
