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

//  connection {
//    type  = "ssh"
//    #host  = yandex_compute_instance.app[count.index].network_interface.0.nat_ip_address
//    host  = self.network_interface.0.nat_ip_address
//    user  = "ubuntu"
//    agent = false
//    # private key path
//    # private_key = file("~/.ssh/appuser")
//    private_key = file(var.private_key_path)
//  }
//  provisioner "file" {
//    source      = "files/puma.service"
//    destination = "/tmp/puma.service"
//  }
//  provisioner "remote-exec" {
//    script = "files/deploy.sh"
//  }
