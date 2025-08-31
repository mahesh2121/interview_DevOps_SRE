# AWS DevOps/SRE Interview Questions & Answers

## 1️⃣ How do you launch and configure an EC2 instance with user data?

**Answer:**

EC2 instances can be launched with user data scripts that run during the first boot to automate initial configuration.

### Methods to Launch:
- **AWS Console**: EC2 Dashboard → Launch Instance → Advanced Details → User Data
- **AWS CLI**: `aws ec2 run-instances --user-data file://script.sh`
- **Terraform**: Using `user_data` parameter in `aws_instance` resource
- **CloudFormation**: Using `UserData` property in EC2 instance resource

### User Data Script Example:
```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello from $(hostname -f)</h1>" > /var/www/html/index.html
```

### Key Points:
- User data runs as **root** on first boot only
- Maximum size: **16 KB** for user data
- Can be shell scripts, cloud-init directives, or PowerShell (Windows)
- Base64 encoded when passed via API
- Logs available in `/var/log/cloud-init-output.log`

---

## 2️⃣ How do you configure security groups vs NACLs in a VPC?

**Answer:**

### Security Groups (Instance Level):
- **Stateful**: Return traffic automatically allowed
- **Default**: Deny all inbound, allow all outbound
- **Rules**: Allow rules only (no deny rules)
- **Target**: Specific instances/ENIs
- **Evaluation**: All rules evaluated

```bash
# Create security group
aws ec2 create-security-group --group-name web-sg --description "Web servers"

# Add rules
aws ec2 authorize-security-group-ingress --group-id sg-12345 \
  --protocol tcp --port 80 --cidr 0.0.0.0/0
```

### NACLs (Subnet Level):
- **Stateless**: Must explicitly allow both inbound and outbound
- **Default**: Allow all traffic
- **Rules**: Both allow and deny rules
- **Target**: All instances in subnet
- **Evaluation**: Rules processed in order (lowest number first)

```bash
# Create NACL
aws ec2 create-network-acl --vpc-id vpc-12345

# Add rules (numbered for priority)
aws ec2 create-network-acl-entry --network-acl-id acl-12345 \
  --rule-number 100 --protocol tcp --port-range From=80,To=80 \
  --cidr-block 0.0.0.0/0 --rule-action allow
```

### Best Practices:
- Use **Security Groups** as primary protection (more granular)
- Use **NACLs** for additional subnet-level controls
- Security Groups are more common for application-level security

---

## 3️⃣ Explain how to design a VPC with public and private subnets.

**Answer:**

### VPC Architecture Design:

```
Internet Gateway
       |
   Public Subnet (10.0.1.0/24)
   - Web Servers/ALB
   - NAT Gateway
       |
   Private Subnet (10.0.2.0/24)
   - App Servers
   - Databases
```

### Step-by-Step Implementation:

1. **Create VPC**:
```bash
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications \
  'ResourceType=vpc,Tags=[{Key=Name,Value=MyVPC}]'
```

2. **Create Subnets**:
```bash
# Public subnet
aws ec2 create-subnet --vpc-id vpc-12345 --cidr-block 10.0.1.0/24 \
  --availability-zone us-west-2a --tag-specifications \
  'ResourceType=subnet,Tags=[{Key=Name,Value=Public-Subnet}]'

# Private subnet
aws ec2 create-subnet --vpc-id vpc-12345 --cidr-block 10.0.2.0/24 \
  --availability-zone us-west-2b --tag-specifications \
  'ResourceType=subnet,Tags=[{Key=Name,Value=Private-Subnet}]'
```

3. **Create and Attach Internet Gateway**:
```bash
aws ec2 create-internet-gateway
aws ec2 attach-internet-gateway --vpc-id vpc-12345 --internet-gateway-id igw-12345
```

