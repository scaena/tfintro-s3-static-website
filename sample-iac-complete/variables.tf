variable "domain_name" {
  type        = string
  description = "The DNS domain name to register records for the sites"
}

variable "route53_hosted_zone_id" {
  type        = string
  description = "The Route 53 hosted zone uinique indetifiable to register DNS for the buckets"
}

