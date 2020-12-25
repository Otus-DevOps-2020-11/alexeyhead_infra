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
