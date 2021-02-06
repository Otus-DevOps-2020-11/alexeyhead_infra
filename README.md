### HW No. 7 (Lecture No. 9)

- The practical task of the method is performed
- Explicit and implicit dependences are considered
- Created packer template db.json for VM build with MongoDB installed

```
{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{ user `service_account_key_file` }}",
            "folder_id": "{{ user `folder_id` }}",
            "source_image_family": "ubuntu-1604-lts",
            "image_name": "reddit-db-base-{{timestamp}}",
            "image_family": "reddit-db-base",
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
            "script": "./scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}

```
- Created packer template app.json for VM build with Ruby installed

```bash
{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{ user `service_account_key_file` }}",
            "folder_id": "{{ user `folder_id` }}",
            "source_image_family": "ubuntu-1604-lts",
            "image_name": "reddit-app-base-{{timestamp}}",
            "image_family": "reddit-app-base",
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
        }
    ]
}

```
- The infrastructure is divided by modules to create separate VMs: for app and for db

```
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
  version                  = "~> 0.35.0"
}

module "app" {
  source           = "../modules/app"
  public_key_path  = var.public_key_path
  private_key_path = var.private_key_path
  app_disk_image   = var.app_disk_image
  subnet_id        = var.subnet_id
  database_url     = module.db.external_ip_address_db
}

module "db" {
  source           = "../modules/db"
  public_key_path  = var.public_key_path
  private_key_path = var.private_key_path
  db_disk_image    = var.db_disk_image
  subnet_id        = var.subnet_id
}

```
- Create infrastructure for two environments - stage and prod

```bash
├── files
│   ├── deploy.sh
│   ├── lb.tf
│   └── puma.service
├── modules
│   ├── app
│   │   ├── files
│   │   │   ├── deploy.sh
│   │   │   └── puma.service
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── db
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── prod
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   ├── terraform.tfvars.example
│   └── variables.tf
├── stage
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   ├── terraform.tfvars.example
│   └── variables.tf

```
- Module configurations are parameterized
- Configuration files are formatted
- The backend.tf file describes remote state storage using Yandex Object Storage

```bash
terraform {
  backend "s3" {
    endpoint = "storage.yandexcloud.net"
    bucket = "odo"
    region = "ru-central1"
    # key        = "prod/terraform.tfstate"
    key        = "terraform.tfstate"
    access_key = "some_access_key"
    secret_key = "some_secret_key"
    dynamodb_endpoint = "https://docapi.serverless.yandexcloud.net/dynamodb_endpoint"
    dynamodb_table = "some_dynamodb_table"

    skip_region_validation     = true
    skip_credentials_validation = true
  }
}

```
- Checked the operation of locks
- Added provisioners for deployment and application operation

```bash
modules/app/main.tf
...
provisioner "file" {
    content        = templatefile("${path.module}/files/puma.service", {
      database_url = "${var.database_url}:27017"
    })
    destination    = "/tmp/puma.service"
  }
  provisioner "remote-exec" {
    script = "../files/deploy.sh"

```

```bash
modules/db/main.tf
...
provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g' /etc/mongod.conf",
      "sudo systemctl restart mongod"
    ]
  }

```
