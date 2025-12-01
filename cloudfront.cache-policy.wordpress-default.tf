# Cache Policy padrão para WordPress
resource "aws_cloudfront_cache_policy" "wordpress_default" {
  name        = "Cache-Wordpress-Default-tf"
  comment     = "Policy padrão para WordPress com cookies e query strings"
  default_ttl = 600
  max_ttl     = 31536000
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    # Headers
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Origin", "Referer", "Host"]
      }
    }

    # Cookies
    cookies_config {
      cookie_behavior = "whitelist"
      cookies {
        items = ["wordpress_test_cookie", "wordpress_*", "comment_author*", "wp-settings*"]
      }
    }

    # Query strings
    query_strings_config {
      query_string_behavior = "all"
    }

    # Compression
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}
