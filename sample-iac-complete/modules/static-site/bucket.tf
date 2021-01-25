resource "aws_s3_bucket" "this" {
  bucket        = "${var.name}.${var.domain_name}"
  acl           = "public-read"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}
