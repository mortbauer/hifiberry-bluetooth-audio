# Hifiberry Bluetooth Audio Receiver on Raspberry Pi Debian Trixi

## Objective

* make your raspberry pi + hifiberry-dacplus a simple bluetooth audio sink

## Install

* required is a raspbwerry pi + hifiberry-dacplus (will work with another very similar just adapt the dtoverlay)
* required raspberry pi os (debian trixie)
* run './install.sh`

## Background Info
* did not make it work with pipewire and wireplumber despite checking out the following repos:
    * rpi-audio-receiver
    * pw_wp_bluetooth_rpi_speaker

* so i went for low level alsa which worked out of the box
