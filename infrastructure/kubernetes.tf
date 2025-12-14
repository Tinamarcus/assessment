locals {
  kubernetes_manifests = {
    deployment = templatefile("${path.module}/../kubernetes/templates/deployment.yaml.tpl", {
      container_image    = var.container_image
      mongodb_private_ip = module.mongodb.private_ip
    })
    ingress = templatefile("${path.module}/../kubernetes/templates/ingress.yaml.tpl", {
      acm_certificate_arn = var.acm_certificate_arn
    })
  }
}

resource "local_file" "deployment" {
  content  = local.kubernetes_manifests.deployment
  filename = "${path.module}/../kubernetes/deployment.yaml"

  depends_on = [module.mongodb]
}

resource "local_file" "ingress" {
  content  = local.kubernetes_manifests.ingress
  filename = "${path.module}/../kubernetes/ingress.yaml"
}

output "kubernetes_manifests_generated" {
  description = "Kubernetes manifest files have been generated"
  value       = "Manifests generated in kubernetes/ directory"
}