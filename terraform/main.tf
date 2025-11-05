resource "civo_firewall" "k8s_fw" {
  name = "${var.cluster_name}-firewall"
}

resource "civo_kubernetes_cluster" "k8s" {
  name        = var.cluster_name
  region      = var.civo_region
  firewall_id = civo_firewall.k8s_fw.id

  pools {
    node_count = var.node_count
    size       = var.node_size
  }

  applications = ""
}

# Run CLI command to save kubeconfig after cluster is created
resource "null_resource" "get_kubeconfig" {
  depends_on = [civo_kubernetes_cluster.k8s]

  provisioner "local-exec" {
    command = "civo kubernetes config ${civo_kubernetes_cluster.k8s.name} --save"
  }

  provisioner "local-exec" {
    command = "Copy-Item -Path \"$env:USERPROFILE\\.kube\\config\" -Destination \"${path.module}\\kubeconfig_${civo_kubernetes_cluster.k8s.name}.yaml\" -Force"
    interpreter = ["PowerShell", "-Command"]
  }
}
