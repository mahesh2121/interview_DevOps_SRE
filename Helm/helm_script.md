Here’s a collection of practical scripts for Helm charts, including automation for common tasks like installation, upgrades, linting, and troubleshooting:
1. Helm Chart Installation Script

Use Case: Install a Helm chart with custom values and atomic rollback on failure.
bash
Copy

#!/bin/bash

CHART_NAME="my-app"
CHART_PATH="./my-chart"
NAMESPACE="production"
VALUES_FILE="values-prod.yaml"

helm upgrade --install $CHART_NAME $CHART_PATH \
  --namespace $NAMESPACE \
  --values $VALUES_FILE \
  --atomic \
  --timeout 5m \
  --wait

2. Helm Chart Upgrade Script

Use Case: Safely upgrade a release and preview changes with helm-diff.
bash
Copy

#!/bin/bash

CHART_NAME="my-app"
CHART_PATH="./my-chart"
NAMESPACE="production"
VALUES_FILE="values-prod.yaml"

# Preview changes
helm diff upgrade $CHART_NAME $CHART_PATH --namespace $NAMESPACE --values $VALUES_FILE

# Apply changes with confirmation
read -p "Proceed with upgrade? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  helm upgrade $CHART_NAME $CHART_PATH \
    --namespace $NAMESPACE \
    --values $VALUES_FILE \
    --atomic \
    --timeout 5m
fi

3. Dependency Management Script

Use Case: Update chart dependencies and validate.
bash
Copy

#!/bin/bash

CHART_PATH="./my-chart"

# Update dependencies
helm dependency update $CHART_PATH

# Check for dependency issues
helm dependency build $CHART_PATH

4. Helm Chart Linting Script

Use Case: Validate chart syntax and best practices.
bash
Copy

#!/bin/bash

CHART_PATH="./my-chart"

# Lint the chart
helm lint $CHART_PATH

# Validate Kubernetes manifests
helm template $CHART_PATH | kubeval --strict

5. Helm Chart Packaging Script

Use Case: Package a chart and sign it for security.
bash
Copy

#!/bin/bash

CHART_PATH="./my-chart"
VERSION="1.2.0"

helm package $CHART_PATH --version $VERSION
helm sign $(ls my-chart-*.tgz)

6. Helm Uninstall Script

Use Case: Safely uninstall a release and clean up resources.
bash
Copy

#!/bin/bash

CHART_NAME="my-app"
NAMESPACE="production"

helm uninstall $CHART_NAME --namespace $NAMESPACE

# Optional: Delete PVCs if needed
kubectl delete pvc -l app.kubernetes.io/instance=$CHART_NAME --namespace $NAMESPACE

7. Helm Rollback Script

Use Case: Rollback to a previous revision if upgrades fail.
bash
Copy

#!/bin/bash

CHART_NAME="my-app"
NAMESPACE="production"
REVISION=2  # Previous working revision

helm rollback $CHART_NAME $REVISION --namespace $NAMESPACE

8. Helm Test Script

Use Case: Run post-deployment tests (e.g., smoke tests).
bash
Copy

#!/bin/bash

CHART_NAME="my-app"
NAMESPACE="production"

helm test $CHART_NAME --namespace $NAMESPACE --logs

9. Helm Environment-Specific Script

Use Case: Deploy to different environments (dev/stage/prod).
bash
Copy

#!/bin/bash

ENV=$1
CHART_NAME="my-app-${ENV}"
CHART_PATH="./my-chart"
NAMESPACE="${ENV}"

case $ENV in
  dev|stage)
    VALUES_FILE="values-${ENV}.yaml"
    ;;
  prod)
    VALUES_FILE="values-prod.yaml"
    ;;
  *)
    echo "Usage: $0 [dev|stage|prod]"
    exit 1
    ;;
esac

helm upgrade --install $CHART_NAME $CHART_PATH \
  --namespace $NAMESPACE \
  --values $VALUES_FILE \
  --atomic

10. Helm Secrets Integration Script

Use Case: Manage encrypted secrets in Helm charts.
bash
Copy

#!/bin/bash

# Install helm-secrets plugin
helm plugin install https://github.com/jkroepke/helm-secrets

# Deploy with encrypted values
helm secrets upgrade --install my-app ./my-chart \
  --namespace production \
  --values secrets.enc.yaml

11. Helm CI/CD Pipeline Script (Jenkins/GitHub Actions)
bash
Copy

#!/bin/bash

# Example CI/CD steps
helm lint ./chart
helm dependency update ./chart
helm package ./chart
helm push my-chart-1.0.0.tgz oci://my-registry/charts

12. Helm Troubleshooting Script

Use Case: Debug a failed release.
bash
Copy

#!/bin/bash

CHART_NAME="my-app"
NAMESPACE="production"

# Check release status
helm status $CHART_NAME --namespace $NAMESPACE

# View generated manifests
helm get manifest $CHART_NAME --namespace $NAMESPACE

# Check Kubernetes events
kubectl get events --namespace $NAMESPACE --sort-by='.metadata.creationTimestamp'

Best Practices

    Atomic OpeSERrations: Always use --atomic in production to auto-rollback on failure.

    Version Pinning: Specify exact chart versions in CI/CD pipelines.

    Secrets Management: Use tools like helm-secrets or sops for encrypted values.

    Validation: Combine helm lint with kubeval for manifest validation.

Common Helm Flags for Production
Flag	Purpose
--atomic	Auto-rollback on failure.
--wait	Wait for resources to be ready.
--timeout	Set timeout for operations (e.g., 5m).
--history-max	Limit stored revisions (e.g., --history-max 5).

These scripts streamline Helm workflows for security, reliability, and automation. Adjust values and paths based on your chart structure!