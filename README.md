# Production-Grade GitOps Platform

An end-to-end, highly available cloud-native platform deployed on AWS. This repository demonstrates a complete DevOps lifecycle, from Infrastructure as Code (IaC) to automated CI/CD pipelines, container orchestration, and GitOps continuous delivery.

## 🏗️ Architecture & Tech Stack

- **Cloud Provider:** AWS
- **Infrastructure as Code:** Terraform
- **Containerization:** Docker (Multi-stage Alpine builds)
- **CI/CD:** GitHub Actions (with AWS OIDC Federation)
- **Container Registry:** Amazon ECR
- **Orchestration & Delivery (Upcoming):** Amazon EKS, Helm, ArgoCD
- **Observability (Upcoming):** Prometheus, Grafana, Loki
- **Security (Upcoming):** Trivy, Checkov

---

## 🚀 Current Implementation Status

### Phase 1: Terraform Foundation (Completed)
Architected a resilient, multi-tier AWS network topology using decoupled Terraform modules.
- **Networking:** Provisioned isolated Public, Private, and Data subnets across multiple Availability Zones.
- **Security:** Deployed a strict Bastion proxy jump and minimal-privilege Security Groups.
- **Data Layer:** Provisioned a secure, private RDS PostgreSQL instance.
- **State Management:** Implemented remote state via Amazon S3 with versioning and state locking to prevent execution collisions.

### Phase 2: Containers & CI/CD (Completed)
Engineered an automated, zero-trust deployment pipeline.
- **Dockerization:** Wrote multi-stage Dockerfiles optimizing build caching and reducing the final production image footprint by over 60%.
- **OIDC Authentication:** Configured GitHub Actions to assume temporary AWS IAM roles via OpenID Connect, eliminating long-lived credentials from repository secrets.
- **Automated Pipeline:** Structured a strict quality gate pipeline (Test → Build → Push) that tags images with immutable git-SHAs and pushes them to Amazon ECR.

---

## 🗺️ Project Roadmap

This project is being developed in iterative phases to mimic a real-world enterprise platform rollout:

- [x] **Phase 1:** AWS Infrastructure Foundation (Terraform)
- [x] **Phase 2:** Containerization & Continuous Integration (Docker, GH Actions, ECR)
- [ ] **Phase 3:** Kubernetes on EKS (Provisioning cluster, deploying via Helm)
- [ ] **Phase 4:** GitOps Continuous Delivery (Decoupling CI/CD with ArgoCD)
- [ ] **Phase 5:** Observability Stack (Metrics and log aggregation via Prometheus/Grafana)
- [ ] **Phase 6:** DevSecOps (Integrating Trivy image scanning and Checkov IaC analysis)
- [ ] **Phase 7:** Platform Polish & Cost Optimization

---

## 📂 Repository Structure

```text
.
├── .github/
│   └── workflows/
│       └── ci.yml                # CI pipeline (Test, Build, Push to ECR)
├── app/                          # Application source code
│   ├── Dockerfile                # Multi-stage production container
│   ├── docker-compose.yml        # Local development environment
│   └── ...
└── terraform/
    ├── environments/
    │   └── dev/                  # Environment-specific configuration and state
    └── modules/
        ├── compute/              # Bastion, App instances, ALB
        ├── data/                 # RDS Postgres, ECR, S3
        ├── networking/           # VPC, Subnets, IGW, NAT
        └── security-groups/      # Stateful firewall rules

```

---

## 🛠️ Usage & Deployment

### Infrastructure Deployment

The infrastructure is modular and managed via Terraform.

1. Ensure AWS CLI is configured with the appropriate profile.
2. Initialize the backend:
```bash
cd terraform/environments/dev
terraform init
```


3. Review and apply the infrastructure:
```bash
terraform plan -out=tfplan
terraform apply tfplan
```



### CI/CD Pipeline

The GitHub Actions workflow triggers automatically on pushes and pull requests to the `main` branch. It executes local tests, builds the Docker image utilizing the GitHub Actions cache (`type=gha`), authenticates to AWS via OIDC, and pushes the immutable artifact to ECR.

