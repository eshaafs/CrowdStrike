#!/bin/bash

# Detect the distribution and write the uninstall script to /tmp/uninstall_crowdstrike.sh

if grep -qi 'ubuntu\|debian\|linux mint' /etc/*release; then
    uninstall_command='apt-get remove falcon-sensor -y &'
elif grep -qi 'centos\|redhat\|fedora' /etc/*release; then
    uninstall_command='yum remove falcon-sensor -y &'
elif grep -qi 'arch' /etc/*release; then
    uninstall_command='pacman -Rns falcon-sensor --noconfirm &'
elif grep -qi 'opensuse' /etc/*release; then
    uninstall_command='zypper remove falcon-sensor -y &'
else
    uninstall_command='echo "Distro not recognized"'
fi

# Create the uninstall script in /tmp
echo -e "#!/bin/bash\n$uninstall_command" > /tmp/uninstall_crowdstrike.sh

# Give execution permissions to the file
chmod +x /tmp/uninstall_crowdstrike.sh

# Run the uninstall script with sudo
sudo bash /tmp/uninstall_crowdstrike.sh
