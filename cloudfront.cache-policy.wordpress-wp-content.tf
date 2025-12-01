# Cache Policy para wp-content (arquivos estáticos do WordPress)
resource "aws_cloudfront_cache_policy" "wordpress_wp_content" {
  name        = "Cache-Wordpress-wp-content-tf"
  comment     = "Policy para wp-content com cache longo"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    # Headers
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers", "Host"]
      }
    }

    # Cookies
    cookies_config {
      cookie_behavior = "none"
    }

    # Query strings
    query_strings_config {
      query_string_behavior = "none"
    }

    # Compression
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}
