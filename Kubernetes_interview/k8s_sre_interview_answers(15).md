# Kubernetes SRE Production Expert Interview Answers

## 1. Pod CrashLoopBackOff with No Error Logs

**Debugging Approach:**

1. **Check Resource Constraints:**
   ```bash
   kubectl describe pod <pod-name>
   kubectl top pod <pod-name>
   ```
   Look for OOMKilled events or CPU throttling.

2. **Examine Liveness/Readiness Probes:**
   ```bash
   kubectl get pod <pod-name> -o yaml | grep -A 10 livenessProbe
   ```
   Probes might be failing due to slow startup or incorrect configuration.

3. **Check Init Containers:**
   ```bash
   kubectl logs <pod-name> -c <init-container-name>
   ```

4. **Investigate Node-Level Issues:**
   ```bash
   kubectl describe node <node-name>
   journalctl -u kubelet
   ```

5. **Security Context Problems:**
   Check if the pod can't access required files due to securityContext restrictions.

**Resolution Strategy:**
- Temporarily disable probes to isolate the issue
- Increase resource limits/requests
- Add debug containers or modify entrypoint for troubleshooting
- Use `kubectl debug` for ephemeral debugging containers

## 2. StatefulSet Pod Recreation Issues

**Common Causes & Solutions:**

1. **PVC Not Releasing:**
   ```bash
   kubectl get pvc
   kubectl describe pvc <pvc-name>
   ```
   If PVC is stuck in terminating state, check for finalizers.

2. **Pod Identity Conflicts:**
   StatefulSets require ordered pod creation. Check if the previous pod's identity is still claimed.

3. **Storage Class Issues:**
   ```bash
   kubectl get storageclass
   kubectl describe pv <pv-name>
   ```

**Safe Resolution Without Data Loss:**
```bash
# Backup data first
kubectl exec <pod-name> -- tar -czf /backup.tar.gz /data

# Force delete stuck pod (last resort)
kubectl delete pod <pod-name> --grace-period=0 --force

# Check PVC status and manually release if needed
kubectl patch pvc <pvc-name> -p '{"metadata":{"finalizers":null}}'

# Recreate the pod
kubectl delete pod <pod-name>
```

## 3. Cluster Autoscaler Not Scaling

**Investigation Steps:**

1. **Check Autoscaler Logs:**
   ```bash
   kubectl logs -n kube-system deployment/cluster-autoscaler
   ```

2. **Verify Node Group Configuration:**
   - Min/max node limits in ASG (AWS) or MIG (GCP)
   - Instance types available
   - Resource quotas

3. **Examine Pending Pods:**
   ```bash
   kubectl describe pod <pending-pod>
   ```
   Look for scheduling constraints: nodeSelector, affinity, taints/tolerations.

4. **Check Resource Requests:**
   Pods without resource requests might not trigger scaling.

5. **Verify IAM/RBAC Permissions:**
   Autoscaler needs permissions to create/delete nodes.

**Common Fixes:**
- Adjust node group max size
- Remove restrictive scheduling constraints
- Add resource requests to pods
- Check for cordoned nodes blocking scheduling

## 4. Network Policy Debugging

**Design Approach:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-specific-cross-namespace
  namespace: target-namespace
spec:
  podSelector:
    matchLabels:
      app: my-service
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: source-namespace
    - podSelector:
        matchLabels:
          app: client-service
    ports:
    - protocol: TCP
      port: 8080
```

**Debugging Process:**
1. **Test Connectivity:**
   ```bash
   kubectl exec -it <pod> -- nc -zv <service>.<namespace>.svc.cluster.local <port>
   ```

2. **Analyze Network Policies:**
   ```bash
   kubectl get networkpolicy -A
   kubectl describe networkpolicy <policy-name>
   ```

3. **Use Network Policy Testing Tools:**
   Deploy netshoot for advanced debugging:
   ```bash
   kubectl run netshoot --rm -i --tty --image nicolaka/netshoot
   ```

## 5. External Database via VPN Architecture

**High-Level Architecture:**
```yaml
# VPN Gateway Pod (HA)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vpn-gateway
spec:
  replicas: 2
  selector:
    matchLabels:
      app: vpn-gateway
  template:
    spec:
      containers:
      - name: strongswan
        image: strongswan:latest
        securityContext:
          capabilities:
            add: ["NET_ADMIN"]
        volumeMounts:
        - name: vpn-config
          mountPath: /etc/ipsec.d
      volumes:
      - name: vpn-config
        secret:
          secretName: vpn-credentials
