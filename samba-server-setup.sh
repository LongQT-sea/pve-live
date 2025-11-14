#!/bin/bash
# Samba Server Setup Script

# Configuration Variables (modify these before running)
SMB_USER="longqt"
SMB_USER_PASSWD="strongPassword"
SMB_GROUP="smbs"
MOUNT_POINT="/mnt/hdd-pool"
ALLOW_NETWORK=192.168.0.0/16

HOSTNAME="$(cat /etc/hostname)"
WORKGROUP="WORKGROUP"

# Install samba if needed
if ! command -v smbd &>/dev/null; then
    echo "Installing Samba..."
    apt update -y && apt install -y samba
fi

# Check MOUNT_POINT
if [ ! -d "$MOUNT_POINT" ]; then
    echo "$MOUNT_POINT does not exist."
    exit 1
fi

# Create group if needed
groupadd -f $SMB_GROUP

# Create a '$SMB_USER' for Samba and add to '$SMB_GROUP' group
if ! id "$SMB_USER" &>/dev/null; then
    useradd -M -s /usr/sbin/nologin -g $SMB_GROUP -G $SMB_GROUP $SMB_USER
fi

# Add '$SMB_USER' to the Samba user database and sets a Samba-specific password
smbpasswd -a $SMB_USER << EOD
$SMB_USER_PASSWD
$SMB_USER_PASSWD
EOD

# Change ownership of the '$MOUNT_POINT' to allow the smbs group access
chown -R $SMB_USER:$SMB_GROUP $MOUNT_POINT

# Set permissions: directories 2775 (setgid for group inheritance), files 664 (rw-rw-r--)
find $MOUNT_POINT -type d -exec chmod 2775 {} \;
find $MOUNT_POINT -type f -exec chmod 664 {} \;

# Create Samba configuration file
cat <<EOF > /etc/samba/smb.conf
[global]
# Server identification
netbios name = $HOSTNAME
workgroup = $WORKGROUP
server string = Secure File Server

# Security settings
map to guest = Bad User

# Protocol security 
server signing = mandatory
client signing = mandatory
server smb encrypt = required
client smb encrypt = required
client min protocol = SMB3

# Network security
hosts allow = $ALLOW_NETWORK
hosts deny = 0.0.0.0/0
smb ports = 445
disable netbios = yes

# Improved async operations
aio read size = 16384
aio write size = 16384

# Enable SMB multichannel (Windows clients)
server multi channel support = yes

# Logging
log level = 0
log file = /var/log/samba/%m.log
max log size = 5000

# Disable printing
load printers = no
printing = bsd
printcap name = /dev/null
disable spoolss = yes

# macOS-specific optimizations
veto files = /._*/.DS_Store/
delete veto files = yes

[HDD-POOL]
comment = HDD-POOL
path = $MOUNT_POINT
valid users = @${SMB_GROUP}
force group = ${SMB_GROUP}
read only = no
browseable = yes
create mask = 0664
directory mask = 0775
inherit acls = yes
vfs objects = acl_xattr fruit

# Guest-accessible share
#[Public]
#path = /mnt/public
#comment = Public Share
#browseable = yes
#guest ok = yes
#read only = no
#force user = nobody
#force group = nogroup
EOF

# Restart and enable Samba services
echo "Restarting Samba services..."
systemctl restart smbd

echo ''
echo "Samba setup completed successfully!"
echo "Remember to configure firewall if needed"