4. **Configure Route Tables**:
```bash
# Public route table
aws ec2 create-route-table --vpc-id vpc-12345
aws ec2 create-route --route-table-id rtb-public --destination-cidr-block 0.0.0.0/0 \
  --gateway-id igw-12345

# Private route table (routes to NAT Gateway)
aws ec2 create-route --route-table-id rtb-private --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id nat-12345
```

### Design Principles:
- **Multi-AZ**: Deploy across multiple availability zones for high availability
- **CIDR Planning**: Use RFC 1918 ranges, plan for growth
- **Security**: Private subnets for databases, public for load balancers only

---

## 4️⃣ What is the use of a NAT Gateway vs Internet Gateway?

**Answer:**

### Internet Gateway (IGW):
- **Purpose**: Bidirectional internet access
- **Target**: Public subnets
- **Traffic**: Inbound and outbound internet traffic
- **Use Case**: Web servers, public-facing resources

### NAT Gateway:
- **Purpose**: Outbound-only internet access
- **Target**: Private subnets
- **Traffic**: Only outbound internet traffic (responses allowed back)
- **Use Case**: Private servers needing software updates, API calls

### Key Differences:

| Feature | Internet Gateway | NAT Gateway |
|---------|------------------|-------------|
| Direction | Bidirectional | Outbound only |
| Cost | Free | $0.045/hour + data processing |
| Availability | Regional | AZ-specific |
| Bandwidth | No limit | Up to 45 Gbps |
| Management | AWS managed | AWS managed |

### Architecture Example:
```
Internet → IGW → Public Subnet → NAT Gateway → Private Subnet
```

### NAT Gateway Setup:
```bash
# Create NAT Gateway in public subnet
aws ec2 create-nat-gateway --subnet-id subnet-public --allocation-id eipalloc-12345

# Update private subnet route table
aws ec2 create-route --route-table-id rtb-private \
  --destination-cidr-block 0.0.0.0/0 --nat-gateway-id nat-12345
```

---

## 5️⃣ How do you attach and mount EBS volumes to EC2?

**Answer:**

### Step-by-Step Process:

1. **Create EBS Volume**:
```bash
aws ec2 create-volume --size 20 --volume-type gp3 \
  --availability-zone us-west-2a --tag-specifications \
  'ResourceType=volume,Tags=[{Key=Name,Value=MyDataVolume}]'
```

2. **Attach to EC2 Instance**:
```bash
aws ec2 attach-volume --volume-id vol-12345 \
  --instance-id i-12345 --device /dev/sdf
```

3. **Format and Mount (Inside EC2)**:
```bash
# Check if volume is attached
lsblk

# Format the volume (first time only)
sudo mkfs -t xfs /dev/xvdf

# Create mount point
sudo mkdir /data

# Mount the volume
sudo mount /dev/xvdf /data

# Make permanent (add to /etc/fstab)
echo '/dev/xvdf /data xfs defaults,nofail 0 2' | sudo tee -a /etc/fstab

# Verify mount
df -h
```

### User Data for Automatic Mounting:
```bash
#!/bin/bash
# Wait for volume attachment
while [ ! -e /dev/xvdf ]; do sleep 1; done

# Format if not formatted
if ! blkid /dev/xvdf; then
    mkfs -t xfs /dev/xvdf
fi

# Mount
mkdir -p /data
mount /dev/xvdf /data
echo '/dev/xvdf /data xfs defaults,nofail 0 2' >> /etc/fstab
```

### Best Practices:
- Use **gp3** volumes for better price/performance
- Enable **encryption** for sensitive data
- Create **snapshots** for backups
- Use **nofail** option in fstab to prevent boot issues

---

## 6️⃣ How do you configure Auto Scaling for EC2 instances?

**Answer:**

### Components Required:
1. **Launch Template** (defines instance configuration)
2. **Auto Scaling Group** (manages scaling logic)
3. **Scaling Policies** (when to scale)

