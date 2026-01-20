
# Config network manager to handle networks
 https://askubuntu.com/questions/71159/network-manager-says-device-not-managed

# when setting up new systems (and after updates), update Firefox and Chrome desktop launchers to limit memory usage
  # Exec=systemd-run --scope -p MemoryMax=5000M --user firefox %u
  # Exec=systemd-run --scope -p MemoryMax=5000M --user chrome-browser %u
```
sudo sed -i 's/^Exec=.*\(\/usr\/.*\)$/Exec=systemd-run --scope -p MemoryMax=12000M --user \1/g' /usr/share/applications/google-chrome.desktop
sudo sed -i 's/^Exec=.*\(firefox.*\)$/Exec=systemd-run --scope -p MemoryMax=12000M --user \1/g' /usr/share/applications/firefox.desktop

# -p CPUQuota=50% -p CPUWeight=50
```
