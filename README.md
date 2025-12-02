# WordPress ECS Infrastructure with Terraform

Infraestrutura completa para WordPress rodando em ECS com Auto Scaling, CloudFront, RDS MySQL e EFS.

## Arquitetura

- **Compute**: ECS com EC2 (ARM64 - t4g.small)
- **Load Balancer**: Application Load Balancer (HTTPS only)
- **CDN**: CloudFront com cache policies customizadas
- **Database**: RDS MySQL 8.0 (db.t4g.micro)
- **Storage**: EFS para arquivos do WordPress
- **Networking**: VPC com subnets públicas e privadas
- **Security**: Security Groups com prefix list do CloudFront

## Estrutura de Arquivos

### Configuração Principal

#### `main.tf`
Configura o provider AWS, backend S3 para state e assume role.

#### `variables.tf`
Define todas as variáveis do projeto organizadas por recurso:
- `tags`: Tags padrão do projeto
- `auth`: Configurações de autenticação AWS
- `vpc`: Configuração completa da VPC e subnets
- `security_groups`: Security groups para ALB, EC2, RDS e EFS
- `alb`: Configuração do Application Load Balancer
- `ecs_cluster`: Nome do cluster ECS
- `ecs_service`: Configuração do serviço ECS
- `ecs_task`: Configuração da task definition
- `asg`: Auto Scaling Group
- `rds`: Configuração do RDS MySQL
- `cloudfront`: Configuração do CloudFront
- `efs`: Configuração do EFS
- `ecr`: Repositório ECR

#### `data.tf`
Data sources para recursos existentes:
- Certificado ACM
- Prefix list do CloudFront
- Políticas gerenciadas do CloudFront (AllViewer, SimpleCORS)

#### `output.tf`
Outputs do Terraform:
- Endpoint do RDS
- DNS do ALB
- Domain name do CloudFront
- Nome do cluster ECS
- VPC ID

### Networking (VPC)

#### `vpc.tf`
Cria a VPC principal com DNS habilitado.

#### `vpc.public-subnets.tf`
Cria subnets públicas em múltiplas AZs usando count.

#### `vpc.private-subnets.tf`
Cria subnets privadas em múltiplas AZs usando count.

#### `vpc.internet-gateway.tf`
Cria o Internet Gateway para acesso à internet.

#### `vpc.public-route-table.tf`
Cria route table pública com rota para o Internet Gateway.

#### `vpc.private-route-table.tf`
Cria route table privada (sem acesso direto à internet).

### Security

#### `security_group.tf`
Define Security Groups:
- **ALB**: HTTPS (443) apenas de IPs do CloudFront (prefix list)
- **EC2**: Todo tráfego do ALB
- **RDS**: MySQL (3306) das instâncias EC2
- **EFS**: NFS (2049) das instâncias EC2

### Load Balancer

#### `alb.tf`
Configura o Application Load Balancer:
- Internet-facing (público)
- Listener HTTPS (443) com certificado ACM
- Target Group para instâncias ECS
- Health checks customizados

### ECS (Elastic Container Service)

#### `ecs_cluster.tf`
Cria o cluster ECS.

#### `ecs_service.tf`
Configura o serviço ECS:
- Integração com ALB
- Capacity provider strategy
- Placement strategy (spread por AZ)
- Deployment configuration

#### `ecs_task_definition.tf`
Define a task definition do WordPress:
- Container WordPress (latest)
- Volume EFS montado em /var/www/html
- Environment variables e secrets do Parameter Store
- CloudWatch Logs
- Runtime platform: ARM64/Linux

#### `ecs_launch_template.tf`
Launch Template para instâncias EC2:
- AMI otimizada para ECS (Amazon Linux 2023 ARM64)
- Instance type: t4g.small
- User data para registrar no cluster
- IAM instance profile

#### `ecs_capacity_provider.tf`
Capacity Provider para auto scaling gerenciado pelo ECS.

### Auto Scaling

#### `asg_ecs.tf`
Auto Scaling Group:
- Min/Desired/Max: 2/2/2
- Subnets públicas
- Lifecycle hooks para draining
- Tags propagadas para instâncias

