resource "yandex_compute_instance" "app" {
  name = "reddit-app"

  labels = {
    tags = "reddit-app"
  }
  resources {
    core_fraction = 5
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.app_disk_image
    }
  }

  network_interface {
    #subnet_id = yandex_vpc_subnet.app-subnet.id
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  connection {
    type  = "ssh"
    host  = self.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # private key path
    # private_key = file("~/.ssh/appuser")
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    # source = "../files/puma.service"
    # content     = templatefile("${path.module}/files/puma.service", { database_url = var.database_url })
    content        = templatefile("${path.module}/files/puma.service", {
      database_url = "${var.database_url}:27017"
    })
    destination    = "/tmp/puma.service"
  }
  provisioner "remote-exec" {
    script = "../files/deploy.sh"
  }
}