### 1. Create Launch Template:
```bash
aws ec2 create-launch-template --launch-template-name web-template \
  --launch-template-data '{
    "ImageId": "ami-12345",
    "InstanceType": "t3.micro",
    "SecurityGroupIds": ["sg-12345"],
    "UserData": "'$(base64 -w 0 userdata.sh)'",
    "IamInstanceProfile": {"Name": "EC2-CloudWatch-Role"}
  }'
```

### 2. Create Auto Scaling Group:
```bash
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name web-asg \
  --launch-template "LaunchTemplateName=web-template,Version=1" \
  --min-size 2 --max-size 10 --desired-capacity 3 \
  --vpc-zone-identifier "subnet-12345,subnet-67890" \
  --target-group-arns arn:aws:elasticloadbalancing:region:account:targetgroup/my-targets \
  --health-check-type ELB --health-check-grace-period 300
```

### 3. Configure Scaling Policies:

**CPU-based scaling**:
```bash
# Scale up policy
aws autoscaling create-or-update-scaling-policy \
  --auto-scaling-group-name web-asg \
  --policy-name scale-up --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ASGAverageCPUUtilization"
    }
  }'
```

### 4. CloudWatch Alarms (Alternative approach):
```bash
# Create alarm for high CPU
aws cloudwatch put-metric-alarm --alarm-name high-cpu \
  --alarm-description "Scale up on high CPU" \
  --metric-name CPUUtilization --namespace AWS/EC2 \
  --statistic Average --period 300 --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:autoscaling:region:account:scalingPolicy:policy-id
```

### Scaling Types:
- **Target Tracking**: Maintain specific metric value (CPU, network, ALB requests)
- **Step Scaling**: Scale based on alarm breach size
- **Scheduled Scaling**: Scale at specific times
- **Predictive Scaling**: ML-based scaling

---

## 7️⃣ What is the difference between Application Load Balancer (ALB) and Network Load Balancer (NLB)?

**Answer:**

### Application Load Balancer (ALB) - Layer 7:

**Features**:
- HTTP/HTTPS traffic only
- Content-based routing (path, host, headers)
- SSL termination
- WebSocket support
- Integration with AWS WAF

**Use Cases**:
- Web applications
- Microservices
- Container-based applications

**Configuration Example**:
```bash
# Create ALB
aws elbv2 create-load-balancer --name my-alb --scheme internet-facing \
  --subnets subnet-12345 subnet-67890 --security-groups sg-12345

# Create target group
aws elbv2 create-target-group --name web-targets --protocol HTTP \
  --port 80 --vpc-id vpc-12345 --health-check-path /health

# Create listener with rules
aws elbv2 create-listener --load-balancer-arn arn:aws:elasticloadbalancing... \
  --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing...
```

### Network Load Balancer (NLB) - Layer 4:

**Features**:
- TCP/UDP/TLS traffic
- Ultra-low latency (microseconds)
- Static IP addresses
- Preserves source IP
- Extreme performance (millions of requests/sec)

**Use Cases**:
- Gaming applications
- IoT applications
- Non-HTTP protocols

### Comparison Table:

| Feature | ALB | NLB |
|---------|-----|-----|
| **Layer** | Layer 7 (Application) | Layer 4 (Transport) |
| **Protocols** | HTTP, HTTPS, WebSocket | TCP, UDP, TLS |
| **Routing** | Content-based | Connection-based |
| **Latency** | Higher | Ultra-low |
| **Static IP** | No | Yes |
| **SSL Termination** | Yes | Limited |
| **WAF Integration** | Yes | No |
| **Cost** | Higher | Lower |

---

## 8️⃣ How do you monitor EC2 using CloudWatch (metrics, alarms, dashboards)?

**Answer:**

### 1. Default Metrics (5-minute intervals):
- CPUUtilization
- NetworkIn/Out
- DiskReadOps/WriteOps
- StatusCheckFailed

### 2. Enable Detailed Monitoring (1-minute intervals):
```bash
aws ec2 monitor-instances --instance-ids i-12345
```