### Database

#### `rds_db_instance.tf`
RDS MySQL:
- Engine: MySQL 8.0
- Instance class: db.t4g.micro
- Storage: 20GB gp2 encrypted
- Senha gerenciada manualmente (self-managed)
- DB subnet group com subnets privadas

#### `parameter-store.tf`
AWS Systems Manager Parameter Store:
- `/wordpress/db/password` (SecureString)
- `/wordpress/db/username` (String)
- `/wordpress/db/name` (String)

### Storage

#### `efs.tf`
Elastic File System:
- Performance mode: generalPurpose
- Throughput mode: elastic
- Encrypted
- Lifecycle policy: transition to IA após 30 dias
- Mount targets em subnets privadas

### CDN

#### `cloudfront.tf`
CloudFront Distribution:
- Aliases customizados
- Origin: ALB via HTTPS
- **Behaviors**:
  - `/wp-content/*`: Cache longo, CORS habilitado
  - `/wp-admin/*`: Cache com cookies WordPress
  - `/wp-includes/images/blank.gif`: Cache longo
  - Default: Cache padrão com cookies e query strings

#### `cloudfront.cache-policy.wordpress-admin.tf`
Cache policy para área administrativa.

#### `cloudfront.cache-policy.wordpress-default.tf`
Cache policy padrão para WordPress.

#### `cloudfront.cache-policy.wordpress-wp-content.tf`
Cache policy para arquivos estáticos.

#### `cloudfront.origin-request-policy.wordpress-general.tf`
Origin request policy com todos os headers, cookies WordPress e query strings.

### DNS

#### `route53.tf`
Registro Route 53:
- Tipo A com alias para CloudFront
- Domínio: wordpress-tf.alisriosti.com.br

### IAM

#### `iam.ecs-instance-role.tf`
IAM Role para instâncias EC2:
- Permissões para registrar no ECS
- Acesso ao EC2
- SSM para Session Manager

#### `iam.ecs-task-execution-role.tf`
IAM Role para execução de tarefas:
- Baixar imagens do ECR
- Enviar logs para CloudWatch
- Acessar Parameter Store (secrets)
- Descriptografar com KMS

#### `iam.ecs-task-role.tf`
IAM Role para tarefas (aplicação):
- Acesso ao EFS com IAM

### Logs

#### `cloudwatch_log_group.tf`
CloudWatch Log Group para logs do ECS com retenção de 7 dias.

## Variáveis Principais

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

# CloudFront
cloudfront.aliases = ["wordpress-tf.alisriosti.com.br"]
```

## Deploy

```bash
# Inicializar Terraform
terraform init

# Planejar mudanças
terraform plan

# Aplicar infraestrutura
terraform apply

# Destruir infraestrutura
terraform destroy
```

## Segurança

- ✅ ALB aceita apenas tráfego HTTPS do CloudFront (prefix list)
- ✅ Senhas armazenadas no Parameter Store (SecureString)
- ✅ RDS em subnets privadas
- ✅ EFS encrypted
- ✅ Storage RDS encrypted
- ✅ Security Groups com least privilege
- ✅ IAM roles com permissões mínimas

## Custos Estimados (us-east-1)

- **ECS EC2**: 2x t4g.small (~$24/mês)
- **RDS**: 1x db.t4g.micro (~$12/mês)
- **ALB**: ~$16/mês + data transfer
- **EFS**: ~$0.30/GB/mês
- **CloudFront**: Free tier + data transfer
- **NAT Gateway**: Não utilizado (custo zero)

**Total estimado**: ~$55-70/mês (sem tráfego)

## Melhorias Futuras

- [ ] Implementar NAT Gateway para subnets privadas
- [ ] Adicionar CloudWatch Alarms
- [ ] Implementar backup automático do RDS
- [ ] Adicionar WAF no CloudFront
- [ ] Implementar CI/CD pipeline
- [ ] Multi-AZ para RDS
- [ ] Auto Scaling dinâmico baseado em métricas
