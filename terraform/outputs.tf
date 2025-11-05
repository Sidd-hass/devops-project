output "cluster_id" {
  description = "The ID of the created Civo Kubernetes cluster"
  value       = civo_kubernetes_cluster.k8s.id
}

output "kubeconfig_path" {
  description = "Location of the saved kubeconfig file"
  value       = "${path.module}/kubeconfig_${civo_kubernetes_cluster.k8s.name}.yaml"
}
