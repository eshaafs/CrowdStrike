#!/bin/zsh

# Check if a maintenance token is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <maintenance-token>"
    exit 1
fi

# Store the maintenance token
MAINTENANCE_TOKEN="$1"

# Create a cleanup script that will delete the Falcon app after 1 minute
cleanup_script="/tmp/cleanup_falcon.sh"
cat << EOF > "$cleanup_script"
#!/bin/zsh
sudo rm -rf /Applications/Falcon.app
EOF

# Make the cleanup script executable
chmod +x "$cleanup_script"

# Create a launchctl plist file to schedule the cleanup script to run 1 minute later
launchctl_plist="/tmp/com.cleanup_falcon.plist"
cat << EOF > "$launchctl_plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.cleanup_falcon</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>$cleanup_script</string>
    </array>
    <key>StartInterval</key>
    <integer>60</integer>  <!-- Start after 1 minute (60 seconds) -->
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

# Load the launchctl job to execute the cleanup script
sudo launchctl load -w "$launchctl_plist"

# Now proceed to create the expect script to handle the uninstall
expect_script="/tmp/uninstall_falcon.exp"

# Write the expect script to the temporary file
cat << EOF > "$expect_script"
#!/usr/bin/expect -f

# Set timeout to handle any delays
set timeout -1

# Define the maintenance token
set maintenance_token "[lindex \$argv 0]"

# Run the falconctl uninstall command and expect a prompt for the maintenance token
spawn sudo /Applications/Falcon.app/Contents/Resources/falconctl uninstall --maintenance-token

# Wait for the prompt that asks for the maintenance token
expect {
    "Falcon Maintenance Token:" {
        send "\$maintenance_token\r"
    }
    timeout {
        puts "Error: Timeout waiting for Falcon Maintenance Token prompt."
        exit 1
    }
}

# Allow the uninstallation process to continue
expect eof
EOF

# Make the expect script executable
chmod +x "$expect_script"

# Execute the expect script with the maintenance token
"$expect_script" "$MAINTENANCE_TOKEN"

# Clean up the temporary expect script
rm "$expect_script"
