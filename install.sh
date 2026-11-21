#!/bin/bash
set -e

TMP_DIR=""

verify_os() {
    MSG="Unsupported OS: Raspberry Pi OS 13 (trixie) is required."

    if [ ! -f /etc/os-release ]; then
        echo $MSG
        exit 1
    fi

    . /etc/os-release

    if [[ ("$ID" != "debian" && "$ID" != "raspbian") || "$VERSION_ID" != "13" ]]; then
        echo $MSG
        exit 1
    fi
}

install_pkgs(){
    apt-get update
    apt-get install -y bluez pipewire-alsa bluez-tools bluez-alsa-utils
}

install_hifiberry() {
    FILE="/boot/firmware/config.txt"

    # Ensure file exists
    [ -f "$FILE" ] || touch "$FILE"

    # Ensure [all] section exists
    if ! grep -q "^\[all\]" "$FILE"; then
        echo -e "\n[all]" >> "$FILE"
    fi

    # Remove existing entries (anywhere in file)
    sed -i '/^dtoverlay=hifiberry-dacplus$/d' "$FILE"
    sed -i '/^dtparam=audio=off$/d' "$FILE"
    sed -i '/^dtparam=i2s=on$/d' "$FILE"

    # Insert lines directly after [all]
    sed -i '/^\[all\]/a dtoverlay=hifiberry-dacplus\ndtparam=audio=off\ndtparam=i2s=on' "$FILE"

}

install_bluetooth() {
    # Bluetooth Audio ALSA Backend (bluez-alsa-utils)
    sudo apt update
    sudo apt install -y --no-install-recommends bluez bluez-tools bluez-alsa-utils pipewire-bin 

    # Bluetooth settings
    sudo tee /etc/bluetooth/main.conf >/dev/null <<'EOF'
[General]
Class = 0x20041C
DiscoverableTimeout = 0
JustWorksRepairing=always

[Policy]
AutoEnable=true
EOF

    # Bluetooth Agent
    sudo tee /etc/systemd/system/bt-agent@.service >/dev/null <<'EOF'
[Unit]
Description=Bluetooth Agent
Requires=bluetooth.service
After=bluetooth.service

[Service]
ExecStartPre=/usr/bin/bluetoothctl discoverable on
ExecStartPre=/bin/hciconfig %I up
ExecStartPre=/bin/hciconfig %I piscan
ExecStartPre=/bin/hciconfig %I sspmode 1
ExecStart=/usr/bin/bt-agent --capability=NoInputNoOutput
RestartSec=5
Restart=always
KillSignal=SIGUSR1

[Install]
WantedBy=multi-user.target
EOF

    sudo tee /etc/systemd/system/bluealsa-aplay.service.d/override.conf > /dev/null <<'EOF'
[Service]
ExecStart=/usr/bin/bluealsa-aplay --pcm=plughw:CARD=sndrpihifiberry,DEV=0 00:00:00:00:00:00
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable bt-agent@hci0.service
    sudo systemctl enable bluealsa-aplay.service
}

verify_os
install_hifiberry
install_bluetooth
