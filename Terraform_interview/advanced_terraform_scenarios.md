# Advanced Terraform Scenario-Based Interview Questions

## 🎯 Unique & Challenging Scenarios Not Typically Covered

### **Scenario 1: Cross-Account Resource Dependencies**
**Question:** "You have Terraform managing resources across multiple AWS accounts. In Account A, you have a VPC, and in Account B, you need to peer with that VPC. However, the VPC ID from Account A needs to be shared with Account B's Terraform configuration. How would you handle this cross-account dependency without hardcoding values?"

**Expected Answer:**
- Use remote state data sources with cross-account S3 bucket access
- Implement Systems Manager Parameter Store or AWS Secrets Manager for cross-account sharing
- Use Terraform Cloud/Enterprise workspaces with variable sets
- Explain IAM roles and cross-account trust relationships

```hcl
# Account A - outputs VPC ID to remote state
output "vpc_id" {
  value = aws_vpc.main.id
}

# Account B - consumes from Account A's remote state
data "terraform_remote_state" "account_a" {
  backend = "s3"
  config = {
    bucket         = "shared-terraform-state-bucket"
    key            = "account-a/vpc/terraform.tfstate"
    region         = "us-west-2"
    role_arn       = "arn:aws:iam::ACCOUNT-A:role/TerraformCrossAccountRole"
  }
}

resource "aws_vpc_peering_connection" "peer" {
  peer_vpc_id = data.terraform_remote_state.account_a.outputs.vpc_id
  vpc_id      = aws_vpc.main.id
}
```

---

### **Scenario 2: Terraform State Corruption Recovery**
**Question:** "During a terraform apply, the process was interrupted due to network issues, and now your state file shows partial updates. Some resources were created in AWS but not reflected in the state file, while others are in an inconsistent state. How do you recover from this situation without losing any existing infrastructure?"

**Expected Answer:**
- Use `terraform refresh` to sync state with real infrastructure
- Manually import missing resources using `terraform import`
- Use `terraform state mv` and `terraform state rm` for cleanup
- Implement state backup and recovery procedures

```bash
# Step-by-step recovery process
# 1. Backup current state
terraform state pull > backup-$(date +%Y%m%d-%H%M%S).tfstate

# 2. Identify missing resources
aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`]'

# 3. Import missing resources
terraform import aws_instance.web i-1234567890abcdef0

# 4. Refresh to sync state
terraform refresh

# 5. Validate and plan
terraform plan
```

---

### **Scenario 3: Dynamic Resource Scaling Based on External Conditions**
**Question:** "You need to create a Terraform configuration that dynamically scales the number of EC2 instances based on the current time of day (more instances during business hours) and external API data (current load metrics). How would you implement this dynamic scaling without using Auto Scaling Groups?"

**Expected Answer:**
- Use external data sources to fetch current metrics
- Implement local-exec provisioners with API calls
- Use count or for_each with dynamic calculations
- Explain limitations and better alternatives (ASG, Lambda-triggered updates)

```hcl
# External data source to get current load metrics
data "external" "current_load" {
  program = ["python3", "${path.module}/scripts/get_load_metrics.py"]
}

# Local values for dynamic calculation
locals {
  current_hour = formatdate("HH", timestamp())
  is_business_hours = local.current_hour >= 9 && local.current_hour <= 17
  base_instance_count = 2
  business_hour_multiplier = 2
  load_multiplier = ceil(tonumber(data.external.current_load.result.cpu_percent) / 25)
  
  total_instances = local.is_business_hours ? 
    (local.base_instance_count * local.business_hour_multiplier * local.load_multiplier) : 
    local.base_instance_count
}

