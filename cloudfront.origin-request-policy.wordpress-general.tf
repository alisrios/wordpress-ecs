# Origin Request Policy para WordPress
resource "aws_cloudfront_origin_request_policy" "wordpress_general" {
  name    = "wordpress-general-tf"
  comment = "Origin request policy para WordPress com cookies e query strings"

  cookies_config {
    cookie_behavior = "whitelist"
    cookies {
      items = [
        "wordpress_test_cookie",
        "wordpress_*",
        "comment_author*",
        "wp-settings*",
        "elementor_*"
      ]
    }
  }

  headers_config {
    header_behavior = "allViewer"
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}
