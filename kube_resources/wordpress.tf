resource "kubernetes_manifest" "service_wordpress" {
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Service"
    "metadata"   = {
            annotations = {
              "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "http",
              "service.beta.kubernetes.io/aws-load-balancer-ssl-ports" = "443",
              "service.beta.kubernetes.io/aws-load-balancer-ssl-cert" = tostring("${module.acm.acm_certificate_arn}"),
              "service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy" = "ELBSecurityPolicy-2016-08",
              "service.beta.kubernetes.io/load-balancer-source-ranges" = "0.0.0.0/0"
            }
      "labels" = {
        "app" = "wordpress"
      }
      "name"    = "wordpress"
      namespace = "default"
    }
    "spec" = {
      "ports" = [
        {
          "port"     = 443
          targetPort = 80
        },
      ]
      "selector" = {
        "app"  = "wordpress"
        "tier" = "frontend"
      }
      "type" = "LoadBalancer"
    }
  }
  depends_on = [module.acm]
}

resource "kubernetes_manifest" "persistentvolumeclaim_wp_pv_claim" {
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "PersistentVolumeClaim"
    "metadata"   = {
      "labels" = {
        "app" = "wordpress"
      }
      "name"    = "wp-pv-claim"
      namespace = "default"
    }
    "spec" = {
      "accessModes" = [
        "ReadWriteOnce",
      ]
      "resources" = {
        "requests" = {
          "storage" = "20Gi"
        }
      }
    }
  }
}

resource "kubernetes_manifest" "deployment_wordpress" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind"       = "Deployment"
    "metadata"   = {
      "labels" = {
        "app" = "wordpress"
      }
      "name"    = "wordpress"
      namespace = "default"
    }
    "spec" = {
      "selector" = {
        "matchLabels" = {
          "app"  = "wordpress"
          "tier" = "frontend"
        }
      }
      "strategy" = {
        "type" = "Recreate"
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app"  = "wordpress"
            "tier" = "frontend"
          }
        }
        "spec" = {
          "containers" = [
            {
              "env" = [
                {
                  "name"  = "WORDPRESS_DB_HOST"
                  "value" = "wordpress-mysql"
                },
                {
                  "name"      = "WORDPRESS_DB_PASSWORD"
                  "valueFrom" = {
                    "secretKeyRef" = {
                      "key"  = "password"
                      "name" = "mysql-pass"
                    }
                  }
                },
              ]
              "image" = "wordpress:4.8-apache"
              "name"  = "wordpress"
              "ports" = [
                {
                  "containerPort" = 80
                  "name"          = "wordpress"
                },
              ]
              "volumeMounts" = [
                {
                  "mountPath" = "/var/www/html"
                  "name"      = "wordpress-persistent-storage"
                },
              ]
            },
          ]
          "volumes" = [
            {
              "name"                  = "wordpress-persistent-storage"
              "persistentVolumeClaim" = {
                "claimName" = "wp-pv-claim"
              }
            },
          ]
        }
      }
    }
  }
}

resource "time_sleep" "wait_30_seconds_for_service_creation" {
  depends_on = [kubernetes_manifest.service_wordpress]

  create_duration = "30s"
}

data "kubernetes_resource" "service_name" {
  api_version = "v1"
  kind        = "Service"
  metadata {
    name      = "wordpress"
    namespace = "default"
  }

  depends_on = [kubernetes_manifest.service_wordpress,time_sleep.wait_30_seconds_for_service_creation]
}

data "aws_route53_zone" "main" {
  name = "bagbaga-glaa.click"
}

module "route53" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "2.10.2"

  records = [
    {
      name    = "wordpress"
      type    = "CNAME"
      ttl     = 3600
      #      data isn't updated automatically :( shoud refresh state to get the new alb hostname
      records = ["${data.kubernetes_resource.service_name.object.status.loadBalancer.ingress[0].hostname}"]
    }
  ]
  zone_id    = data.aws_route53_zone.main.zone_id
  depends_on = [kubernetes_manifest.service_wordpress]
}

output "test" {
  value = data.kubernetes_resource.service_name.object.status.loadBalancer
}

module "acm" {
  source              = "terraform-aws-modules/acm/aws"
  version             = "4.3.2"
  domain_name         = "wordpress.bagbaga-glaa.click"
  validation_method   = "DNS"
  zone_id             = data.aws_route53_zone.main.zone_id
  wait_for_validation = true
}








