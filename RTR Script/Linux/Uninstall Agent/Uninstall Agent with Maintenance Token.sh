#!/bin/bash

# Check if the input JSON is provided
if [ -z "$1" ]; then
    echo '{"status": "error", "message": "Maintenance token JSON is required."}'
    exit 1
fi

# Parse the maintenance token from the JSON input without jq
MAINTENANCE_TOKEN=$(echo "$1" | sed -n 's/.*"maintenance-token":"\([^"]*\)".*/\1/p')

# Check if the token was extracted correctly
if [ -z "$MAINTENANCE_TOKEN" ]; then
    echo '{"status": "error", "message": "Invalid JSON format or missing maintenance-token."}'
    exit 1
fi

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

# Give execution permission to the script
chmod +x /tmp/uninstall_crowdstrike.sh

# Authorize the maintenance token
/opt/CrowdStrike/falconctl -s --maintenance-token="$MAINTENANCE_TOKEN"

# Jadwal cron untuk menjalankan uninstall script dalam 1 menit
CRON_TIME=$(date -d "+1 minute" +"%M %H %d %m *")
echo "$CRON_TIME root /tmp/uninstall_crowdstrike.sh" >> /etc/crontab

# Jadwal cron untuk menghapus cron job dalam 3 menit
CLEANUP_TIME=$(date -d "+3 minute" +"%M %H %d %m *")
echo "$CLEANUP_TIME root sed -i '/uninstall_crowdstrike.sh/d' /etc/crontab" >> /etc/crontab

# Restart cron service agar perubahan diterapkan
sudo systemctl restart cron

# Return success response
echo '{"status": "success", "message": "Uninstallation script scheduled via cron."}'
