# Introdução ao Terraform

Este repositório contem alguns passos introdutórios para a ferramenta Terraform. Ele é baseado
somente na versão 0.14.5 livre da ferramenta que pode ser obtida gratuitamente.

## Preparação do ambiente

Este repo foi criado com a intenção de ser usado em palestras introdutórias do Terraform, mas é público justamente para que as pessoas possam tentar reproduzir os passos em uma conta pessoal AWS. Note que existem custos para estas simulações, em particular em relação a um domínio registrado dentro da AWS (US$ 11,00/ano + US$ 1,0/mês). Dois registros DNS dentro desse domínio serão criados e também dois buckets públicos (que não devem ser usados para armazenar informações sensíveis!), seu custo é negligênciável e possível beirem a US$ 0,01.

Domínios registrados externamente na AWS não vão funcionar para o teste.

Para desenvolver os passos você precisa:

- Instalar o Terraform, uma ferramenta de command line, conforme dito na introdução acima a versão usada foi a 0.14.5 e recomenda-se que ela seja a usada para evitar possíveis incompatibilidades : https://www.terraform.io/downloads.html.
- Uma conta AWS para testes.
- Um domínio DNS registrado no Route 53 dessa conta, para o teste que vamos fazer será usado o domínio do auto `valterlisboa.net`. Observe os comentários sobre custo
- Para facilitar as coisas é recomendado que a variável de ambiente abaixo seja setada antes de começar. Isso vai forçar a usar a região da virgínia, que é mais barata do que  a do Brasil e possui todas as opções disponíveis de produtos AWS em General Availability:

```
export AWS_REGION=us-east-1
```

## Resultado

A ideia aqui é seguir um passo a passo que vai mostrar como usar o Terraform para criar buckets S3 que publicam sites estáticos. O AWS S3 é um serviço da AWS usado para armazenamento de objetos muito popular e uma de suas features é ser capaz de servir como um serviço HTTP simples para fornecer arquivos HTML, ou mesmo Single Page Applications (SPA). Associado ao bucket iremos registrar dentro de um domínio um registro DNS para este site, que irá resolver o endereço do bucket. Isso será feito duas vezes, uma para um ambiente hipotético de homologação e outro de produção. 

Existem muitas outras maneiras de publicar páginas estáticas ou SPA na AWS, a que está sendo usado neste exemplo não possui suporte a HTTPS, portanto não deve ser usada em ambientes produtivos que requerem segurança, mas ela é simples o suficiente para servir de instrumento para o hands on. O foco aqui é demonstrar um pouco como o Terraform funciona e não aprender a usar AWS em toda sua magnitude, no entanto, é interessante observar como os serviços se interconectam entre si para criar uma solução e o caso se presta a demostrar isso.

## Arquivos e diretórios

Além desta documentação existem dois diretórios dentro do repo, o primeiro `sample-static-site` possui dois arquivos HTML bem simples (a ideia aqui é se concentrar no Terraform e não em uma aplicação web), eles serão usados como exemplo para deploy nos buckets. 

O segundo é o `sample-iac-complete` é o resultado final desejado a ser alcançado pelo hands-on, ele é mais uma referência do que qualquer outra coisa, no entanto é totalmente funcional. 

## Passo a passo

```bash
$ mkdir hands-on
```

### Inicializando um root module

Arquivo `hands-on/main.tf`:

```terraform
terraform {
  required_version = "~> 0.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {}
```

```bash
$ terraform init
```

### Criando um bucket

[Documentação do Provider AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)

[Documentação do resource para buckets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)

Arquivo `hands-on/bucket.tf`

```terraform
resource "aws_s3_bucket" "this" {
  bucket        = "tfintro-hml.valterlisboa.net"
  acl           = "public-read"
  force_destroy = true
}
```

```bash
$ terraform validate
$ terraform plan 
```

```bash
$ terraform apply -auto-approve
```

```terraform
resource "aws_s3_bucket" "this" {
  bucket        = "tfintro-hml.valterlisboa.net"
  acl           = "public-read"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}
```

```bash
$ terraform validate
$ terraform plan 
```

```bash
$ terraform apply -auto-approve
```

### Associando um registro DNS ao bucket

Arquivo `hands-on/dns.tf`:

```terraform
resource "aws_route53_record" "this" {
  zone_id = "XXXXXXXXXXXXXXXXXXXXXXXX"
  name    = "tfintro-hml.valterlisboa.net"
  type    = "A"

  alias {
    name                   = aws_s3_bucket.this.website_domain
    zone_id                = aws_s3_bucket.this.hosted_zone_id
    evaluate_target_health = false
  }
}
```

```bash
$ terraform validate
$ terraform plan 
```

```bash
$ terraform apply -auto-approve
```

### Criando variáveis

Arquivo `hands-on/variables.tf`

```terraform
variable "domain_name" {
  type        = string
  description = "The DNS domain name"
}

variable "route53_hosted_zone_id" {
  type        = string
  description = "The unique ID for the Route 53 zone to register records"
}
```

Arquivo `hands-on/terraform.tfvars`:

```terraform
domain_name = "valterlisboa.net"
route53_hosted_zone_id = "XXXXXXXXXXXXXXXXXXXXX"
```

Arquivo `hands-on/bucket.tf`:

```terraform
resource "aws_s3_bucket" "this" {
  bucket        = "tfintro-hml.${var.domain_name}"
  acl           = "public-read"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}
```

Arquivo `hands-on/dns.tf`:

```terraform
resource "aws_route53_record" "this" {
  zone_id = var.route53_hosted_zone_id
  name    = "tfintro-hml.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_s3_bucket.this.website_domain
    zone_id                = aws_s3_bucket.this.hosted_zone_id
    evaluate_target_health = false
  }
}
```

```bash
$ terraform validate
$ terraform plan 
```

### Fazendo deploy do bucket

