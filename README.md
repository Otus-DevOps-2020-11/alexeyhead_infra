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

- Create ubuntu16.json for building custom VM image, copy scripts install_* from ./config-script to ./packer/scripts
- Check and build Packer template
```
packer validate ./ubuntu16.json
packer build ./ubuntu16.json
```
- Create new VM from YC and deploy app (from deploy.sh).
- Create variables.json.example with custom variables for Packer
- Create systemd unit named "packer/files/puma.service" for start Puma service when VM is booted
- Create immutable.json for building "baked" image with installed Ruby, MongoDB and Monolith app
- Create a script config-scripts/create-reddit-vm.sh to run a backed image with a set of software and application

### HW No. 6 (Lecture No. 8)

- Download terraform version 0.12.8, unzip and move to directory contained in the $PATH
- Exclude terraform service files and directories in .gitignore

```bash
*.tfstate
*.tfstate.*.backup
*.tfstate.backup
*.tfvars
.terraform/
```
##### Terraform initialization

- Create main.tf with the following contents

```bash
provider "yandex" {
  token     = "some_token"
  cloud_id  = "some_cloud_id"
  folder_id = "some_folder_id"
  zone      = "some_zone"
  version   = "~> 0.35.0"
}
```

- To get your values use the command

```bash
$ yc config list
```

- And finally run next command to download terraform provider module

```bash
terraform init
```

##### Terraform resources and provisioners

- Add the following code in `main.tf` to create a VM

```bash
resource "yandex_compute_instance" "app" {
  name = "reddit-app"

  resources {
    core_fraction = 5
    cores         = 2
    memory        = 2
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }
  network_interface {
    subnet_id = var.subnet_id
    nat       = "true"
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
  connection {
    type  = "ssh"
    host  = yandex_compute_instance.app.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # private key path
    # private_key = file("~/.ssh/appuser")
    private_key = file(var.private_key_path)
  }
  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }
  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}
```
where:

```bash
- resources - info about CPU
- boot_disk - info about Disk
- network_interface - info about network
- metadata - allows a provider to declare metadata fields (e.g. ssh-keys)
- connection - info about connection settings for provisioners
- provisioner - allows you to execute commands

```

- Check what terraform plans to do

```bash
terraform plan
```
`+` means: the resource will be created

`-` means: the resource will be deleted

- To start instance VM, run:

```bash
terraform apply
```

- Check connection to VM

```bash
ssh ubuntu@nat_ip_address
```

##### Output vars
- create `outputs.tf` - file with output variables, to facilitate the search for the necessary information

```
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
```

- recreate the VM resource in the next application of changes

```bash
$ terraform taint yandex_compute_instance.app
Resource instance yandex_compute_instance.app has been marked as tainted
```
- Run `terraform apply` and find VM external nat_ip_address

```bash
Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
Outputs:
external_ip_address_app = 84.201.130.224
```

##### Check that the application works.

- Follow link:

```bash
http://nat_ip_address:9292
```

##### Input vars

- Create `variables.tf` - file with input variables that will allow you to parameterize the configuration files

```bash
variable cloud_id {
  description = "Cloud"
}
variable folder_id {
  description = "Folder"
}
variable zone {
  description = "Zone"
  # default value
  default = "ru-central1-a"
}
variable public_key_path {
  description = "Path to the public key used for ssh access"
}
variable image_id {
  description = "Disk image"
}
variable subnet_id {
  description = "Subnet"
}
variable service_account_key_file {
  description = "key .json"
}
variable private_key_path {
  description = "Path to the private key used for ssh access"
}
```
Now we can use input var for definition other resourses. Use syntax `var.var_name` to get the value

- Define some values in special file `terraform.tfvars` for automatic use when the terraform start

```bash
cloud_id                 = "some_cloud_id"
folder_id                = "some_folder_id"
zone                     = "some_zone"
image_id                 = "some_image_id"
service_account_key_file = "/path/to/key.json"
public_key_path          = "/path/to/public.key"
subnet_id                = "some_subnet_id"
private_key_path         = "/path/to/private.key"
```
##### Tasks

- Task1 - Define input var for private key
- Solution1

Add to `main.tf`
```bash
connection {
    type  = "ssh"
    host  = yandex_compute_instance.app.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # private key path
    private_key = file(var.private_key_path)
  }
```
Add to `terraform.tfvars.example`
```bash
private_key_path         = "/path/to/private.key"
```
- Task2 - Define default input var for zone
- Solution2