### 3. Custom Metrics with CloudWatch Agent:

**Install Agent**:
```bash
# Amazon Linux 2
sudo yum install -y amazon-cloudwatch-agent

# Configure agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```

**Agent Configuration** (`/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json`):
```json
{
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "cpu": {"measurement": ["cpu_usage_idle", "cpu_usage_iowait"]},
      "disk": {"measurement": ["used_percent"], "resources": ["*"]},
      "mem": {"measurement": ["mem_used_percent"]}
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [{
          "file_path": "/var/log/httpd/access_log",
          "log_group_name": "/aws/ec2/apache",
          "log_stream_name": "{instance_id}"
        }]
      }
    }
  }
}
```

### 4. Create CloudWatch Alarms:
```bash
# CPU alarm
aws cloudwatch put-metric-alarm --alarm-name high-cpu \
  --alarm-description "High CPU usage" \
  --metric-name CPUUtilization --namespace AWS/EC2 \
  --statistic Average --period 300 --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=InstanceId,Value=i-12345 \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:region:account:topic-name
```

### 5. Create Custom Dashboard:
```bash
aws cloudwatch put-dashboard --dashboard-name EC2-Monitoring \
  --dashboard-body '{
    "widgets": [{
      "type": "metric",
      "properties": {
        "metrics": [["AWS/EC2", "CPUUtilization", "InstanceId", "i-12345"]],
        "period": 300,
        "stat": "Average",
        "region": "us-west-2",
        "title": "EC2 CPU Utilization"
      }
    }]
  }'
```

---

## 9️⃣ How do you set up CloudWatch log groups for an application?

**Answer:**

### 1. Create Log Group:
```bash
aws logs create-log-group --log-group-name /aws/ec2/myapp
aws logs put-retention-policy --log-group-name /aws/ec2/myapp --retention-in-days 30
```

### 2. Configure CloudWatch Agent for Log Collection:

**Agent Configuration**:
```json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/myapp/application.log",
            "log_group_name": "/aws/ec2/myapp",
            "log_stream_name": "{instance_id}-app",
            "timezone": "UTC",
            "multi_line_start_pattern": "^\\d{4}-\\d{2}-\\d{2}"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/system",
            "log_stream_name": "{instance_id}-system"
          }
        ]
      }
    }
  }
}
```

### 3. Application-Level Logging (using AWS SDK):

**Python Example**:
```python
import boto3
import logging
from pythonjsonlogger import jsonlogger

# Configure CloudWatch Logs client
client = boto3.client('logs')

# Send logs programmatically
def send_log_event(message, log_group, log_stream):
    try:
        client.put_log_events(
            logGroupName=log_group,
            logStreamName=log_stream,
            logEvents=[{
                'timestamp': int(time.time() * 1000),
                'message': json.dumps(message)
            }]
        )
    except Exception as e:
        print(f"Failed to send log: {e}")
```

### 4. Set Up Log Insights Queries:
```sql
-- Find errors in last hour
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100

-- Application performance
fields @timestamp, @duration
| filter @type = "REPORT"
| stats avg(@duration) by bin(5m)
```

### 5. Create Log-based Alarms:
```bash
aws logs put-metric-filter --log-group-name /aws/ec2/myapp \
  --filter-name error-count --filter-pattern "ERROR" \
  --metric-transformations \
  metricName=ErrorCount,metricNamespace=MyApp,metricValue=1

aws cloudwatch put-metric-alarm --alarm-name app-errors \
  --metric-name ErrorCount --namespace MyApp \
  --statistic Sum --period 300 --threshold 5 \
  --comparison-operator GreaterThanThreshold
```

---

## 🔟 How do you manage RDS backups and automated failover?

**Answer:**

### 1. RDS Backup Configuration:

