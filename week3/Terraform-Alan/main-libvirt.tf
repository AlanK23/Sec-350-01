provider "libvirt" {
  uri = "qemu:///system"
}

variable "vm_memory" {
  description = "VM memory in KiB"
  type        = number
  default     = 1048576 # 1 GB
}

variable "vm_vcpu" {
  description = "Number of virtual CPUs"
  type        = number
  default     = 4
}

resource "libvirt_network" "lan" {
  name      = "${var.student_name}-lan"
  autostart = true

  forward = {
    mode = "nat"
  }

  ips = [
    {
      address = "192.168.101.1"
      prefix  = 24
      family  = "ipv4"

      dhcp = {
        ranges = [
          {
            start = "192.168.101.100"
            end   = "192.168.101.254"
          }
        ]
      }
    }
  ]
}

resource "libvirt_pool" "default" {
  name = "${var.student_name}-default"
  type = "dir"

  target = {
    path = "/var/lib/libvirt/images/${var.student_name}"
    permissions = {
      owner = 64055
      group = 64055
      mode  = "0750"
    }
  }
}

resource "libvirt_volume" "ubuntu_base" {
  name = "${var.student_name}-ubuntu-base.qcow2"
  pool = libvirt_pool.default.name

  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    }
  }

  depends_on = [libvirt_pool.default]
}

resource "libvirt_volume" "ubuntu_disk" {
  name     = "${var.student_name}-ubuntu-server.qcow2"
  pool     = libvirt_pool.default.name
  capacity = 42949672960 # 40 GB

  target = {
    format = {
      type = "qcow2"
    }
  }

  backing_store = {
    path = libvirt_volume.ubuntu_base.path
    format = {
      type = "qcow2"
    }
  }
}

resource "libvirt_domain" "ubuntu_server" {
  name   = "${var.student_name}-ubuntu-server"
  memory = var.vm_memory
  vcpu   = var.vm_vcpu
  type   = "kvm"

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = libvirt_pool.default.name
            volume = libvirt_volume.ubuntu_disk.name
          }
        }
        target = {
          bus = "virtio"
          dev = "vda"
        }
        driver = {
          type = "qcow2"
        }
      }
    ]

    interfaces = [
      {
        type  = "network"
        model = { type = "virtio" }
        source = {
          network = {
            network = libvirt_network.lan.name
          }
        }
      }
    ]

    graphics = [
      {
        vnc = {
          auto_port = true
          listen    = "127.0.0.1"
        }
      }
    ]
  }

  running = true
}

output "network_address" {
  value = "Network '${libvirt_network.lan.name}' CIDR: 192.168.101.0/24, Gateway: 192.168.101.1"
}

output "vm_name" {
  value = libvirt_domain.ubuntu_server.name
}
