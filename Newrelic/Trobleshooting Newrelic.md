7. Troubleshooting (SRE Playbook)
Issue 1: No Data in New Relic

Scenario:
New Relic dashboards show gaps in data for your ECS tasks.
Step-by-Step Troubleshooting:

    Verify IAM Role Permissions

        Ensure the ECS task execution role has permissions to retrieve secrets (e.g., New Relic license key from AWS Secrets Manager).

        Example Terraform IAM Policy:
        hcl
        Copy

        resource "aws_iam_policy" "ecs_secrets_access" {
          name = "ecs-secrets-access"
          policy = jsonencode({
            Version = "2012-10-17",
            Statement = [{
              Effect = "Allow",
              Action = ["secretsmanager:GetSecretValue"],
              Resource = [aws_secretsmanager_secret.newrelic_license.arn]
            }]
          })
        }

        AWS CLI Check:
        bash
        Copy

        # List task execution role policies
        aws iam list-attached-role-policies --role-name ecs-task-execution-role

    Check Secrets Manager Access

        Ensure the task can access the secret:
        bash
        Copy

        # Simulate secret retrieval (replace <SECRET_ARN>)
        aws secretsmanager get-secret-value --secret-id <SECRET_ARN>

    Inspect Agent Logs

        Get container ID for the New Relic agent:
        bash
        Copy

        # List containers in the ECS task
        aws ecs describe-tasks --cluster <CLUSTER_NAME> --tasks <TASK_ID>

        Fetch logs from the New Relic sidecar container:
        bash
        Copy

        docker logs <NEW_RELIC_CONTAINER_ID>

        Example Error:
        log
        Copy

        ERROR: Unable to connect to New Relic endpoint (check license key)

Automation Example:

Trigger a Lambda function if logs contain ERROR via CloudWatch Logs Subscription:
python
Copy

import boto3

def lambda_handler(event, context):
    for log in event['logEvents']:
        if "ERROR" in log['message']:
            sns = boto3.client('sns')
            sns.publish(
                TopicArn='<SNS_TOPIC_ARN>',
                Message=f"New Relic Agent Error: {log['message']}"
            )

Issue 2: High Latency

Scenario:
API endpoints show increased response times (P95 > 2s).
Step-by-Step Troubleshooting:

    Use New Relic Thread Profiler

        Navigate to New Relic APM → Transactions → Slow Transactions.

        Identify slow traces and use the Thread Profiler to analyze code bottlenecks.

        Example NRQL Query:
        sql
        Copy

        SELECT average(duration) FROM Transaction WHERE appName = 'my-ecs-app' FACET name SINCE 1 hour ago

    Check ECS Throttling/Placement Failures

        CloudWatch Metrics:

            CPUUtilization, MemoryUtilization, ThrottledRequests.
        bash
        Copy

        # Fetch ECS service metrics
        aws cloudwatch get-metric-statistics \
          --namespace AWS/ECS \
          --metric-name CPUUtilization \
          --dimensions Name=ClusterName,Value=<CLUSTER_NAME> \
          --start-time $(date -u +"%Y-%m-%dT%H:%M:%SZ" --date "-5 minutes") \
          --end-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") \
          --period 60 \
          --statistics Average

        ECS Service Events (via AWS CLI):
        bash
        Copy

        aws ecs describe-services --cluster <CLUSTER_NAME> --services <SERVICE_NAME>

        Example Error:
        json
        Copy

        "events": [
          {
            "message": "service was unable to place a task because no container instance met all of its requirements",
            "createdAt": "2023-10-01T12:00:00Z"
          }
        ]

Fix Implementation:

    Adjust Auto Scaling:
    hcl
    Copy

    # Example: Scale based on CPUReservation
    resource "aws_appautoscaling_policy" "ecs_scale_out" {
      name               = "ecs-scale-out"
      service_namespace  = "ecs"
      resource_id        = "service/<CLUSTER_NAME>/<SERVICE_NAME>"
      scalable_dimension = "ecs:service:DesiredCount"
      policy_type        = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration {
        target_value = 70
        predefined_metric_specification {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
      }
    }

    Optimize Task Placement:
    Use spread strategy to distribute tasks across Availability Zones.
    json
    Copy

    "placementStrategies": [
      {
        "type": "spread",
        "field": "attribute:ecs.availability-zone"
      }
    ]

SRE Best Practices

    Preventive Automation:

        Use Terraform to enforce IAM policies and resource limits.

        Schedule daily CloudWatch alarms to audit task health.

    Runbook Integration:

        Embed troubleshooting steps in ChatOps tools (e.g., Slack/Jira) via New Relic alerts.

    Chaos Testing:

        Simulate agent failures using AWS Fault Injection Simulator (FIS):
        bash
        Copy

        # Terminate New Relic container in a task
        aws ecs stop-task --cluster <CLUSTER_NAME> --task <TASK_ID>

Summary

    No Data: Fix IAM/secret access and monitor agent logs.

    High Latency: Profile code bottlenecks and auto-scale ECS tasks.

    Automation: Use Terraform + Lambda to enforce reliability.

This playbook aligns with SRE principles by combining observability (New Relic), infrastructure automation (Terraform), and proactive failure testing. Let me know if you need deeper dives!