**Automated Backups**:
```bash
# Enable automated backups
aws rds modify-db-instance --db-instance-identifier mydb \
  --backup-retention-period 7 --preferred-backup-window "03:00-04:00" \
  --preferred-maintenance-window "sun:04:00-sun:05:00"
```

**Manual Snapshots**:
```bash
# Create manual snapshot
aws rds create-db-snapshot --db-instance-identifier mydb \
  --db-snapshot-identifier mydb-snapshot-$(date +%Y%m%d)

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier restored-db --db-snapshot-identifier mydb-snapshot-20241201
```

### 2. Multi-AZ Deployment for Failover:

**Enable Multi-AZ**:
```bash
aws rds modify-db-instance --db-instance-identifier mydb \
  --multi-az --apply-immediately
```

**Features**:
- **Automatic failover** in 60-120 seconds
- **Synchronous replication** to standby
- **Same endpoint** - no application changes needed
- **Maintenance benefits** - patches applied to standby first

### 3. Read Replicas (Different from Multi-AZ):
```bash
# Create read replica
aws rds create-db-instance-read-replica \
  --db-instance-identifier mydb-replica \
  --source-db-instance-identifier mydb \
  --db-instance-class db.t3.micro
```

### 4. Backup Strategy Best Practices:

**Point-in-Time Recovery**:
- Enabled automatically with automated backups
- Can restore to any point within retention period
- Transaction log backups stored in S3

**Cross-Region Backups**:
```bash
# Copy snapshot to another region
aws rds copy-db-snapshot --source-db-snapshot-identifier mydb-snapshot \
  --target-db-snapshot-identifier mydb-snapshot-copy \
  --source-region us-west-2 --region us-east-1
```

### 5. Monitoring and Alerts:
```bash
# Database connection alarm
aws cloudwatch put-metric-alarm --alarm-name db-connections \
  --metric-name DatabaseConnections --namespace AWS/RDS \
  --statistic Average --period 300 --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=DBInstanceIdentifier,Value=mydb
```

---

## 1️⃣1️⃣ How do you configure Route 53 for domain hosting and failover routing?

**Answer:**

### 1. Domain Hosting Setup:

**Create Hosted Zone**:
```bash
aws route53 create-hosted-zone --name example.com \
  --caller-reference $(date +%s) \
  --hosted-zone-config Comment="Production domain"
```

**Basic DNS Records**:
```bash
# A record pointing to ALB
aws route53 change-resource-record-sets --hosted-zone-id Z12345 \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "www.example.com",
        "Type": "A",
        "AliasTarget": {
          "DNSName": "my-alb-123456.us-west-2.elb.amazonaws.com",
          "EvaluateTargetHealth": true,
          "HostedZoneId": "Z1D633PJN98FT9"
        }
      }
    }]
  }'
```

### 2. Failover Routing Configuration:

**Primary-Secondary Failover**:
```bash
# Primary record
aws route53 change-resource-record-sets --hosted-zone-id Z12345 \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "app.example.com",
        "Type": "A",
        "SetIdentifier": "primary",
        "Failover": "PRIMARY",
        "TTL": 60,
        "ResourceRecords": [{"Value": "192.0.2.1"}],
        "HealthCheckId": "hc-12345"
      }
    }]
  }'

# Secondary record
aws route53 change-resource-record-sets --hosted-zone-id Z12345 \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE", 
      "ResourceRecordSet": {
        "Name": "app.example.com",
        "Type": "A",
        "SetIdentifier": "secondary",
        "Failover": "SECONDARY",
        "TTL": 60,
        "ResourceRecords": [{"Value": "192.0.2.2"}]
      }
    }]
  }'
```

### 3. Health Checks:
```bash
# Create health check
aws route53 create-health-check --caller-reference $(date +%s) \
  --health-check-config '{
    "Type": "HTTPS",
    "ResourcePath": "/health",
    "FullyQualifiedDomainName": "app.example.com",
    "Port": 443,
    "RequestInterval": 30,
    "FailureThreshold": 3
  }'
```

