resource "yandex_lb_target_group" "app_target_group" {
  name = "reddit-app-target-group"

  target {
    address = "${yandex_compute_instance.app.network_interface.0.ip_address}"
    subnet_id = var.subnet_id
  }
}

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