```

**Security & HA Considerations:**
- Use NetworkPolicies to restrict VPN gateway access
- Implement VPN connection health checks
- Use secrets for VPN credentials with encryption at rest
- Deploy VPN gateways across multiple AZs
- Implement connection pooling for database connections
- Use service mesh for mTLS between microservices and VPN gateway

## 6. Multi-Tenant EKS Platform

**Isolation Strategy:**

1. **Namespace-Level Isolation:**
   ```yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: tenant-a
     labels:
       tenant: tenant-a
   ```

2. **Resource Quotas:**
   ```yaml
   apiVersion: v1
   kind: ResourceQuota
   metadata:
     namespace: tenant-a
   spec:
     hard:
       requests.cpu: "4"
       requests.memory: 8Gi
       limits.cpu: "8"
       limits.memory: 16Gi
       pods: "20"
   ```

3. **Network Policies:**
   Default deny-all with explicit allow rules per tenant.

4. **RBAC:**
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: RoleBinding
   subjects:
   - kind: User
     name: tenant-a-admin
   roleRef:
     kind: ClusterRole
     name: tenant-admin
   ```

5. **Observability:**
   - Prometheus with tenant-specific ServiceMonitors
   - Grafana with tenant-specific dashboards
   - Centralized logging with tenant labels

6. **Security:**
   - Pod Security Standards/Policies
   - OPA Gatekeeper for policy enforcement
   - Image scanning and admission controllers

## 7. Kubelet Constant Restarts

**Investigation Steps:**

1. **Check System Resources:**
   ```bash
   top
   df -h
   free -m
   ```

2. **Examine Kubelet Logs:**
   ```bash
   journalctl -u kubelet -f
   systemctl status kubelet
   ```

3. **Check Node Conditions:**
   ```bash
   kubectl describe node <node-name>
   ```

4. **Verify Configuration:**
   ```bash
   cat /var/lib/kubelet/config.yaml
   ps aux | grep kubelet
   ```

**Common Issues & Fixes:**
- **Disk Pressure:** Clean up logs, images, or expand disk
- **Memory Pressure:** Adjust kubelet memory reserves
- **Certificate Issues:** Rotate kubelet certificates
- **CNI Problems:** Check network plugin configuration
- **Container Runtime Issues:** Restart containerd/docker service

## 8. Pod Eviction Prevention & QoS Classes

**QoS Classes:**

1. **Guaranteed:** Requests = Limits for CPU and Memory
2. **Burstable:** Has requests but limits ≠ requests
3. **BestEffort:** No requests or limits set

**Prevention Strategies:**

1. **Priority Classes:**
   ```yaml
   apiVersion: scheduling.k8s.io/v1
   kind: PriorityClass
   metadata:
     name: critical-priority
   value: 1000000
   globalDefault: false
   description: "Critical system pods"
   ```

2. **Resource Management:**
   ```yaml
   resources:
     requests:
       memory: "1Gi"
       cpu: "500m"
     limits:
       memory: "2Gi"
       cpu: "1000m"
   ```

3. **Node Resource Reservation:**
   Configure kubelet with `--system-reserved` and `--kube-reserved`.

4. **Pod Disruption Budgets:**
   ```yaml
   apiVersion: policy/v1
   kind: PodDisruptionBudget
   metadata:
     name: critical-app-pdb
   spec:
     minAvailable: 2
     selector:
       matchLabels:
         app: critical-app
   ```

## 9. TCP/UDP Same Port Configuration

**Service Configuration:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: dual-protocol-service
spec:
  selector:
    app: my-app
  ports:
  - name: tcp-port
    port: 8080
    protocol: TCP
    targetPort: 8080
  - name: udp-port
    port: 8080
    protocol: UDP
    targetPort: 8080
  type: LoadBalancer
```

**Ingress Limitations:**
Standard Ingress only supports HTTP/HTTPS. For TCP/UDP:
- Use LoadBalancer services
- Configure ingress controller (like NGINX) with TCP/UDP configmaps
- Consider service mesh for advanced routing

## 10. Zero-Downtime Deployment Strategies

**Advanced Strategies:**

1. **Blue-Green Deployments:**
   ```yaml
   # Use labels to switch traffic
   spec:
     selector:
       app: my-app
       version: blue  # Switch to green when ready
   ```

2. **Canary Deployments with Flagger:**
   ```yaml
   apiVersion: flagger.app/v1beta1
   kind: Canary
   spec:
     progressDeadlineSeconds: 60
     analysis:
       interval: 30s
       threshold: 5
       maxWeight: 50
       stepWeight: 10
   ```

3. **Readiness Gates:**
   ```yaml
   spec:
     readinessGates:
     - conditionType: "example.com/feature-1"
   ```

4. **Pre-Stop Hooks:**
   ```yaml
   lifecycle:
     preStop:
       exec:
         command: ["/bin/sh", "-c", "sleep 15"]
   ```

## 11. Service Mesh Sidecar Optimization

**Analysis Steps:**

1. **Resource Monitoring:**
   ```bash
   kubectl top pod --containers
   ```

2. **Envoy Admin Interface:**
   ```bash
   kubectl port-forward <pod> 15000:15000
   curl localhost:15000/stats
   ```

**Optimization Techniques:**
- Reduce Envoy memory limits
- Tune connection pool settings
- Optimize tracing sampling rates
- Use resource limits on sidecars
- Consider sidecar-less service mesh options (Cilium Service Mesh)

## 12. Kubernetes Operator Design

**CRD Example:**
```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: myapps.example.com
spec:
  group: example.com
  versions:
  - name: v1
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              replicas:
                type: integer
              version:
                type: string
          status:
            type: object
            properties:
              phase:
                type: string
