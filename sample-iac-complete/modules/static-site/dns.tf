resource "aws_route53_record" "this" {
  zone_id = var.route53_hosted_zone_id
  name    = "${var.name}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_s3_bucket.this.website_domain
    zone_id                = aws_s3_bucket.this.hosted_zone_id
    evaluate_target_health = false
  }
}
