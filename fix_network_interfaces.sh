#!/bin/bash

# Exit on error
set -e

# Define the configuration file path
CONFIG_FILE="/etc/NetworkManager/conf.d/99-custom-managed-devices.conf"

# Step 1: Create a custom configuration to manage all devices
echo "Creating custom NetworkManager configuration..."
sudo bash -c "cat > $CONFIG_FILE <<EOF
[keyfile]
unmanaged-devices=none
EOF"

# Step 2: Restart NetworkManager
echo "Restarting NetworkManager..."
sudo systemctl restart NetworkManager

# Step 3: Get a list of Ethernet interfaces
ETH_INTERFACES=$(ls /sys/class/net | grep -E "^en" | grep -v "lo")

echo "Detected Ethernet interfaces: $ETH_INTERFACES"

# Step 4: Loop through each interface and create a connection profile
for iface in $ETH_INTERFACES; do
    echo "Configuring interface: $iface"

    # Check if interface already has a connection
    if nmcli con show | grep -q "$iface"; then
        echo "Connection for $iface already exists. Skipping..."
    else
        # Create a new connection profile with DHCP
        sudo nmcli connection add type ethernet ifname "$iface" con-name "$iface" ipv4.method auto
    fi

    # Bring up the connection
    echo "Bringing up $iface..."
    sudo nmcli connection up "$iface" || echo "Failed to bring up $iface. Check link status."
done

# Step 5: Verify link status for all interfaces
for iface in $ETH_INTERFACES; do
    echo "Checking link status for $iface..."
    sudo ethtool "$iface" | grep "Link detected" || echo "$iface may not be connected to a network."
done

# Final status report
echo "Network device status:"
nmcli device status

echo "Script execution completed."

