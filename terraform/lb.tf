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

#  target {
#    address = "${yandex_compute_instance.app2.network_interface.0.ip_address}"
#    subnet_id = var.subnet_id
#  }
}
