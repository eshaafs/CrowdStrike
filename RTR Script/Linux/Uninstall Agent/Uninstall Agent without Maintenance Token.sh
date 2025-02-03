#!/bin/bash

# Create the uninstall script
cat <<EOF > /tmp/uninstall_crowdstrike.sh
#!/bin/bash

# Detect the Linux distribution and uninstall the CrowdStrike sensor
if grep -qi 'ubuntu\|debian' /etc/*release; then
    sudo apt purge falcon-sensor -y
elif grep -qi 'rhel\|centos\|oracle\|amazon' /etc/*release; then
    sudo yum remove falcon-sensor -y
elif grep -qi 'sles\|suse' /etc/*release; then
    sudo zypper remove falcon-sensor -y
elif grep -qi 'photon' /etc/*release; then
    sudo tdnf remove falcon-sensor -y
else
    echo '{"status": "error", "message": "Unsupported Linux distribution."}' > /tmp/uninstall_crowdstrike.log
    exit 1
fi

# Reload systemd daemon to clean up lingering service files
sudo systemctl daemon-reload

# Log success
echo '{"status": "success", "message": "Falcon Sensor uninstalled successfully."}' > /tmp/uninstall_crowdstrike.log

EOF

# Give execution permissions to the file
chmod +x /tmp/uninstall_crowdstrike.sh

# Run the uninstall script with sudo
sudo bash /tmp/uninstall_crowdstrike.sh