resource "aws_instance" "dynamic_web" {
  count = local.total_instances
  
  ami           = data.aws_ami.latest.id
  instance_type = "t3.micro"
  
  tags = {
    Name = "dynamic-web-${count.index + 1}"
    ScalingReason = "Hour:${local.current_hour}, Load:${data.external.current_load.result.cpu_percent}%"
  }
}
```

---

### **Scenario 4: Zero-Downtime Blue-Green Deployment with Terraform**
**Question:** "Your company wants to implement blue-green deployments using Terraform. You have a production environment serving traffic, and you need to deploy a new version with zero downtime. The challenge is that you can't use managed services like ELB target groups switching. How would you orchestrate this with Terraform?"

**Expected Answer:**
- Use Terraform workspaces or separate state files for blue/green environments
- Implement DNS switching mechanism (Route53 weighted routing)
- Use null_resource with provisioners for orchestration
- Explain rollback strategies and health checks

```hcl
# Blue-Green deployment with DNS switching
variable "environment_color" {
  description = "blue or green"
  type        = string
}

variable "traffic_weight" {
  description = "Traffic weight for this environment"
  type        = number
  default     = 0
}

# Application infrastructure
resource "aws_instance" "app" {
  count = 3
  ami   = var.ami_id
  instance_type = "t3.medium"
  
  tags = {
    Name = "${var.environment_color}-app-${count.index + 1}"
    Color = var.environment_color
  }
}

resource "aws_lb" "app" {
  name = "${var.environment_color}-app-lb"
  load_balancer_type = "application"
  subnets = var.subnet_ids
  
  tags = {
    Color = var.environment_color
  }
}

# DNS record with weighted routing
resource "aws_route53_record" "app" {
  zone_id = var.hosted_zone_id
  name    = "app.example.com"
  type    = "A"
  
  set_identifier = var.environment_color
  weighted_routing_policy {
    weight = var.traffic_weight
  }
  
  alias {
    name                   = aws_lb.app.dns_name
    zone_id               = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}

# Health check and traffic switching
resource "null_resource" "health_check_and_switch" {
  count = var.traffic_weight == 100 ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOF
      # Wait for health checks to pass
      ./scripts/wait_for_health.sh ${aws_lb.app.dns_name}
      
      # Gradually switch traffic
      ./scripts/gradual_traffic_switch.sh ${var.environment_color}
    EOF
  }
  
  depends_on = [aws_lb.app]
}
```

---

### **Scenario 5: Managing Terraform State in Air-Gapped Environment**
**Question:** "Your organization operates in a highly secure, air-gapped environment where there's no internet connectivity. You need to manage Terraform infrastructure, but can't use remote state backends like S3 or Terraform Cloud. How would you implement collaborative Terraform workflows with proper state management in this environment?"

**Expected Answer:**
- Local state management with version control integration
- State locking mechanisms using local file systems
- Manual state backup and synchronization procedures
- Alternative approaches using local storage solutions

```hcl
# terraform.tf - Local backend configuration for air-gapped environment
terraform {
  backend "local" {
    path = "/shared/terraform/states/${var.project_name}/${var.environment}/terraform.tfstate"
  }
}

# State management wrapper script
# scripts/terraform-wrapper.sh
#!/bin/bash
STATE_DIR="/shared/terraform/states/${PROJECT}/${ENV}"
LOCK_FILE="${STATE_DIR}/.terraform.lock"
BACKUP_DIR="/shared/terraform/backups"

# Function to acquire lock
acquire_lock() {
  if [ -f "$LOCK_FILE" ]; then
    echo "State is locked by $(cat $LOCK_FILE)"
    exit 1
  fi
  
  echo "$(whoami)@$(hostname):$(date)" > "$LOCK_FILE"
  trap 'rm -f "$LOCK_FILE"' EXIT
}

# Function to backup state
backup_state() {
  if [ -f "$STATE_DIR/terraform.tfstate" ]; then
    cp "$STATE_DIR/terraform.tfstate" \
       "$BACKUP_DIR/terraform.tfstate.$(date +%Y%m%d-%H%M%S)"
  fi
}

