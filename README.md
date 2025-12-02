# WordPress ECS Infrastructure with Terraform

Infraestrutura completa para WordPress rodando em ECS com Auto Scaling, CloudFront, RDS MySQL e EFS.

## 🏗️ Arquitetura

- **Compute**: ECS com EC2 (ARM64 - t4g.small)
- **Load Balancer**: Application Load Balancer (HTTPS only)
- **CDN**: CloudFront com cache policies customizadas
- **Database**: RDS MySQL 8.0 (db.t4g.micro)
- **Storage**: EFS para arquivos do WordPress
- **Networking**: VPC com subnets públicas e privadas
- **Security**: Security Groups com prefix list do CloudFront
- **Secrets**: AWS Systems Manager Parameter Store

## 📁 Estrutura de Arquivos

### Configuração Principal

| Arquivo | Descrição |
|---------|-----------|
| `main.tf` | Provider AWS, backend S3 e assume role |
| `variables.tf` | Todas as variáveis organizadas por recurso |
| `data.tf` | Data sources (ACM, CloudFront prefix list, políticas gerenciadas) |
| `output.tf` | Outputs (RDS endpoint, ALB DNS, CloudFront domain, etc) |

### 🌐 Networking (VPC)

| Arquivo | Descrição |
|---------|-----------|
| `vpc.tf` | VPC principal com DNS habilitado |
| `vpc.public-subnets.tf` | Subnets públicas (2 AZs) usando count |
| `vpc.private-subnets.tf` | Subnets privadas (2 AZs) usando count |
| `vpc.internet-gateway.tf` | Internet Gateway |
| `vpc.public-route-table.tf` | Route table pública com rota para IGW |
| `vpc.private-route-table.tf` | Route table privada |

**CIDR Blocks:**
- VPC: `10.0.0.0/16`
- Public Subnets: `10.0.0.0/20`, `10.0.16.0/20`
- Private Subnets: `10.0.128.0/20`, `10.0.144.0/20`

### 🔒 Security

| Arquivo | Descrição |
|---------|-----------|
| `security_group.tf` | Security Groups para ALB, EC2, RDS e EFS |

**Security Groups:**
- **ALB**: HTTPS (443) apenas de IPs do CloudFront (prefix list)
- **EC2**: Todo tráfego (0-65535) do ALB
- **RDS**: MySQL (3306) das instâncias EC2
- **EFS**: NFS (2049) das instâncias EC2

### ⚖️ Load Balancer

| Arquivo | Descrição |
|---------|-----------|
| `alb.tf` | ALB internet-facing, listener HTTPS, target group |

**Configuração:**
- Tipo: Internet-facing
- Listener: HTTPS (443) com certificado ACM
- Target Group: HTTP (80) para instâncias ECS
- Health Check: `/` com matcher `200,301,302`

### 🐳 ECS (Elastic Container Service)

| Arquivo | Descrição |
|---------|-----------|
| `ecs_cluster.tf` | Cluster ECS |
| `ecs_service.tf` | Serviço ECS com integração ALB |
| `ecs_task_definition.tf` | Task definition do WordPress |
| `ecs_launch_template.tf` | Launch template para instâncias EC2 |
| `ecs_capacity_provider.tf` | Capacity provider para auto scaling |

**Task Definition:**
- Container: `wordpress:latest`
- CPU: 1024
- Memory Reservation: 410 MB
- Port: 80
- Volume EFS: `/var/www/html`
- Secrets: Parameter Store (DB credentials)
- Logs: CloudWatch

### 📈 Auto Scaling

| Arquivo | Descrição |
|---------|-----------|
| `asg_ecs.tf` | Auto Scaling Group com lifecycle hooks |

**Configuração:**
- Min/Desired/Max: 2/2/2
- Subnets: Públicas
- Instance Type: t4g.small (ARM64)
- Lifecycle Hook: Draining ao terminar

### 🗄️ Database

| Arquivo | Descrição |
|---------|-----------|
| `rds_db_instance.tf` | RDS MySQL e DB subnet group |
| `parameter-store.tf` | Parameter Store para secrets |

