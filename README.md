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

Antes de mais nada é necessário criar o diretório `hands-on` para que possamos fazer alterações sem poluir o repositório. Note que o .gitignore que o autor criou não leva este diretório em conta e se você quiser fazer um fork e commitar suas alterações é necessário usar outro nome ou editar o .gitignore.

```bash
$ mkdir hands-on
$ cd hands-on
```

### Inicializando um root module

O Terraform possui o conceito de modules (módulos), por padrão ele separa tudo por diretórios e o diretório onde executamos os comandos é chamado de *root module* (módulo raiz). O diretório `hands-on` será nosso root module e portanto ele deve possui os arquivos de configuração do próprio Terraform assim como as configurações dos **providers**. 

Um provider é um plugin que o terraform baixa localmente ao executar alguns comandos para que ele possa interagir com seus alvos que em geral são algo baseados em API como nuvens públicas ou privadas, SaaS e serviços de rede. É possível pesquisar, navegar e escolher providers no [portal da Hashicorp destinado a este fim](https://registry.terraform.io/browse/providers).

Crie o arquivo `hands-on/main.tf` conforme abaixo:

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

Estes valores serão explicados durante a apresentação, para validar e inicializar tudo rode o comando abaixo.

```bash
$ terraform init
```

### Criando um bucket

Uma vez que root module estiver pré configurado é hora de começar a declarar o código de Terraform para criar nosso bucket. A [Documentação do Provider AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) possui toda as informações de resources (declaração que alteram a nuvem), data sources (itens que retornam informações da nuvem), etc. Mais especificamente vamos usar o [resource que cria buckets dentro do serviço S3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket).

Crie o arquivo `hands-on/bucket.tf`, durante a apresentação serão explicados os parâmetros e syntax.

```terraform
resource "aws_s3_bucket" "this" {
  bucket        = "tfintro-hml.valterlisboa.net"
  acl           = "public-read"
  force_destroy = true
}
```

Para poder validar as alterações sempre use estes dois comandos abaixo. O primeiro valida a sintaxe e o segundo se comunica com a nuvem e mostra um *diff* entre o ambiente atual, a declaração que fizemos e o state do Terraform (mais informação do último abaixo).

```bash
$ terraform validate
$ terraform plan 
```

Uma vez que esteja contente com o resulatdo do plan é possível aplicar as alterações com o comando `apply` abaixo. Além de alterar a nuvem criando o bucket, ele também irá gerar (ou atualizar se já existir) um arquivo `terraform.tfstate` que armazenará o state (estado) das execuções do Terraform. Este arquivo não deve ser commitado no git pois pode conter informações sensíveis, por isso é recomendado que ele seja armazenado em um registry de state remoto. Não vamos entrar em detalhes neste assunto na apresentação, para o exemplo um tfstate local é suficiente.

```bash
$ terraform apply -auto-approve
```

Durante a apresentação perceba que o bucket não está com o suporte a website ativo, então precisamos alterar o arquivo e aplicar o mesmo procedimento acima. Este processo de alterar/validate/plan/apply é similar à doutrina de TDD e sempre deve ser seguido, óbviamente atrelado a comandos git de add/commit/push. Isso garante que as alterações sempre serão revisadas (ao menos manualmente).

Altere o arquivo `hands-on/bucket.tf` conforme abaixo acrescentando o bolco `website`. Os detalhes de seus parâmetros serão discutidos durante a apresentação.

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

Novamente valide as alterações.

```bash
$ terraform validate
$ terraform plan 
```

E então aplique-as quando satisfeito. Em casos de erros nos comandos acima, ou de alterações indesejadas altere os arquivos e use o validate/plan até que tudo esteja em ordem. Nunca applique alterações que possam causar indisponibilidade ou perda de dados!!!

```bash
$ terraform apply -auto-approve
```
### Fazendo deploy no bucket

Fazer deploy manualmente em um bucket S3 com website estático é uma questão de fazer sync entre o diretório que possui os arquivos e o bucket.

```bash
$ aws s3 sync ../sample-static-site/ s3://tfintro-hml.valterlisboa.net --acl public-read
```

Durante a apresentação veremos como acessar o site. É importante notar que não configuramos nada redeferente a web servers além do que foi declarado, o S3 é um serviço serverless e não requer acesso ao seu S.O. rodando por debaixo dele para uso, de fato, nem é possível acessá-lo.

### Associando um registro DNS ao bucket

Embora o bucket esteja funcional, vamos deixar ele mais vistoso acrescentando um domínio DNS ao mesmo. Isso requer o domínio citado na introdução anteriormente dentro do Route 53, que nada mais é do que um serviço gerenciado (também serverless como o S3) para domínios públicos ou privados, estremamente acoplável com uma pletora de outros serviços AWS.

Durante a apresentação a documentação do recurso record será acessada e você deve criar o arquivo `hands-on/dns.tf` conforme abaixo:

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

Isso vai criar um registro Alias (também discutido na apresentação), do bucket para o domínio. Note que no `zone_id` acima foi omitido o ID real da hosted zone usada no exemplo. Atenção extra as interpolações e valores obtidos do resource `aws_s3_bucket`, essa parte é muito importante.

Depois disso voltamos ao processo já executado anteriormente de validação.

```bash
$ terraform validate
$ terraform plan 
```

E aplicação se tudo estiver correto.

```bash
$ terraform apply -auto-approve
```

Acessar http://tfintro-hml.valterlisboa.net para testar, substituindo o domínio pelo seu registrado na AWS caso esteja fazendo dentro de sua conta. 

### Criando variáveis

Um passo importante é externalizar valores de dentro de nosso root module de forma que seja possível optar por eles, isso torna os modules mais genéricos e reutilizaveis. Para nosso propósito vamos externalizar um valor que se repete ao longo de múltiplos ambientes que o é o domínio DNS (usado em ambos resources acima) e outro que é relativamente sensível pois é um ID interno da nossa conta AWS.

Crie o arquivo `hands-on/variables.tf` conforme abaixo:

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

Para facilitar nossa vida e como estamos rodando um Terraform localmente, vamos criar um arquivo que vai alimentar os variables acima. O ideal é que este arquivo **não seja commitado no git**. De fato, o ideal é usar orquestradores como Terraform Cloud para armazenamento destes valores, para nosso exemplo vamos simplesmente armazenar ele localmente (o .gitignore também o está ignorando).

Crie o arquivo `hands-on/terraform.tfvars` conforme abaixo:

```terraform
domain_name = "valterlisboa.net"
route53_hosted_zone_id = "XXXXXXXXXXXXXXXXXXXXX"
```

E altere os arquivos `hands-on/bucket.tf` e `hands-on/dns.tf` para receber as variables no lugar dos valores hard coded:

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

Repita o já conhecido processo de validate/plan e veja que não houve alterações, pois os valores substituidos batem com os estáticos anteriores.

```bash
$ terraform validate
$ terraform plan 
```

### Criando um módulo comum para homologação e produção

Infra as Code no terraform só faz sentido se reusarmos os modules, agora vamos faezr um exercício relativamente mais avançado alterando o código para incluir um module em um sub diretório e chamá-lo múltiplas vezes para criar os ambientes de homologação e produção.

Primeiro crie o diretório conforme abaixo e mova os arquivos que contém os resources.

```bash
mkdir -p modules/static-site
mv bucket.tf dns.tf modules/static-site/
```

Crie o arquivo `hands-on/modules/static-site/variables.tf` conforme abaixo, ele é similar ao `variables.tf` do root module mas possui uma variable a mais:

```terraform
variable "name" {
  type        = string
  description = "The site name to be pretended to the domain to compose the URL"
}

variable "domain_name" {
  type        = string
  description = "The DNS domain name"
}

variable "route53_hosted_zone_id" {
  type        = string
  description = "The unique ID for the Route 53 zone to register records"
}
```

Altere os arquivo `hands-on/modules/static-site/bucket.tf` e `hands-on/modules/static-site/dns.tf` conforme abaixo, os detalhes disto serão discutidos na apresentação:

```terraform
resource "aws_s3_bucket" "this" {
  bucket        = "${var.name}.${var.domain_name}"
  acl           = "public-read"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}
```

```terraform
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
```

No root module crie o arquivo `hands-on/environments.tf` para chamar o module que criamos.

```terraform
module "hml" {
  source = "./modules/static-site"

  name                   = "tfintro-hml"
  domain_name            = var.domain_name
  route53_hosted_zone_id = var.route53_hosted_zone_id
}
```

Repare no parâmetro `source`, ele aponta para o diretório que criamos. Também os outros parâmetros nada mais são do que os variables. Para que possamos atualizar os mapas de referências de módulos use o comando `get` abaixo:

```bash
$ terraform get
```

E novamente execute os comandos de teste

```bash
$ terraform validate
$ terraform plan 
```

A saída é um pouco preocupante, mas não se aflija, durante a apresentação isso vai ser discutido em detalhes pois o plan está dizendo que resources serão destruídos. Depois da explicação os comandos abaixo vão corrigir o state movendo os resources do root module para o sub module.

```bash
$ terraform state mv 'aws_route53_record.this' 'module.hml.aws_route53_record.this'
$ terraform state mv 'aws_s3_bucket.this' 'module.hml.aws_s3_bucket.this'
```

Agora podemos verificar que o `plan` não mais indica mudanças.

```bash
$ terraform plan 
```

Finalmente vamos criar o ambiente de produção editando o arquivo `hands-on/environments.tf` conforma abaixo:

```terraform
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
```

Como é um novo module referenciado é preciso executar `get` antes do tradicional check.

```bash
$ terraform get
$ terraform validate
$ terraform plan 
```

E aplicamos e criamos produção.

```bash
$ terraform apply -auto-approve
```

Veja que a partir de agora se precisarmos repetir o processo para diferentes sites é uma questão de repetir o o código com names diferentes. Vamos fazer deploy em produção para testar.

```bash
$ aws s3 sync ../sample-static-site/ s3://tfintro.valterlisboa.net --acl public-read
```

Acessar http://tfintro.valterlisboa.net para testar, substituindo o domínio pelo seu registrado na AWS caso esteja fazendo dentro de sua conta. 