acquire_lock
backup_state
terraform "$@"
```

---

### **Scenario 6: Terraform with Custom Provider Integration**
**Question:** "Your company has an internal API for managing custom hardware resources that aren't supported by existing Terraform providers. You've been asked to integrate Terraform with this internal system. Walk me through how you would create a custom workflow to manage these resources using Terraform."

**Expected Answer:**
- Use external data sources and null resources
- Implement local-exec provisioners with API calls
- Create wrapper scripts for resource lifecycle management
- Explain when to consider building a custom provider vs. workarounds

```hcl
# Custom resource management using null_resource and external data
data "external" "custom_hardware_check" {
  program = ["python3", "${path.module}/scripts/check_hardware.py"]
  
  query = {
    hardware_type = var.hardware_type
    specs = jsonencode(var.hardware_specs)
  }
}

resource "null_resource" "custom_hardware" {
  count = var.hardware_count
  
  # Create custom hardware resource
  provisioner "local-exec" {
    command = <<-EOF
      python3 ${path.module}/scripts/create_hardware.py \
        --type "${var.hardware_type}" \
        --specs '${jsonencode(var.hardware_specs)}' \
        --name "hardware-${count.index + 1}" \
        --output-file "${path.module}/outputs/hardware-${count.index + 1}.json"
    EOF
  }
  
  # Update custom hardware resource
  provisioner "local-exec" {
    when = "create"
    command = <<-EOF
      python3 ${path.module}/scripts/update_hardware.py \
        --id "$(cat ${path.module}/outputs/hardware-${count.index + 1}.json | jq -r '.id')" \
        --specs '${jsonencode(var.hardware_specs)}'
    EOF
  }
  
  # Destroy custom hardware resource
  provisioner "local-exec" {
    when = "destroy"
    command = <<-EOF
      python3 ${path.module}/scripts/destroy_hardware.py \
        --id "$(cat ${path.module}/outputs/hardware-${count.index + 1}.json | jq -r '.id')"
    EOF
  }
  
  triggers = {
    hardware_specs = jsonencode(var.hardware_specs)
    hardware_type = var.hardware_type
  }
}

# External data to get created resource information
data "external" "hardware_info" {
  count = var.hardware_count
  
  program = ["python3", "${path.module}/scripts/get_hardware_info.py"]
  
  query = {
    hardware_file = "${path.module}/outputs/hardware-${count.index + 1}.json"
  }
  
  depends_on = [null_resource.custom_hardware]
}
```

---

### **Scenario 7: Terraform State Migration Between Backend Types**
**Question:** "You've been managing Terraform state locally for months, but now your team is growing and you need to migrate to a remote S3 backend. However, you have multiple environments and projects, each with their own state file. What's your migration strategy to ensure no data loss and minimal disruption?"

**Expected Answer:**
- Step-by-step migration process
- State backup procedures
- Backend configuration management
- Team coordination during migration

```bash
#!/bin/bash
# State migration script - local to S3

# Configuration
PROJECT_NAME="my-project"
ENVIRONMENTS=("dev" "staging" "prod")
S3_BUCKET="my-terraform-states"
AWS_REGION="us-west-2"

# Step 1: Create S3 bucket and DynamoDB table for locking
create_backend_resources() {
  aws s3 mb "s3://$S3_BUCKET" --region "$AWS_REGION"
  aws s3api put-bucket-versioning \
    --bucket "$S3_BUCKET" \
    --versioning-configuration Status=Enabled
  
  aws dynamodb create-table \
    --table-name "terraform-state-locks" \
    --attribute-definitions \
      AttributeName=LockID,AttributeType=S \
    --key-schema \
      AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$AWS_REGION"
}

# Step 2: Migrate each environment
migrate_environment() {
  local env=$1
  echo "Migrating $env environment..."
  
  cd "environments/$env"
  
  # Backup current state
  cp terraform.tfstate "terraform.tfstate.backup.$(date +%Y%m%d-%H%M%S)"
  
  # Create new backend configuration
  cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket         = "$S3_BUCKET"
    key            = "$PROJECT_NAME/$env/terraform.tfstate"
    region         = "$AWS_REGION"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
EOF

  # Initialize with backend migration
  terraform init -migrate-state
  
  # Verify migration
  terraform plan
  
  cd - > /dev/null
}

