Core Helm Commands

    Install a Chart
    bash
    Copy

    helm install <release-name> <chart> --namespace <namespace> --values values.yaml

        Explanation: Deploys a Helm chart as a release in a Kubernetes cluster.

        Production Tip: Use --atomic to auto-rollback on failure.
        bash
        Copy

        helm install my-app ./chart --atomic --timeout 5m

    Upgrade a Release
    bash
    Copy

    helm upgrade <release-name> <chart> --values values.yaml

        Explanation: Updates an existing release with new configurations or chart versions.

        Troubleshooting Flag: Use --dry-run to simulate changes.
        bash
        Copy

        helm upgrade my-app ./chart --dry-run

    Rollback a Release
    bash
    Copy

    helm rollback <release-name> <revision-number>

        Explanation: Reverts a release to a previous version.

        Example: Rollback to revision 2:
        bash
        Copy

        helm rollback my-app 2

    List Releases
    bash
    Copy

    helm list --namespace <namespace>

        Explanation: Shows deployed releases and their statuses.

        Flag: Use --all-namespaces to see releases across the cluster.

    Uninstall a Release
    bash
    Copy

    helm uninstall <release-name> --namespace <namespace>

        Explanation: Removes a release and its resources.

        Caution: Use --keep-history to retain release metadata.

Production Troubleshooting Commands

    Check Release Status
    bash
    Copy

    helm status <release-name> --namespace <namespace>

        Use Case: Diagnose why a release is stuck in pending-upgrade or failed.

        Output: Shows notes, hooks, and errors.

    View Release History
    bash
    Copy

    helm history <release-name> --namespace <namespace>

        Use Case: Identify which revision caused a failure (e.g., a bad upgrade).

    Inspect Rendered Manifests
    bash
    Copy

    helm get manifest <release-name> --namespace <namespace>

        Use Case: Debug incorrect Kubernetes resource configurations (e.g., misconfigured Service/Deployment).

    Check Release Values
    bash
    Copy

    helm get values <release-name> --namespace <namespace>

        Use Case: Verify if the correct values (e.g., replicas, image tags) were applied.

    Debug Hooks
    bash
    Copy

    helm get hooks <release-name> --namespace <namespace>

        Use Case: Investigate failing pre/post-install hooks (e.g., a stuck Job).

    Lint a Chart
    bash
    Copy

    helm lint ./chart

        Use Case: Validate chart syntax and best practices before deployment.

    Render Templates Locally
    bash
    Copy

    helm template ./chart --values values.yaml

        Use Case: Preview Kubernetes manifests without installing the chart.

Advanced Production Scenarios

    Dependency Management
    bash
    Copy

    helm dependency update ./chart

        Use Case: Resolve chart dependencies (e.g., Redis, PostgreSQL subcharts).

    Run Tests
    bash
    Copy

    helm test <release-name> --namespace <namespace>

        Use Case: Validate release functionality (e.g., smoke tests for connectivity).

    Export Release State
    bash
    Copy

    helm get all <release-name> --namespace <namespace> > release-state.yaml

        Use Case: Snapshot a release’s configuration for audits or debugging.

Production Best Practices

    Atomic Rollbacks
    bash
    Copy

    helm upgrade --atomic --timeout 5m

        Rolls back changes automatically if the upgrade fails.

    Use --wait for Resource Readiness
    bash
    Copy

    helm install --wait --timeout 5m

        Blocks until all resources (e.g., Pods) are ready.

    Secure Secrets

        Avoid hardcoding secrets in values.yaml. Use Kubernetes Secrets or integrate with Vault.

    Monitor with Hooks
    yaml
    Copy

    annotations:
      "helm.sh/hook": post-install

        Use hooks for backups, migrations, or notifications.

Common Production Issues & Fixes
Issue	Command	Explanation
Release Stuck in pending	helm rollback <release> <revision>	Rollback to a stable revision.
Failed Hooks	kubectl logs <hook-pod>	Check logs of the failed hook Pod.
Resource Conflicts	helm get manifest	Look for immutable field errors (e.g., selector).
Image Pull Errors	helm get values	Verify image.repository and tag in values.
Plugins for Enhanced Debugging

    Diff Plugin
    bash
    Copy

    helm plugin install https://github.com/databus23/helm-diff
    helm diff upgrade <release> ./chart

        Use Case: Preview changes before upgrading.

    Secrets Plugin
    bash
    Copy

    helm plugin install https://github.com/jkroepke/helm-secrets
    helm secrets install <release> ./chart --values secrets.yaml

        Use Case: Encrypt sensitive values files.

This guide covers Helm’s critical commands and troubleshooting workflows for production-grade Kubernetes deployments. Always test changes in staging first!