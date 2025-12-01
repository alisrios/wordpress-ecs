data "aws_route53_zone" "primary" {
  name = "alisriosti.com.br"
}

resource "aws_route53_record" "wordpress_tf" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "wordpress-tf.alisriosti.com.br"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}
