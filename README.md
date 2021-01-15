# alexeyhead_infra
alexeyhead Infra repository

### HW No. 3 (Lecture No. 5)

IP addresses

```
bastion_IP = 178.154.255.210
someinternalhost_IP = 10.130.0.25

```

#### Connection to the someinternalhost in one line

```
ssh -i ~/.ssh/appuser -J appuser@178.154.255.210 appuser@10.130.0.25
```

#### Connection from the console using the command `ssh someinternalhost`

Honestly, at first I thought of just creating an alias and adding it to .bashrc, but after searching in Google I read about the next option with ProxyJump:

Add to ~/.ssh/config next lines

```
Host bastion
	User appuser
	Hostname 178.154.255.210
	IdentityFile ~/.ssh/appuser
Host someinternalhost
	User appuser
	Hostname 10.130.0.25
	IdentityFile ~/.ssh/appuser
	ProxyJump bastion
```
After saving the file do the following command:

`ssh someinternalhost`

Output should be as follows

```
Welcome to Ubuntu 16.04.6 LTS (GNU/Linux 4.4.0-142-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

appuser@someinternalhost:~$

```

### HW No. 4 (Lecture No. 6)

```
testapp_IP = 84.201.130.59
testapp_port = 9292
```

##### Install testapp using scripts

- Create and copy scripts to VM

```
scp ./install_ruby.sh yc-user@testapp_IP:
scp ./install_mongodb.sh yc-user@testapp_IP:
scp ./deploy.sh yc-user@testapp_IP:
```

- Execute scripts in copy order

##### Install testapp using startup script

- Create metadata.yaml
- Run the following command using CLI

```
yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --metadata-from-file user-data=./metadata.yml
```
### HW No. 5 (Lecture No. 7)

- Installed and configured Packer to work with YC. Create service account YC, key and setup role

```
SVC_ACCT="some_name"
FOLDER_ID="folder_id_from yc config list"
yc iam service-account create --name $SVC_ACCT --folder-id $FOLDER_ID
ACCT_ID=$(yc iam service-account get $SVC_ACCT grep ^id awk '{print $2}')
yc resource-manager folder add-access-binding --id $FOLDER_ID --role editor --service-account-id $ACCT_ID
yc iam key create --service-account-id $ACCT_ID --output /path/to/file/key.json
```

- Create ubuntu16.json for building custom VM image, copy cripts install_* from ./config-script to ./packer/scripts

```
{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "вставьте путь до своего",
            "folder_id": "вставьте свой",
            "source_image_family": "ubuntu-1604-lts",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "use_ipv4_nat" = "true",
            "ssh_username": "ubuntu",
            "platform_id": "standard-v1"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```

- Check and build Packer template

```
packer validate ./ubuntu16.json
packer build ./ubuntu16.json
```

- Create new VM from YC and deploy app (from deploy.sh).

- Create variables.json.example with custom variables for Packer

```
{
  "token": "some_token",
  "folder_id": "some_folder_id",
  "source_image_family": some_image_family",
  "service_account_key_file": "/path/to/key.json"
}
```

- Create systemd unit named "packer/files/puma.service" for start Puma service when VM is booted

```

```

- Create immutable.json for building "baked" image with installed Ruby, MongoDB and Monolith app

```
{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{ user `service_account_key_file` }}",
            "folder_id": "{{ user `folder_id` }}",
            "source_image_family": "ubuntu-1604-lts",
            "image_name": "reddit-full-{{timestamp}}",
            "image_family": "reddit-full",
	        "use_ipv4_nat": "true",
            "ssh_username": "ubuntu",
            "platform_id": "standard-v1",
            "instance_mem_gb": "2",
            "disk_size_gb": "10"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "./scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "./scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "file",
            "source": "./files/puma.service",
            "destination": "/tmp/puma.service"
        },
        {
            "type": "shell",
            "script": "./scripts/deploy.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```

- Create a script (config-scripts/create-reddit-vm.sh) to run a backed image with a set of software and application

```
#!/usr/bin/env bash
yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=2 \
  --create-boot-disk image-family=reddit-full,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --ssh-key ~/.ssh/appuser.pub
```