### 4. Advanced Routing Policies:

**Weighted Routing** (Blue/Green deployments):
```bash
# 90% traffic to current version
aws route53 change-resource-record-sets --hosted-zone-id Z12345 \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "api.example.com",
        "Type": "A",
        "SetIdentifier": "current",
        "Weight": 90,
        "TTL": 60,
        "ResourceRecords": [{"Value": "192.0.2.1"}]
      }
    }]
  }'

# 10% traffic to new version
# Similar configuration with Weight: 10
```

**Geolocation Routing**:
```bash
# Route EU traffic to EU region
aws route53 change-resource-record-sets --hosted-zone-id Z12345 \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "api.example.com",
        "Type": "A",
        "SetIdentifier": "eu-users",
        "GeoLocation": {"ContinentCode": "EU"},
        "TTL": 300,
        "ResourceRecords": [{"Value": "192.0.2.10"}]
      }
    }]
  }'
```

---

## 1️⃣2️⃣ What is the difference between Elastic IPs and Public IPs?

**Answer:**

### Public IP Addresses:

**Characteristics**:
- **Dynamic**: Changes when instance stops/starts
- **Free**: No additional charges
- **Automatic**: Assigned automatically in public subnets
- **Release**: Released when instance terminates

**Behavior**:
```bash
# Instance with public IP
aws ec2 run-instances --image-id ami-12345 --instance-type t3.micro \
  --subnet-id subnet-12345 --associate-public-ip-address
```

### Elastic IP Addresses (EIP):

**Characteristics**:
- **Static**: Remains same across stop/start cycles
- **Chargeable**: $0.005/hour when not attached to running instance
- **Manual**: Must be explicitly allocated and associated
- **Persistent**: Remains until explicitly released

**Management**:
```bash
# Allocate Elastic IP
aws ec2 allocate-address --domain vpc

# Associate with instance
aws ec2 associate-address --instance-id i-12345 --allocation-id eipalloc-12345

# Disassociate
aws ec2 disassociate-address --allocation-id eipalloc-12345

# Release (important to avoid charges)
aws ec2 release-address --allocation-id eipalloc-12345
```

### Comparison Table:

| Feature | Public IP | Elastic IP |
|---------|-----------|------------|
| **Cost** | Free | $0.005/hour when unattached |
| **Persistence** | Lost on stop/start | Persistent |
| **DNS Resolution** | Changes with IP | Static |
| **Use Case** | Temporary/dev instances | Production servers |
| **Limit** | 1 per instance | 5 per region (default) |
| **Attachment** | Automatic | Manual |

### When to Use Each:

**Use Public IP for**:
- Development/testing environments
- Auto Scaling Groups (instances come and go)
- Cost optimization
- Temporary workloads

**Use Elastic IP for**:
- Production web servers
- DNS A records pointing to specific servers
- Services requiring consistent IP addresses
- Whitelisting scenarios

### Best Practices:
- **Release unused EIPs** to avoid charges
- **Use ALB/NLB** instead of EIPs for most production workloads
- **Document EIP usage** to prevent accidental releases
- **Monitor EIP costs** in billing dashboard

---

## Additional AWS CLI Configuration Tips:

### AWS CLI Setup:
```bash
# Configure AWS CLI
aws configure set region us-west-2
aws configure set output json

# Use profiles for multiple accounts
aws configure --profile prod
aws configure --profile dev
```

### Common Troubleshooting Commands:
```bash
# Check instance status
aws ec2 describe-instance-status --instance-ids i-12345

# View VPC configuration
aws ec2 describe-vpcs --vpc-ids vpc-12345

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-12345

# Monitor Auto Scaling activities
aws autoscaling describe-scaling-activities --auto-scaling-group-name web-asg
```

---

*This document serves as a comprehensive reference for AWS DevOps/SRE interview preparation. Each answer includes practical examples and CLI commands for hands-on practice.*