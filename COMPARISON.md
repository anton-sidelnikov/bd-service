# Architecture Comparison: Serverless Lambda vs EC2 vs EKS

This document compares our current solution using **AWS Lambda + API Gateway + DynamoDB** with other common deployment options like **EC2** and **EKS (Kubernetes on AWS)**.

---

## Current Solution: AWS Lambda + API Gateway

| Feature                  | Description                                    |
|--------------------------|------------------------------------------------|
| **Execution Model**      | Event-driven, on-demand (serverless)           |
| **Infra Management**     | Fully managed by AWS                           |
| **Auto-scaling**         | Native and instant                             |
| **Billing**              | Pay-per-invocation (ms granularity)            |
| **Deployments**          | Terraform-managed Lambda versions + alias      |
| **Zero-Downtime**        | Alias-based rollout with health checks         |
| **Security**             | Scoped IAM, API Gateway auth, OIDC deploy role |
| **Operational Overhead** | Extremely low                                  |

### Pros
- Instant auto-scaling (per request)
- No idle cost — perfect for low/moderate traffic
- Easy to apply least-privilege IAM policies
- Easy to rollback via alias/versioning
- Test and promote per PR using Terraform workspaces

### Cons
- Cold starts possible (mitigated with provisioned concurrency if needed)
- Limited runtime environment and execution time (15 min max)

---

## Option 1: EC2 (Virtual Machines)

| Feature              | Description                                  |
|----------------------|----------------------------------------------|
| **Execution Model**  | Always-on servers                            |
| **Infra Management** | You manage OS, patching, scaling             |
| **Auto-scaling**     | EC2 ASG (manual setup needed)                |
| **Billing**          | Per-hour or per-second billing               |
| **Deployments**      | Manual or via SSM / CodeDeploy / Ansible     |
| **Zero-Downtime**    | Requires load balancer + deployment strategy |
| **Security**         | Requires OS hardening + IAM                  |

### Pros
- Full control over OS/runtime
- Familiar and flexible

### Cons
- Always-on billing (even idle)
- Higher operational burden
- Harder to scale/test per PR
- Slow deployment and rollback

---

## Option 2: EKS (Kubernetes on AWS)

| Feature              | Description                                        |
|----------------------|----------------------------------------------------|
| **Execution Model**  | Container orchestration via Kubernetes             |
| **Infra Management** | AWS manages control plane, you manage worker nodes |
| **Auto-scaling**     | Horizontal Pod Autoscaler + Cluster Autoscaler     |
| **Billing**          | Pay for nodes (even idle) + control plane          |
| **Deployments**      | CI/CD via ArgoCD, Helm, or kubectl                 |
| **Zero-Downtime**    | Rolling updates with health checks                 |
| **Security**         | Requires RBAC + network policies                   |

### Pros
- Fine-grained control over scaling, deployment, networking
- Suitable for complex microservice architectures
- Portable across clouds with same K8s stack

### Cons
- Steep learning curve (K8s, Helm, etc.)
- Complex to manage + costly for small workloads
- Not cost-efficient for burst/low-traffic apps

---

## Summary Comparison Table

| Feature               | Lambda                     | EC2                          | EKS                             |
|-----------------------|----------------------------|------------------------------|---------------------------------|
| Infra Management      | AWS-managed                | Manual                       | Shared (AWS + Manual)           |
| Scaling               | Auto (per-invocation)      | Manual / ASG                 | Auto (pods/nodes)               |
| Cold Start            | Possible (ms-sec)          | N/A                          | N/A                             |
| Cost Efficiency       | Very high (pay-per-use)    | Low for burst workloads      | Moderate/low for small loads    |
| Zero Downtime Deploys | via aliases                | Manual                       | Rolling deployments             |
| CI/CD Integration     | Terraform + GitHub Actions | SSH / SSM / Ansible ...      | ArgoCD / Helm / kubectl         |
| Security Model        | Fine-grained IAM           | OS-level + IAM               | RBAC + IAM + Network Policies   |
| Best For              | APIs, event-driven logic   | Full control, legacy systems | Large-scale, multi-service apps |

---

## Cost Comparison

| Cost Factor                 | Lambda                   | EC2                           | EKS                                  |
|-----------------------------|--------------------------|-------------------------------|--------------------------------------|
| Idle Cost                   | $0                       | Charged hourly                | Charged per node                     |
| Billing Granularity         | Per ms / invocation      | Per second                    | Per second (node level)              |
| Storage                     | S3 / DynamoDB separately | EBS volumes                   | EBS volumes / K8s Persistent Volumes |
| Scaling Cost                | Scales by invocations    | Must size EC2 or ASG manually | Pay for over-provisioned node pool   |
| Cost for small PR test envs | Low                      | Expensive (full VM per PR)    | Moderate (each PR = pod/node)        |

**Lambda is by far the most cost-efficient option** for services with low-to-medium usage and burst or intermittent workloads.

---

## Deployment Latency Comparison

| Stage                        | Lambda               | EC2                       | EKS                            |
|------------------------------|----------------------|---------------------------|--------------------------------|
| Code packaging time          | ~5s (zip + upload)   | Depends (SSM/rsync)       | Docker build + push (10–60s)   |
| Infra apply (Terraform)      | ~10–30s              | ~30–60s                   | ~1–2 min                       |
| Time to be live              | ~1s via alias switch | ELB propagation delay     | Rolling update (pods replaced) |
| Rollback speed               | Instant via alias    | Manual + restart required | Re-deploy previous image       |
| Parallel PR test env support | Workspace-based      | Complex and heavy         | Possible, but infra-heavy      |

---

## Why Lambda Was Chosen

**AWS Lambda** because:

- Zero-maintenance & cost-efficient for event-driven workloads
- Seamless scaling without capacity planning
- Native support for CI/CD, versioning, and rollback
- Ideal for lightweight APIs with DynamoDB storage
- Best-in-class for PR-based ephemeral environments
- Low-latency and safe deployments with alias-based promotion
