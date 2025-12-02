# CloudFront Distribution
resource "aws_cloudfront_distribution" "this" {
  aliases             = var.cloudfront.aliases
  comment             = var.cloudfront.aliases[0]
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = true
  price_class         = var.cloudfront.price_class
  wait_for_deployment = true

  # Behavior 0: /wp-login.php - Login do WordPress (sem cache)
  ordered_cache_behavior {
    path_pattern           = "/wp-login.php"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "wordpress-alb"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = aws_cloudfront_cache_policy.wordpress_admin.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.wordpress_general.id
  }

  # Behavior 1: /wp-admin/* - Área administrativa do WordPress (sem cache)
  ordered_cache_behavior {
    path_pattern           = "/wp-admin/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "wordpress-alb"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = aws_cloudfront_cache_policy.wordpress_admin.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.wordpress_general.id
  }

  # Behavior 2: /wp-json/* - REST API do WordPress
  ordered_cache_behavior {
    path_pattern           = "/wp-json/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "wordpress-alb"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = aws_cloudfront_cache_policy.wordpress_default.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.wordpress_general.id
  }

  # Behavior 3: /wp-content/* - Arquivos estáticos do WordPress (cache longo)
  ordered_cache_behavior {
    path_pattern               = "/wp-content/*"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "wordpress-alb"
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
    cache_policy_id            = aws_cloudfront_cache_policy.wordpress_wp_content.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.managed_simple_cors.id
  }

  # Behavior 4: /wp-includes/images/blank.gif - Imagem específica (cache longo)
  ordered_cache_behavior {
    path_pattern           = "/wp-includes/images/blank.gif"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "wordpress-alb"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = aws_cloudfront_cache_policy.wordpress_wp_content.id
  }

  # Behavior 5 (Default): Comportamento padrão para todo o resto
  default_cache_behavior {
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "wordpress-alb"
    viewer_protocol_policy   = "redirect-to-https"
    compress                 = true
    cache_policy_id          = aws_cloudfront_cache_policy.wordpress_default.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.wordpress_general.id
  }

  # Origin - ALB público (internet-facing)
  origin {
    domain_name = aws_lb.this.dns_name
    origin_id   = "wordpress-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = var.alb.listener.https_port
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Restrições geográficas
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Certificado SSL
  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.certificado.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cloudfront.aliases[0]}-cdn"
    }
  )
}
