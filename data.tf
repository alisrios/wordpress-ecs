# Data source para o certificado ACM
data "aws_acm_certificate" "certificado" {
  domain   = "*.alisriosti.com.br"
  statuses = ["ISSUED"]
}

# Data source para a prefix list do CloudFront
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}


# Data source para políticas gerenciadas do CloudFront
data "aws_cloudfront_origin_request_policy" "managed_all_viewer" {
  name = "Managed-AllViewer"
}

data "aws_cloudfront_response_headers_policy" "managed_simple_cors" {
  name = "Managed-SimpleCORS"
}
