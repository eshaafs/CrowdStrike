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

# Authorize the maintenance token
/opt/CrowdStrike/falconctl -s --maintenance-token="$MAINTENANCE_TOKEN"

# Create the encoded uninstall script
ENCODED_SCRIPT="IyEvYmluL2Jhc2gKCiMgRGV0ZWN0IHRoZSBMaW51eCBkaXN0cmlidXRpb24gYW5kIHVuaW5zdGFsbCB0aGUgQ3Jvd2RTdHJpa2Ugc2Vuc29yCmlmIGdyZXAgLXFpICd1YnVudHVcfGRlYmlhbicgL2V0Yy8qcmVsZWFzZTsgdGhlbgogICAgc3VkbyBhcHQgcHVyZ2UgZmFsY29uLXNlbnNvciAteQplbGlmIGdyZXAgLXFpICdyaGVsXHxjZW50b3NcfG9yYWNsZVx8YW1hem9uJyAvZXRjLypyZWxlYXNlOyB0aGVuCiAgICBzdWRvIHl1bSByZW1vdmUgZmFsY29uLXNlbnNvciAteQplbGlmIGdyZXAgLXFpICdzbGVzXHxzdXNlJyAvZXRjLypyZWxlYXNlOyB0aGVuCiAgICBzdWRvIHp5cHBlciByZW1vdmUgZmFsY29uLXNlbnNvciAteQplbGlmIGdyZXAgLXFpICdwaG90b24nIC9ldGMvKnJlbGVhc2U7IHRoZW4KICAgIHN1ZG8gdGRuZiByZW1vdmUgZmFsY29uLXNlbnNvciAteQplbHNlCiAgICBlY2hvICd7InN0YXR1cyI6ICJlcnJvciIsICJtZXNzYWdlIjogIlVuc3VwcG9ydGVkIExpbnV4IGRpc3RyaWJ1dGlvbi4ifScgPiAvdG1wL3VuaW5zdGFsbF9jcm93ZHN0cmlrZS5sb2cKICAgIGV4aXQgMQpmaQoKIyBSZWxvYWQgc3lzdGVtZCBkYWVtb24gdG8gY2xlYW4gdXAgbGluZ2VyaW5nIHNlcnZpY2UgZmlsZXMKc3VkbyBzeXN0ZW1jdGwgZGFlbW9uLXJlbG9hZAoKIyBMb2cgc3VjY2VzcwplY2hvICd7InN0YXR1cyI6ICJzdWNjZXNzIiwgIm1lc3NhZ2UiOiAiRmFsY29uIFNlbnNvciB1bmluc3RhbGxlZCBzdWNjZXNzZnVsbHkuIn0nID4gL3RtcC91bmluc3RhbGxfY3Jvd2RzdHJpa2UubG9nCg=="

# Decode and create the uninstall script
echo "$ENCODED_SCRIPT" | base64 -d > /tmp/uninstall_crowdstrike.sh

# Give execution permission to the script
chmod +x /tmp/uninstall_crowdstrike.sh

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