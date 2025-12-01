# Busca o certificado ACM para o domínio principal
# Recurso de dados: aws_acm_certificate
# Obtém o certificado emitido para *.alisriosti.com.br
data "aws_acm_certificate" "certificado" {
  domain   = "*.alisriosti.com.br"
  statuses = ["ISSUED"]
}
