provider "yandex" {
  token     = "AgAAAABL_yx-AATuwdu73CKFZkkoiQ_rGDU_QJw"
  cloud_id  = "b1gr7ijt35laouif2ch5"
  folder_id = "b1g0hb7q84svqad7un6v"
  zone      = "ru-central1-a"
  version   = "~> 0.35.0"
}

resource "yandex_compute_instance" "app" {
  name = "reddit-app"

  resources {
    core_fraction = 5
    cores         = 2
    memory        = 2
  }
  boot_disk {
    initialize_params {
      image_id = "fd8tidpvjkcp8uim7122"
    }
  }
  network_interface {
    subnet_id = "e9b8enc7d61gl9b2hf7v"
    nat       = "true"
  }
  metadata   = {
    ssh-keys = "ubuntu:${file("~/.ssh/appuser.pub")}"
  }
  connection {
    type = "ssh"
    host = yandex_compute_instance.app.network_interface.0.nat_ip_address
    user = "ubuntu"
    agent = false
    # private key path
    private_key = file("~/.ssh/appuser")
  }
  provisioner "file" {
    source = "files/puma.service"
    destination = "/tmp/puma.service"
  }
  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}
