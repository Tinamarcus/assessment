apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tina-ingress
  namespace: tina-ns
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
%{ if acm_certificate_arn != "" ~}
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/certificate-arn: '${acm_certificate_arn}'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
%{ else ~}
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
%{ endif ~}
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: tina-service
            port:
              number: 80