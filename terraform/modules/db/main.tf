resource "yandex_compute_instance" "db" {
  name = "reddit-db"
  labels = {
    tags = "reddit-db"
  }

  resources {
    core_fraction = 5
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.db_disk_image
    }
  }

  network_interface {
    #subnet_id = yandex_vpc_subnet.app-subnet.id
    subnet_id = var.subnet_id
    nat = true
  }

  metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  connection {
    type = "ssh"
    host = self.network_interface.0.nat_ip_address
    user = "ubuntu"
    agent = false
    # private key path
    # private_key = file("~/.ssh/appuser")
    private_key = file(var.private_key_path)
  }

//  provisioner "remote-exec" {
//    inline = [
//      "sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g' /etc/mongod.conf",
//      "sudo systemctl restart mongod"
//    ]
//  }
}