Add to `variables.tf`
```bash
variable zone {
  description = "Zone"
  # default value
  default = "ru-central1-a"
}
```
##### Task with *

First task with *

- Create `lb.tf` with describe loadbalancer for reddit app
- Add output var for IP address loadbalancer

First solution with *

- Create `lb.tf`

```bash
resource "yandex_lb_network_load_balancer" "app_load_balancer" {
  name = "reddit-app-load-balancer"

  listener {
    name = "reddit-app-listener"
    port = 9292
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = "${yandex_lb_target_group.app_target_group.id}"

    healthcheck {
      name = "http"
      http_options {
        port = 9292
        path = "/"
      }
    }
  }
}

resource "yandex_lb_target_group" "app_target_group" {
  name = "reddit-app-target-group"

  target {
    address = "${yandex_compute_instance.app.network_interface.0.ip_address}"
    subnet_id = var.subnet_id
  }
}
```
- Add to `outputs.tf` LB IP-address

```bash
output "external_ip_address_lb" {
  value = yandex_lb_network_load_balancer.app_load_balancer.listener.*.external_address_spec.0.address
}
```

---
Second task with *

- Add terraform resource copy for new instance `reddit-app2`
- Add second instance to LB
- Check that app work on LB_IP, even if on one instance made stop puma-service
- Add output var for reddit-app2 IP address
- Which problem you see?

Second solution with *

- Add to `main.tf` instance copy

```bash
resource "yandex_compute_instance" "app2" {
  name = "reddit-app2"

  resources {
    core_fraction = 5
    cores         = 2
    memory        = 2
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }
  network_interface {
    subnet_id = var.subnet_id
    nat       = "true"
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
  connection {
    type  = "ssh"
    host  = yandex_compute_instance.app2.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # private key path
    # private_key = file("~/.ssh/appuser")
    private_key = file(var.private_key_path)
  }
  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }
  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
```
- Add to `lb.tf`

```bash
  target {
    address = "${yandex_compute_instance.app2.network_interface.0.ip_address}"
    subnet_id = var.subnet_id
  }
```
- connect to VM - use external_ip_address_app or external_ip_address_app2 from output
- run
```bash
sudo systemctl stop puma
```
- Follow link `http://LB_IP:9292` - Monolith stil works!
- Add to `outputs.tf` second instance IP-address
```bash
output "external_ip_address_app2" {
  value = yandex_compute_instance.app2.network_interface.0.nat_ip_address
}
```

- I see next problem - Too much code of the same type - it's easy to forget to change the instance name or add new instance to loadbalancer.

---

Third task with *

- Add instance with `count`

Third solution with *

- Deleted resourse `reddit-app2` and recreate `main.tf` with `count`

```
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
  version                  = "~> 0.35.0"
}

resource "yandex_compute_instance" "app" {
  count = var.vm_count

  name  = "reddit-app-${count.index}"

  resources {
    core_fraction = 5
    cores         = 2
    memory        = 2
  }
  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }
  network_interface {
    subnet_id = var.subnet_id
    nat       = "true"
  }
  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
  connection {
    type  = "ssh"
    #host  = yandex_compute_instance.app[count.index].network_interface.0.nat_ip_address
    host  = self.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # private key path
    # private_key = file("~/.ssh/appuser")
    private_key = file(var.private_key_path)
  }
  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }
  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}

```

- Added input var to `variables.tf` with default value

```
variable vm_count {
  description = "Number of VM"
  # default value
  default = 1
}
```

- Changed `outputs.tf`

```
output "external_ip_address_app" {
  value = {
    for external_ip_address_app in yandex_compute_instance.app :
    external_ip_address_app.name => external_ip_address_app.network_interface.0.nat_ip_address
  }
}
output "external_ip_address_lb" {
  value = yandex_lb_network_load_balancer.app_load_balancer.listener.*.external_address_spec.0.address
}
```
- Changed `lb.tf`

```
resource "yandex_lb_network_load_balancer" "app_load_balancer" {
  name = "reddit-app-load-balancer"

  listener {
    name = "reddit-app-listener"
    port = 9292
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = "${yandex_lb_target_group.app_target_group.id}"

    healthcheck {
      name = "http"
      http_options {
        port = 9292
        path = "/"
      }
    }
  }
}

resource "yandex_lb_target_group" "app_target_group" {
  name = "reddit-app-target-group"

  dynamic "target" {
    for_each = yandex_compute_instance.app.*.network_interface.0.ip_address
    content {
      subnet_id = var.subnet_id
      address = target.value
    }
  }
}
```