**RDS:**
- Engine: MySQL 8.0
- Instance: db.t4g.micro
- Storage: 20GB gp2 encrypted
- Multi-AZ: Desabilitado
- Subnets: Privadas
- Senha: Self-managed via Parameter Store

**Parameter Store:**
- `/wordpress/db/password` (SecureString)
- `/wordpress/db/username` (String)
- `/wordpress/db/name` (String)

### 💾 Storage

| Arquivo | Descrição |
|---------|-----------|
| `efs.tf` | EFS file system e mount targets |

**Configuração:**
- Performance: generalPurpose
- Throughput: elastic
- Encrypted: Sim
- Lifecycle: Transition to IA após 30 dias
- Mount Targets: Subnets privadas

### 🌍 CDN (CloudFront)

| Arquivo | Descrição |
|---------|-----------|
| `cloudfront.tf` | CloudFront distribution |
| `cloudfront.cache-policy.wordpress-admin.tf` | Cache policy para wp-admin |
| `cloudfront.cache-policy.wordpress-default.tf` | Cache policy padrão |
| `cloudfront.cache-policy.wordpress-wp-content.tf` | Cache policy para wp-content |
| `cloudfront.origin-request-policy.wordpress-general.tf` | Origin request policy |

**Behaviors (ordem de precedência):**

| Precedência | Path Pattern | Cache Policy | Origin Request | Response Headers | Allowed Methods |
|-------------|--------------|--------------|----------------|------------------|-----------------|
| 0 | `/wp-login.php` | wordpress-admin-tf | wordpress-general-tf | - | ALL |
| 1 | `/wp-admin/*` | wordpress-admin-tf | wordpress-general-tf | - | ALL |
| 2 | `/wp-json/*` | wordpress-default-tf | wordpress-general-tf | - | ALL |
| 3 | `/wp-content/*` | wordpress-wp-content-tf | - | Managed-SimpleCORS | GET, HEAD, OPTIONS |
| 4 | `/wp-includes/images/blank.gif` | wordpress-wp-content-tf | - | - | GET, HEAD |
| 5 (Default) | `*` | wordpress-default-tf | wordpress-general-tf | - | ALL |

**Legenda:**
- **ALL**: DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT
- Behaviors 0-2: Sem cache ou cache mínimo (áreas administrativas e API)
- Behaviors 3-4: Cache longo (arquivos estáticos)
- Behavior 5: Cache padrão (páginas WordPress)

**Cache Policies:**
- **wordpress-wp-content-tf**: 
  - TTL: min=1s, default=86400s (1 dia), max=31536000s (1 ano)
  - Headers: Origin, Access-Control-Request-Method, Access-Control-Request-Headers, Host
  - Cookies: None
  - Query Strings: None
  - Compression: Gzip + Brotli

- **wordpress-admin-tf**: 
  - TTL: min=0s, default=1s, max=1s (cache mínimo)
  - Headers: Origin, Referer, Host
  - Cookies: wordpress-test-cookie, wordpress_*, comment_author*, wp-settings*
  - Query Strings: All
  - Compression: Gzip + Brotli

- **wordpress-default-tf**: 
  - TTL: min=1s, default=600s (10 min), max=31536000s (1 ano)
  - Headers: Origin, Referer, Host
  - Cookies: wordpress_test_cookie, wordpress_*, comment_author*, wp-settings*
  - Query Strings: All
  - Compression: Gzip + Brotli

**Origin Request Policy:**
- **wordpress-general-tf**:
  - Headers: All viewer headers
  - Cookies: wordpress_test_cookie, wordpress_*, comment_author*, wp-settings*, elementor_*
  - Query Strings: All

### 🌐 DNS

| Arquivo | Descrição |
|---------|-----------|
| `route53.tf` | Registro Route 53 tipo A com alias |

**Configuração:**
- Tipo: A (alias para CloudFront)
- Domínio: `wordpress-tf.alisriosti.com.br`
- Zone: `alisriosti.com.br`

### 👤 IAM

| Arquivo | Descrição |
|---------|-----------|
| `iam.ecs-instance-role.tf` | Role para instâncias EC2 do ECS |
| `iam.ecs-task-execution-role.tf` | Role para execução de tarefas |
| `iam.ecs-task-role.tf` | Role para tarefas (aplicação) |

