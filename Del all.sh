#!/bin/bash

# Set your main user
MAIN_USER="test"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this script as root (sudo)."
  exit 1
fi

echo "Cleaning all users except $MAIN_USER..."

# Delete all other users except the main one and system users
for user in $(cut -d: -f1 /etc/passwd); do
  if id -u "$user" >/dev/null 2>&1; then
    if [ "$user" != "$MAIN_USER" ] && [ "$(id -u "$user")" -ge 1000 ]; then
      echo "Deleting user: $user"
      userdel -r "$user"
    fi
  fi
done

echo "Deleting all home directories except /home/$MAIN_USER..."
find /home -mindepth 1 -maxdepth 1 ! -name "$MAIN_USER" -exec rm -rf {} \;

echo "Cleaning apt packages and caches..."
apt autoremove --purge -y
apt clean
apt autoclean

echo "Removing logs, temp files, and caches..."
rm -rf /var/log/*
rm -rf /tmp/*
rm -rf /var/tmp/*
rm -rf /root/.cache/*
rm -rf /home/"$MAIN_USER"/.cache/*

echo "Removing unused snap packages..."
snap list --all | awk '/disabled/{print $1, $2}' | while read snapname version; do
  snap remove "$snapname" --revision="$version"
done

echo "Deleting user-created files in root directories (careful)..."
find / -path /home/"$MAIN_USER" -prune -o -type f -user "$MAIN_USER" -exec rm -f {} \; 2>/dev/null

echo "System clean complete. Only user $MAIN_USER is kept."
echo "Rebooting in 10 seconds..."
sleep 10
reboot
