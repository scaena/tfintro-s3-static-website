module "hml" {
  source = "./modules/static-site"

  name                   = "tfintro-hml"
  domain_name            = var.domain_name
  route53_hosted_zone_id = var.route53_hosted_zone_id
}

module "prd" {
  source = "./modules/static-site"

  name                   = "tfintro"
  domain_name            = var.domain_name
  route53_hosted_zone_id = var.route53_hosted_zone_id
}
