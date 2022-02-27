#!/bin/bash

# Source: https://linuxize.com/post/how-to-install-and-configure-samba-on-centos-7/
echo ' '
echo 'Source is https://linuxize.com/post/how-to-install-and-configure-samba-on-centos-7/'
echo ' '
echo ' '

# yum update
yum update -y

# Install Samba on Centos 7
sudo yum install samba samba-client -y

# Start Samba service
sudo systemctl start smb.service
sudo systemctl start nmb.service

# Enable Samba service
sudo systemctl enable smb.service
sudo systemctl enable nmb.service

# The smbd service provides file sharing and printing services and listens on TCP ports 139 and 445.
# The nmbd service provides NetBIOS over IP naming services to clients and listens on UDP port 137.


# Configuring Firewall
sudo firewall-cmd --permanent --zone=public --add-service=samba
sudo firewall-cmd --zone=public --add-service=samba

# Creating the /samba directory
sudo mkdir /samba

# Create a new group named sambashare. Later we will add all Samba users to this group.
sudo groupadd sambashare

# Set the /samba directory group ownership to sambashare
sudo chgrp sambashare /samba

# Samba uses Linux users and group permission system but it has its own authentication mechanism separate from the standard Linux authentication. We will create the users using the standard Linux useradd tool and then set the user password with the smbpasswd utility


# Creating Samba Users. smbgod
sudo useradd -M -d /samba/smbgod -s /usr/sbin/nologin -G sambashare smbgod

# Create the user’s home directory and set the directory ownership to user smbgod and group sambashare
sudo mkdir /samba/smbgod
sudo chown smbgod:sambashare /samba/smbgod

# The following command will add the setgid bit to the /samba/smbgod directory so the newly created files in this directory will inherit the group of the parent directory.
# This way, no matter which user creates a new file, the file will have group-owner of sambashare.
# For example, if you don’t set the directory’s permissions to 2770 and the sadmin user creates a new file the user smbgod will not be able to read/write to this file.
sudo chmod 2770 /samba/smbgod




# Add the smbgod user account to the Samba database by setting the user password.
echo 'Set Samba password for smbgod user. This is Samba password only, NOT user password'
sudo smbpasswd -a smbgod

# Once the password is set, enable the Samba account by typing.
sudo smbpasswd -e smbgod


# Next, let’s create a user and group sadmin.
# All members of this group will have administrative permissions.
# Later if you want to grant administrative permissions to another user simply add that user to the sadmin group.

# Create the administrative user by typing. This command will also create a group sadmin and add the user to both sadmin and sambashare groups
sudo useradd -M -d /samba/common -s /usr/sbin/nologin -G sambashare sadmin

# Set a password and enable the user.
echo 'Set password for sadmin user. This is Samba password only, NOT user password'
sudo smbpasswd -a sadmin
sudo smbpasswd -e sadmin

# Next, create the common share directory
sudo mkdir /samba/common

# Set the directory ownership to user sadmin and group sambashare.
sudo chown sadmin:sambashare /samba/common

# This directory will be accessible by all authenticated users.
# The following command configures write/read access to members of the sambashare group in the /samba/common directory.
sudo chmod 2770 /samba/common



# Configuring Samba Shares.
# Append the sections.

sudo bash -c 'cat << EOF >> /etc/samba/smb.conf
[common]
	path = /samba/common
	browseable = yes
	read only = no
	force create mode = 0660
	force directory mode = 2770
	valid users = @sambashare @sadmin
[smbgod]
	path = /samba/smbgod
	browseable = no
	read only = no
	force create mode = 0660
	force directory mode = 2770
	valid users = smbgod @sadmin
EOF'


# Restart the Samba services with.
sudo systemctl restart smb.service
sudo systemctl restart nmb.service

# Selinux security context.
sudo chcon -t samba_share_t /samba/smbgod
sudo chcon -t samba_share_t /samba/common
