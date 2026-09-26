# Production-Grade GitOps Platform

An end-to-end, highly available cloud-native platform deployed on AWS. This repository demonstrates a complete DevOps lifecycle, from Infrastructure as Code (IaC) to automated CI/CD pipelines, container orchestration, and GitOps continuous delivery.

## 🗺️ Architecture

![Architecture diagram: GitHub Actions builds and pushes to ECR via OIDC, then deploys over SSH through a bastion to an app EC2 instance in a private subnet, which talks to RDS Postgres in a data subnet](docs/architecture.svg)

Traffic is bounded by security groups at every hop: the ALB accepts public HTTP/HTTPS, the app server only accepts traffic from the ALB and the bastion, and RDS only accepts traffic from the app server. The app server and database sit in private/data subnets with no direct internet inbound.

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
- **Automated Pipeline:** Structured a strict quality gate pipeline (Test → Build → Push → Deploy) that tags images with immutable git-SHAs, pushes them to Amazon ECR, then runs an Ansible playbook (SSH via the bastion) to pull and run the new image on the app server.

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
    │   └── dev/                  # Sole environment entry point (calls the shared modules)
    └── modules/
        ├── compute/              # Bastion, App instances, ALB
        ├── data/                 # RDS Postgres, ECR
        ├── networking/           # VPC, Subnets, IGW, NAT
        └── security-groups/      # Stateful firewall rules

```

`terraform/environments/dev` is the only environment wired up right now — run all Terraform commands from there. A `prod` environment will be added the same way (reusing the shared modules) when it's actually needed.

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

The GitHub Actions workflow triggers automatically on pushes and pull requests to the `main` branch. It executes local tests, builds the Docker image utilizing the GitHub Actions cache (`type=gha`), authenticates to AWS via OIDC, and pushes the immutable artifact to ECR. On a push (not PRs), a final `deploy` job runs the Ansible `app_servers` playbook over SSH via the bastion to pull and run the new image on the app server.

The deploy job needs one additional repository secret beyond `ECR_REPOSITORY_URL` and `AWS_ACCOUNT_ID`:

- `BASTION_SSH_PRIVATE_KEY` — the private half of the `gitops-platform` key pair registered in the `iam` module, used to SSH-proxy through the bastion to the private app server.

### Terraform Pipeline

A second workflow ([`terraform.yml`](.github/workflows/terraform.yml)) plans and applies infrastructure changes:

- **Any PR touching `terraform/**`** runs `terraform plan` using a **read-only** OIDC role (`gitops-platform-tf-plan-role`) and posts the plan as a PR comment — safe even on a PR from a fork, since it can't change anything.
- **A push to `main`** re-runs that same read-only plan, uploads it as an artifact, then a second job downloads it and runs `terraform apply` on the *exact* reviewed plan using a separate, more privileged OIDC role (`gitops-platform-tf-apply-role`). That job targets the `dev` GitHub Environment, which requires manual approval before it's allowed to run — merging to `main` never silently changes infrastructure.

### Branching Strategy

Trunk-based, not GitFlow: one long-lived `main` branch, short-lived feature branches merged via PR. Environments are promotion targets gated by required reviewers on a GitHub Environment (`dev` today; `prod` the same way once it exists), not separate long-lived branches — this matches the GitOps direction the later phases (ArgoCD) are already headed in.

