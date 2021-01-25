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

## Passo a passo

```bash
$ mkdir hands-on
```

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

