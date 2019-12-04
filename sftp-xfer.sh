#!/bin/bash


## Vars
sftp_user=$1
sftp_group=$2
JAILPATH="/home/$sftp_user"
user_pass="$(/usr/local/bin/aws secretsmanager get-random-password --password-length 15 --exclude-punctuation --query 'RandomPassword' --output text --region us-west-2)"
wrkr_key="$3"

#if [ $# -lt 2 ]
#then
#        echo "This script must be run with super-user privileges."
#        echo -e "\nUsage:\n sudo sh add_sftp_user.sh sftpuser sftpuser_sftpgrp  /file/path/ssh.pub --if applicable-- \n"
#fi

## Make sure the Group Exists ##
/bin/egrep  -i "^${sftp_group}" /etc/group
if [ $? -eq 0 ]; then
        echo "Great, group $sftp_group already exists in /etc/group"
else
        echo "Group does not exist, Creating Group $sftp_group..."
        groupadd $sftp_group
fi


## Make Sure User Exists ##
/bin/egrep  -i "^${sftp_user}" /etc/passwd
if [ $? -eq 0 ]; then
        echo "User $sftp_user exists in /etc/passwd, aborting..."
        exit 1
else
        echo "Good, $sftp_user is a new user."

        if [ -d "/home/$sftp_user" ]; then
                echo "/home/$sftp-user already exists, aborting..."
                exit 1
        else
                echo "Creating User $sftp_user"
                adduser $sftp_user

                echo "Seting User: $sftp_user Password to Pass: $user_pass"
                echo "$user_pass" | passwd --stdin $sftp_user

                echo "Creating Folder Directory Structure"
                mkdir -p /home/$sftp_user
                cd /home/ && chown root:$sftp_user $sftp_user
                mkdir -p /home/$sftp_user/Processed
                usermod -m -d /home/$sftp_user/Processed $sftp_user
                mkdir -p /home/$sftp_user/Error
                usermod -m -d /home/$sftp_user/Error $sftp_user
                mkdir -p /home/$sftp_user/Inbound
                usermod -m -d /home/$sftp_user/Inbound $sftp_user
                mkdir -p /home/$sftp_user/Outbound
                usermod -m -d /home/$sftp_user/Outbound $sftp_user
                echo "Done setting Directory Structure"

                echo "Setting Permissions on Folder Directory Structure"
                chown $1:$2 /home/$sftp_user/Processed/
                chmod ug+rwX /home/$sftp_user/Processed/
                chown $1:$2 /home/$sftp_user/Error/
                chmod ug+rwX /home/$sftp_user/Error/
                chown $1:$2 /home/$sftp_user/Inbound/
                chmod ug+rwX /home/$sftp_user/Inbound/
                chown $1:$2 /home/$sftp_user/Outbound/
                chmod ug+rwX /home/$sftp_user/Outbound/
                chmod 777 /home/$sftp_user/Outbound/
                echo "Done setting Permissions on Folder Directory Structure"

                echo "Adding User $sftp_user to $sftp_group"
                usermod -a -G $sftp_group $sftp_user
        fi
fi

## Disable all Login Access except SFTP Only ##
usermod -s /usr/sbin/nologin $sftp_user
chmod 755 /home/$sftp_user

## Add Pub Key from worker to User Authorized Keys ##
if [ -z "$wrkr_key" ]
then
      echo "Wrker Key is empty, Not adding a Key"
else
      echo "Adding the Worker key to the users authorized list"
      mkdir /home/$sftp_user/.ssh
      cd /home/$sftp_user && chmod 700 .ssh
      mv $wrkr_key /home/$sftp_user/.ssh/authorized_keys
      cd /home/$sftp_user/.ssh && chmod 600 authorized_keys
      cd /home/$sftp_user && chown -R $sftp_user:$sftp_user .ssh
fi

## Jail User to its own Home Folder ##
if ! grep -q "Match group $sftp_group" /etc/ssh/sshd_config
then
  echo "* jailing user $sftp_user to group $sftp_group *"

  echo "
## Sftp $sftp_user Group Jail ##
Match group $sftp_group
AuthorizedKeysFile /home/$sftp_user/.ssh/authorized_keys
ChrootDirectory $JAILPATH
AllowTCPForwarding no
X11Forwarding no
ForceCommand internal-sftp
" >> /etc/ssh/sshd_config
fi


echo "#### Completed Addition Of SFTP User ####"
echo "HOST: xfer.materialbank.com"
echo "USER: $sftp_user"
echo "PASS: $user_pass"
echo "### Restarting SSH Daemon for changes to take affect ####"
systemctl restart sshd