# Execute migration
create_backend_resources

for env in "${ENVIRONMENTS[@]}"; do
  migrate_environment "$env"
done
```

---

### **Scenario 8: Terraform with Secrets Management Integration**
**Question:** "Your Terraform configuration needs to create resources that require sensitive data (database passwords, API keys, certificates). However, you cannot store these secrets in your Terraform files or state. How would you design a secure workflow that integrates with external secret management systems while maintaining Terraform's declarative approach?"

**Expected Answer:**
- Integration with HashiCorp Vault, AWS Secrets Manager, or Azure Key Vault
- Use of external data sources for secret retrieval
- Proper secret rotation handling
- State file security considerations

```hcl
# Secrets management integration example
terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "~> 3.0"
    }
  }
}

# Configure Vault provider
provider "vault" {
  address = var.vault_address
  # Authentication via environment variables or IAM
}

# Retrieve secrets from Vault
data "vault_generic_secret" "db_credentials" {
  path = "secret/database/${var.environment}"
}

data "vault_generic_secret" "api_keys" {
  path = "secret/api-keys/${var.environment}"
}

# Generate random password and store in Vault
resource "random_password" "db_password" {
  length = 32
  special = true
}

resource "vault_generic_secret" "generated_password" {
  path = "secret/generated/db-password-${var.environment}"
  
  data_json = jsonencode({
    password = random_password.db_password.result
    created_at = timestamp()
  })
}

# Use secrets in resource creation
resource "aws_db_instance" "main" {
  identifier = "${var.environment}-database"
  
  username = data.vault_generic_secret.db_credentials.data["username"]
  password = data.vault_generic_secret.db_credentials.data["password"]
  
  # Ensure password changes trigger updates
  lifecycle {
    replace_triggered_by = [
      vault_generic_secret.generated_password
    ]
  }
  
  tags = {
    Environment = var.environment
    # Never include sensitive data in tags
  }
}

# External API integration with secrets
resource "null_resource" "external_api_setup" {
  provisioner "local-exec" {
    command = <<-EOF
      curl -X POST "https://api.example.com/setup" \
        -H "Authorization: Bearer ${data.vault_generic_secret.api_keys.data["bearer_token"]}" \
        -H "X-API-Key: ${data.vault_generic_secret.api_keys.data["api_key"]}" \
        -d '{"environment": "${var.environment}"}'
    EOF
    
    # Use environment variables instead of inline secrets
    environment = {
      API_TOKEN = data.vault_generic_secret.api_keys.data["bearer_token"]
      API_KEY = data.vault_generic_secret.api_keys.data["api_key"]
    }
  }
  
  triggers = {
    # Trigger recreation when secrets change
    secret_version = data.vault_generic_secret.api_keys.lease_id
  }
}
```

---

## 🎯 Key Interview Assessment Points

These scenarios test:

1. **Advanced State Management** - Understanding of complex state operations
2. **Cross-Account/Multi-Environment** - Real-world enterprise scenarios  
3. **Integration Capabilities** - Working with external systems and APIs
4. **Security Best Practices** - Secrets management and secure workflows
5. **Disaster Recovery** - Handling corrupted state and recovery procedures
6. **Custom Solutions** - Building workarounds when standard providers aren't available
7. **Migration Strategies** - Real-world transition scenarios
8. **Operational Excellence** - Monitoring, scaling, and deployment strategies

## 💡 Follow-up Questions for Each Scenario

- "What would be your rollback strategy if this approach fails?"
- "How would you monitor and alert on the health of this setup?"
- "What are the security implications of this approach?"
- "How would this scale with a larger team or more environments?"
- "What alternative approaches would you consider?"

---

*These scenarios reflect real-world challenges that senior Terraform practitioners encounter in enterprise environments and test deep understanding beyond basic Terraform syntax and concepts.*