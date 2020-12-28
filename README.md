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
testapp_IP = 178.154.227.126
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