**Permissões:**
- **Instance Role**: ECS, EC2, SSM
- **Task Execution Role**: ECR, CloudWatch Logs, Parameter Store, KMS
- **Task Role**: EFS com IAM

### 📊 Logs

| Arquivo | Descrição |
|---------|-----------|
| `cloudwatch_log_group.tf` | Log group para ECS |

**Configuração:**
- Log Group: `/ecs/task-def-wordpress-tf`
- Retenção: 7 dias

## 🚀 Deploy

```bash
# Inicializar Terraform
terraform init

# Validar configuração
terraform validate

# Planejar mudanças
terraform plan

# Aplicar infraestrutura
terraform apply

# Destruir infraestrutura
terraform destroy
```

## 🔐 Segurança

- ✅ ALB aceita apenas tráfego HTTPS do CloudFront (prefix list)
- ✅ Senhas armazenadas no Parameter Store (SecureString)
- ✅ RDS em subnets privadas
- ✅ EFS encrypted
- ✅ Storage RDS encrypted
- ✅ Security Groups com least privilege
- ✅ IAM roles com permissões mínimas
- ✅ Sem listener HTTP no ALB
- ✅ CloudFront força HTTPS (redirect-to-https)

## 💰 Custos Estimados (us-east-1)

| Recurso | Especificação | Custo Mensal |
|---------|---------------|--------------|
| ECS EC2 | 2x t4g.small | ~$24 |
| RDS MySQL | 1x db.t4g.micro | ~$12 |
| ALB | 1x ALB + data transfer | ~$16 |
| EFS | ~1GB | ~$0.30 |
| CloudFront | Free tier + data transfer | ~$0-5 |
| Parameter Store | 3 parâmetros | Grátis |
| Route 53 | 1 hosted zone | ~$0.50 |

**Total estimado**: ~$55-70/mês (sem tráfego significativo)

## 📝 Variáveis Principais

```hcl
# Tags do projeto
tags = {
  Environment = "production"
  Project     = "wordpress-ecs-tf"
}

# Cluster ECS
ecs_cluster.name = "cluster-wordpress-ecs-tf"

# RDS
rds.identifier = "db-wordpress-tf"
rds.engine = "mysql"
rds.engine_version = "8.0"
rds.username = "wordpress"
rds.database_name = "wordpress"

# CloudFront
cloudfront.aliases = ["wordpress-tf.alisriosti.com.br"]

# VPC
vpc.cidr_block = "10.0.0.0/16"
```

## 🎯 Recursos Criados

- 1x VPC
- 2x Subnets Públicas
- 2x Subnets Privadas
- 1x Internet Gateway
- 2x Route Tables
- 4x Security Groups
- 1x Application Load Balancer
- 1x Target Group
- 1x ECS Cluster
- 1x ECS Service
- 1x ECS Task Definition
- 1x Auto Scaling Group
- 2x EC2 Instances (t4g.small)
- 1x RDS MySQL Instance
- 1x EFS File System
- 2x EFS Mount Targets
- 1x CloudFront Distribution
- 4x CloudFront Cache Policies
- 1x CloudFront Origin Request Policy
- 1x Route 53 Record
- 3x Parameter Store Parameters
- 1x CloudWatch Log Group
- 6x IAM Roles
- 1x Launch Template

## 🔄 Melhorias Futuras

- [ ] Implementar NAT Gateway para subnets privadas
- [ ] Adicionar CloudWatch Alarms (CPU, Memory, Health)
- [ ] Implementar backup automático do RDS
- [ ] Adicionar AWS WAF no CloudFront
- [ ] Implementar CI/CD pipeline (CodePipeline)
- [ ] Multi-AZ para RDS (alta disponibilidade)
- [ ] Auto Scaling dinâmico baseado em métricas
- [ ] Implementar AWS Secrets Manager em vez de Parameter Store
- [ ] Adicionar CloudWatch Container Insights
- [ ] Implementar AWS Backup para EFS

## 📚 Referências

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Amazon ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [CloudFront Cache Policies](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/controlling-the-cache-key.html)
- [WordPress on AWS](https://aws.amazon.com/getting-started/hands-on/launch-a-wordpress-website/)