```

**Controller Logic:**
- Implement reconciliation loop
- Use controller-runtime framework
- Handle events (create, update, delete)
- Implement proper error handling and retries
- Use finalizers for cleanup operations

## 13. Container Log Disk IO Management

**Solutions:**

1. **Log Rotation Configuration:**
   ```json
   {
     "log-driver": "json-file",
     "log-opts": {
       "max-size": "10m",
       "max-file": "3"
     }
   }
   ```

2. **Centralized Logging:**
   Deploy Fluent Bit or Fluentd to ship logs to external systems.

3. **Volume Mounts for Logs:**
   ```yaml
   volumeMounts:
   - name: log-volume
     mountPath: /var/log
   ```

4. **Node-Level Monitoring:**
   Monitor disk usage with Prometheus node-exporter.

## 14. etcd Performance & High Availability

**Root Causes:**
- Large key-value pairs
- Excessive watch operations
- Disk IO bottlenecks
- Network latency between etcd members

**Solutions:**

1. **etcd Tuning:**
   ```bash
   # Defragmentation
   etcdctl defrag --cluster

   # Compaction
   etcdctl compact <revision>
   ```

2. **Hardware Optimization:**
   - Use SSD storage
   - Dedicated etcd nodes
   - Low-latency networking

3. **HA Configuration:**
   - Odd number of etcd members (3 or 5)
   - Spread across availability zones
   - Regular backups with etcdctl snapshot

## 15. Trusted Registry Policy Enforcement

**Implementation Options:**

1. **OPA Gatekeeper:**
   ```yaml
   apiVersion: templates.gatekeeper.sh/v1beta1
   kind: ConstraintTemplate
   metadata:
     name: allowedregistries
   spec:
     crd:
       spec:
         names:
           kind: AllowedRegistries
         validation:
           properties:
             registries:
               type: array
               items:
                 type: string
   ```

2. **Pod Security Policy (deprecated) / Pod Security Standards:**
   Use admission controllers to enforce image registry restrictions.

3. **Image Scanning Integration:**
   Integrate with tools like Twistlock, Aqua, or Falco to scan images before deployment.

## 16. Multi-Region Single Control Plane

**Architectural Considerations:**

**Challenges:**
- Cross-region latency affects etcd performance
- Single point of failure for control plane
- Network partitioning risks

**Solutions:**
1. **Regional Node Groups:**
   Deploy worker nodes regionally but accept control plane latency.

2. **Edge Clusters:**
   Use lightweight Kubernetes distributions (k3s) for edge locations.

3. **Federation/Multi-Cluster:**
   Consider Admiralty, Submariner, or service mesh federation.

4. **Data Locality:**
   - Use nodeAffinity for data-sensitive workloads
   - Implement regional storage classes
   - Cache frequently accessed data locally

## 17. Ingress Controller Performance Under Load

**Diagnosis:**

1. **Monitor Ingress Metrics:**
   ```bash
   kubectl get --raw /metrics | grep nginx
   ```

2. **Check Resource Usage:**
   ```bash
   kubectl top pod -n ingress-nginx
   ```

3. **Analyze Request Patterns:**
   Review access logs for patterns and bottlenecks.

**Scaling Solutions:**

1. **Horizontal Scaling:**
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nginx-ingress-controller
   spec:
     replicas: 5  # Scale based on load
   ```

2. **Resource Optimization:**
   ```yaml
   resources:
     requests:
       cpu: 500m
       memory: 512Mi
     limits:
       cpu: 2000m
       memory: 2Gi
   ```

3. **Load Balancer Configuration:**
   - Use multiple ingress controllers
   - Configure session affinity appropriately
   - Implement proper health checks

4. **Advanced Features:**
   - Enable rate limiting
   - Configure connection pooling
   - Use proxy protocol for real client IPs
   - Implement circuit breakers

## Additional Production Best Practices

### Monitoring & Observability
- Implement comprehensive metrics (RED/USE methodology)
- Set up proper alerting with runbooks
- Use distributed tracing for complex transactions
- Monitor resource utilization trends

### Security
- Regular security scanning
- Implement network segmentation
- Use service accounts with minimal privileges
- Regular certificate rotation

### Operational Excellence
- Implement GitOps workflows
- Automate routine operations
- Maintain disaster recovery procedures
- Regular chaos engineering exercises

### Performance Optimization
- Right-size resource requests/limits
- Use horizontal pod autoscaling
- Implement proper caching strategies
- Optimize container images for size and security