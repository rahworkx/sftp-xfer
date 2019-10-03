# Sftp Xfer

Shell Script to setup a sftp server with user isolation. 
I created this script to help ease the issues of setting up and adding multiple users to a sftp server. 

## Getting Started

The Shell script will do the following
- Create User
- Create Group
- Create and add Password to User
- Create Home Directory
- Create Inbound, Outbound Error, Processed folders in Home Directory
- Add A public key to user if provided
- Chroot Jail user to home folder
- Only allow sftp login *Not SSH*

### Prerequisites
Created for a Centos 7 server. 
Needs AWS CLI with SecretsManager Policy *python3 +*

## Running 

The Following example is of all options
```
sh sftp-xfer.sh client01 client01_sftponly /opt/keys/id_rsa.pub
```

The following example does not set a pub key. However user and group are mandatory
```
sh sftp-xfer.sh client01 client01_sftponly 
```

## Acknowledgments

* StackOverflow Diggin
