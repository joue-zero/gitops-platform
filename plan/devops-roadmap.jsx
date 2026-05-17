import { useState } from "react";

const PROJECT = {
  title: "Production-Grade GitOps Platform",
  tagline: "One project. Full DevOps lifecycle. CV-ready in 8–12 weeks.",
  description:
    "A self-hosted microservices app deployed to AWS with full CI/CD, IaC, container orchestration, observability, and security hardening. Every layer maps directly to what hiring managers look for in 1–2 YOE DevOps roles in Cairo.",
  stack: [
    { name: "GitHub Actions", role: "CI/CD pipelines", yours: true },
    { name: "Docker", role: "Containerization + multi-stage builds", yours: true },
    { name: "Terraform", role: "AWS infrastructure provisioning (IaC)", yours: true },
    { name: "Ansible", role: "Server config management + AMI baking", yours: true },
    { name: "Kubernetes (EKS)", role: "Container orchestration", yours: true },
    { name: "AWS (EC2, S3, RDS, EKS, IAM, VPC)", role: "Cloud infrastructure", yours: true },
    { name: "Helm", role: "K8s package management", yours: false },
    { name: "ArgoCD", role: "GitOps continuous delivery", yours: false },
    { name: "Prometheus + Grafana", role: "Metrics & dashboards", yours: false },
    { name: "ELK / Loki", role: "Centralized logging", yours: false },
    { name: "Trivy / Checkov", role: "Security scanning (DevSecOps)", yours: false },
    { name: "SonarQube", role: "Code quality gates in CI", yours: false },
  ],
};

const PHASES = [
  {
    id: 1,
    title: "Foundation",
    duration: "Week 1–2",
    color: "#00D4FF",
    deliverable: "Terraform-provisioned AWS VPC with bastion, public/private subnets, RDS, S3",
    tasks: [
      "Write Terraform modules: VPC, subnets, security groups, IAM roles",
      "Provision EC2 bastion + private app servers",
      "RDS (Postgres) in private subnet",
      "Remote state in S3 + DynamoDB locking",
      "Ansible playbook to configure servers (install Docker, set users, harden SSH)",
    ],
    gap: "Terraform modules structure, remote state, Ansible roles vs playbooks",
    cvline: "Provisioned multi-tier AWS infrastructure using Terraform with remote state management and Ansible for configuration management",
  },
  {
    id: 2,
    title: "Containers & Registry",
    duration: "Week 3",
    color: "#FF6B35",
    deliverable: "Dockerized app pushed to ECR via GitHub Actions",
    tasks: [
      "Multi-stage Dockerfiles for a simple Node/Python app (or reuse your Laravel app)",
      "AWS ECR as private registry",
      "GitHub Actions workflow: lint → test → build → push to ECR",
      "Docker Compose for local dev parity",
    ],
    gap: "ECR auth in CI, multi-arch builds, layer caching strategy",
    cvline: "Built multi-stage Docker images with GitHub Actions CI pushing to AWS ECR with layer caching",
  },
  {
    id: 3,
    title: "Kubernetes on EKS",
    duration: "Week 4–5",
    color: "#7C3AED",
    deliverable: "App running on EKS cluster with Helm charts",
    tasks: [
      "Provision EKS cluster with Terraform (eksctl or terraform-aws-eks module)",
      "Write Helm chart: Deployment, Service, Ingress, ConfigMap, Secrets",
      "NGINX Ingress Controller + AWS Load Balancer",
      "Horizontal Pod Autoscaler (HPA)",
      "Namespaces per environment (dev/staging/prod)",
    ],
    gap: "Helm chart structure, k8s RBAC, EKS node groups vs Fargate",
    cvline: "Deployed microservices on AWS EKS using Helm charts with HPA and NGINX Ingress",
  },
  {
    id: 4,
    title: "GitOps with ArgoCD",
    duration: "Week 6",
    color: "#10B981",
    deliverable: "ArgoCD auto-syncing cluster state from Git",
    tasks: [
      "Install ArgoCD on cluster",
      "Separate GitOps repo (app manifests only)",
      "GitHub Actions updates image tag in manifests repo → ArgoCD detects and deploys",
      "App of Apps pattern for multi-service management",
      "Rollback via Git revert",
    ],
    gap: "GitOps mental model, ArgoCD ApplicationSets, sync policies",
    cvline: "Implemented GitOps delivery with ArgoCD, decoupling CI (GitHub Actions) from CD (ArgoCD)",
  },
  {
    id: 5,
    title: "Observability",
    duration: "Week 7–8",
    color: "#F59E0B",
    deliverable: "Grafana dashboards showing cluster + app metrics and logs",
    tasks: [
      "Deploy kube-prometheus-stack via Helm (Prometheus + Grafana + Alertmanager)",
      "Custom app metrics (expose /metrics endpoint)",
      "Grafana dashboards: node health, pod restarts, request latency",
      "Loki + Promtail for log aggregation",
      "Slack/email alerts on pod crash / high CPU",
    ],
    gap: "PromQL queries, Grafana panel building, log label strategies",
    cvline: "Built observability stack with Prometheus, Grafana, and Loki; wrote PromQL alerts for SLO breach",
  },
  {
    id: 6,
    title: "DevSecOps",
    duration: "Week 9–10",
    color: "#EF4444",
    deliverable: "Security gates in CI + hardened infrastructure",
    tasks: [
      "Trivy: scan Docker images for CVEs in CI pipeline (fail on HIGH/CRITICAL)",
      "Checkov: scan Terraform code for misconfigurations",
      "SonarQube: code quality gate in GitHub Actions",
      "AWS IAM least-privilege audit",
      "Secrets management: AWS Secrets Manager or HashiCorp Vault",
    ],
    gap: "Vault setup, SAST/DAST concepts, CIS benchmark basics",
    cvline: "Integrated DevSecOps pipeline with Trivy image scanning, Checkov IaC analysis, and Vault secrets management",
  },
  {
    id: 7,
    title: "Polish & Document",
    duration: "Week 11–12",
    color: "#EC4899",
    deliverable: "Public GitHub repo, architecture diagram, README, blog post",
    tasks: [
      "Architecture diagram (draw.io or Excalidraw)",
      "README: problem → solution → architecture → how to run",
      "Cost estimate (AWS pricing)",
      "Record a 3-min Loom walkthrough",
      "Write a dev.to / Hashnode post about one hard problem you solved",
    ],
    gap: "Technical writing, architecture diagramming conventions",
    cvline: "Documented end-to-end GitOps platform with architecture diagrams and a published technical write-up",
  },
];

const GAPS = [
  { tool: "Helm", priority: "High", week: "4–5", why: "Every k8s job uses it. Non-negotiable." },
  { tool: "ArgoCD", priority: "High", week: "6", why: "GitOps is the standard CD pattern now." },
  { tool: "Prometheus/Grafana", priority: "High", week: "7–8", why: "Observability is asked in every interview." },
  { tool: "Trivy / Checkov", priority: "Medium", week: "9", why: "DevSecOps differentiates you from pure infra people." },
  { tool: "Linux (advanced)", priority: "Medium", week: "ongoing", why: "systemd, cgroups, namespaces — k8s runs on these." },
  { tool: "Networking (VPC/DNS)", priority: "Medium", week: "1–2", why: "Debugging prod issues is impossible without this." },
  { tool: "SonarQube", priority: "Low", week: "9–10", why: "Nice-to-have for code quality gates in pipeline." },
];

export default function App() {
  const [activePhase, setActivePhase] = useState(null);
  const [tab, setTab] = useState("phases");

  const phase = PHASES.find((p) => p.id === activePhase);

  return (
    <div style={{
      minHeight: "100vh",
      background: "#0A0A0F",
      color: "#E2E2E8",
      fontFamily: "'DM Mono', 'Fira Code', monospace",
      padding: "0",
      overflowX: "hidden",
    }}>
      {/* Google Fonts */}
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Mono:ital,wght@0,300;0,400;0,500;1,300&family=Syne:wght@700;800&display=swap');

        * { box-sizing: border-box; }

        .phase-card {
          border: 1px solid #1E1E2E;
          border-radius: 4px;
          padding: 16px 20px;
          cursor: pointer;
          transition: all 0.2s;
          background: #0D0D14;
        }
        .phase-card:hover {
          background: #12121C;
          transform: translateX(4px);
        }
        .phase-card.active {
          background: #12121C;
          transform: translateX(4px);
        }
        .tag {
          display: inline-block;
          padding: 2px 8px;
          border-radius: 2px;
          font-size: 11px;
          font-weight: 500;
          letter-spacing: 0.08em;
        }
        .tab-btn {
          background: none;
          border: none;
          color: #555566;
          font-family: inherit;
          font-size: 12px;
          letter-spacing: 0.12em;
          text-transform: uppercase;
          padding: 8px 16px;
          cursor: pointer;
          border-bottom: 2px solid transparent;
          transition: all 0.15s;
        }
        .tab-btn.active {
          color: #E2E2E8;
          border-bottom-color: #00D4FF;
        }
        .tab-btn:hover:not(.active) {
          color: #9999AA;
        }
        .stack-pill {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          padding: 4px 10px;
          border-radius: 2px;
          font-size: 12px;
          margin: 3px;
        }
        .task-item::before {
          content: '→';
          color: #00D4FF;
          margin-right: 8px;
          flex-shrink: 0;
        }
        .task-item {
          display: flex;
          font-size: 13px;
          color: #AAAABB;
          padding: 5px 0;
          line-height: 1.5;
        }
        .priority-high { color: #EF4444; }
        .priority-medium { color: #F59E0B; }
        .priority-low { color: #10B981; }

        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-track { background: #0A0A0F; }
        ::-webkit-scrollbar-thumb { background: #2A2A3A; border-radius: 2px; }
      `}</style>

      {/* Header */}
      <div style={{
        borderBottom: "1px solid #1A1A2A",
        padding: "40px 40px 32px",
        background: "linear-gradient(180deg, #0D0D18 0%, #0A0A0F 100%)",
      }}>
        <div style={{ maxWidth: 900 }}>
          <div style={{ fontSize: 11, letterSpacing: "0.2em", color: "#00D4FF", textTransform: "uppercase", marginBottom: 12 }}>
            DevOps Portfolio Blueprint · Cairo Market · 2025–2026
          </div>
          <h1 style={{
            fontFamily: "'Syne', sans-serif",
            fontSize: "clamp(28px, 5vw, 48px)",
            fontWeight: 800,
            margin: "0 0 12px",
            lineHeight: 1.1,
            letterSpacing: "-0.02em",
          }}>
            {PROJECT.title}
          </h1>
          <p style={{ color: "#6666AA", fontSize: 14, margin: "0 0 24px", maxWidth: 620, lineHeight: 1.7 }}>
            {PROJECT.description}
          </p>

          {/* Quick stats */}
          <div style={{ display: "flex", gap: 32, flexWrap: "wrap" }}>
            {[
              { label: "Phases", val: "7" },
              { label: "Timeline", val: "10–12 wks" },
              { label: "New tools", val: "6" },
              { label: "CV lines", val: "7" },
            ].map(s => (
              <div key={s.label}>
                <div style={{ fontFamily: "'Syne', sans-serif", fontSize: 28, fontWeight: 700, color: "#00D4FF", lineHeight: 1 }}>{s.val}</div>
                <div style={{ fontSize: 11, color: "#44445A", letterSpacing: "0.1em", textTransform: "uppercase", marginTop: 4 }}>{s.label}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ borderBottom: "1px solid #1A1A2A", padding: "0 40px", display: "flex", gap: 4 }}>
        {[
          { id: "phases", label: "Phases" },
          { id: "stack", label: "Full Stack" },
          { id: "gaps", label: "Gaps to Fill" },
          { id: "cv", label: "CV Lines" },
        ].map(t => (
          <button key={t.id} className={`tab-btn ${tab === t.id ? "active" : ""}`} onClick={() => { setTab(t.id); setActivePhase(null); }}>
            {t.label}
          </button>
        ))}
      </div>

      <div style={{ maxWidth: 900, margin: "0 auto", padding: "32px 40px" }}>

        {/* PHASES TAB */}
        {tab === "phases" && (
          <div style={{ display: "grid", gridTemplateColumns: activePhase ? "1fr 1fr" : "1fr", gap: 24 }}>
            {/* Phase list */}
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              {PHASES.map(p => (
                <div
                  key={p.id}
                  className={`phase-card ${activePhase === p.id ? "active" : ""}`}
                  onClick={() => setActivePhase(activePhase === p.id ? null : p.id)}
                  style={{ borderLeftColor: p.color, borderLeftWidth: 3 }}
                >
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 6 }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                      <span style={{ fontFamily: "'Syne', sans-serif", fontSize: 11, color: p.color, fontWeight: 700, letterSpacing: "0.1em" }}>
                        {String(p.id).padStart(2, "0")}
                      </span>
                      <span style={{ fontFamily: "'Syne', sans-serif", fontSize: 15, fontWeight: 700 }}>{p.title}</span>
                    </div>
                    <span style={{ fontSize: 11, color: "#44445A", whiteSpace: "nowrap", marginLeft: 12 }}>{p.duration}</span>
                  </div>
                  <div style={{ fontSize: 12, color: "#666680", lineHeight: 1.5, paddingLeft: 22 }}>{p.deliverable}</div>
                </div>
              ))}
            </div>

            {/* Phase detail */}
            {phase && (
              <div style={{ background: "#0D0D14", border: "1px solid #1E1E2E", borderRadius: 4, padding: 24, position: "sticky", top: 20, alignSelf: "start" }}>
                <div style={{ fontSize: 11, letterSpacing: "0.15em", color: phase.color, textTransform: "uppercase", marginBottom: 8 }}>
                  Phase {phase.id} · {phase.duration}
                </div>
                <h2 style={{ fontFamily: "'Syne', sans-serif", fontSize: 22, fontWeight: 700, margin: "0 0 8px" }}>{phase.title}</h2>
                <div style={{ fontSize: 12, color: "#666680", marginBottom: 20, lineHeight: 1.6, paddingBottom: 20, borderBottom: "1px solid #1E1E2E" }}>
                  Deliverable: <span style={{ color: "#AAAABB" }}>{phase.deliverable}</span>
                </div>

                <div style={{ marginBottom: 20 }}>
                  <div style={{ fontSize: 11, letterSpacing: "0.1em", color: "#44445A", textTransform: "uppercase", marginBottom: 10 }}>Tasks</div>
                  {phase.tasks.map((t, i) => (
                    <div key={i} className="task-item">{t}</div>
                  ))}
                </div>

                <div style={{ background: "#0A0A0F", border: "1px solid #1E1E2E", borderRadius: 3, padding: 14, marginBottom: 16 }}>
                  <div style={{ fontSize: 10, letterSpacing: "0.12em", color: "#F59E0B", textTransform: "uppercase", marginBottom: 6 }}>Gap to fill</div>
                  <div style={{ fontSize: 12, color: "#AAAABB", lineHeight: 1.6 }}>{phase.gap}</div>
                </div>

                <div style={{ background: "#0A1A0A", border: "1px solid #1E3A1E", borderRadius: 3, padding: 14 }}>
                  <div style={{ fontSize: 10, letterSpacing: "0.12em", color: "#10B981", textTransform: "uppercase", marginBottom: 6 }}>CV line</div>
                  <div style={{ fontSize: 12, color: "#AAAABB", lineHeight: 1.6, fontStyle: "italic" }}>"{phase.cvline}"</div>
                </div>
              </div>
            )}
          </div>
        )}

        {/* STACK TAB */}
        {tab === "stack" && (
          <div>
            <div style={{ fontSize: 12, color: "#44445A", marginBottom: 24, lineHeight: 1.7 }}>
              Green = you already know it. Orange = you need to learn it. Every tool has a reason to be here.
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(260px, 1fr))", gap: 12 }}>
              {PROJECT.stack.map(s => (
                <div key={s.name} style={{
                  background: "#0D0D14",
                  border: `1px solid ${s.yours ? "#1A3A1A" : "#2A1A0A"}`,
                  borderRadius: 4,
                  padding: 16,
                }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
                    <span style={{ fontFamily: "'Syne', sans-serif", fontSize: 14, fontWeight: 700 }}>{s.name}</span>
                    <span className="tag" style={{
                      background: s.yours ? "#0A2A0A" : "#1A0A00",
                      color: s.yours ? "#10B981" : "#F59E0B",
                    }}>
                      {s.yours ? "✓ know" : "learn"}
                    </span>
                  </div>
                  <div style={{ fontSize: 12, color: "#555566", lineHeight: 1.5 }}>{s.role}</div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* GAPS TAB */}
        {tab === "gaps" && (
          <div>
            <div style={{ fontSize: 12, color: "#44445A", marginBottom: 24, lineHeight: 1.7 }}>
              These are the specific skills you need to learn through building this project. You don't study them in isolation — each one shows up in a phase.
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 1 }}>
              <div style={{ display: "grid", gridTemplateColumns: "1.5fr 80px 80px 2fr", gap: 16, padding: "8px 16px", fontSize: 10, letterSpacing: "0.12em", color: "#44445A", textTransform: "uppercase" }}>
                <span>Tool</span><span>Priority</span><span>Phase wk</span><span>Why it matters</span>
              </div>
              {GAPS.map(g => (
                <div key={g.tool} style={{
                  display: "grid",
                  gridTemplateColumns: "1.5fr 80px 80px 2fr",
                  gap: 16,
                  padding: "14px 16px",
                  background: "#0D0D14",
                  borderBottom: "1px solid #1A1A2A",
                  alignItems: "center",
                }}>
                  <span style={{ fontFamily: "'Syne', sans-serif", fontSize: 14, fontWeight: 700 }}>{g.tool}</span>
                  <span className={`priority-${g.priority.toLowerCase()}`} style={{ fontSize: 12, fontWeight: 500 }}>{g.priority}</span>
                  <span style={{ fontSize: 12, color: "#44445A" }}>{g.week}</span>
                  <span style={{ fontSize: 12, color: "#7777AA", lineHeight: 1.5 }}>{g.why}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* CV TAB */}
        {tab === "cv" && (
          <div>
            <div style={{ fontSize: 12, color: "#44445A", marginBottom: 24, lineHeight: 1.7 }}>
              After completing this project, these are your exact CV bullet points. Copy-paste them into your LaTeX CV.
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              {PHASES.map((p, i) => (
                <div key={p.id} style={{
                  background: "#0D0D14",
                  border: "1px solid #1E1E2E",
                  borderLeftColor: p.color,
                  borderLeftWidth: 3,
                  borderRadius: 4,
                  padding: "14px 18px",
                }}>
                  <div style={{ fontSize: 10, letterSpacing: "0.12em", color: p.color, textTransform: "uppercase", marginBottom: 6 }}>
                    Phase {p.id} — {p.title}
                  </div>
                  <div style={{ fontSize: 13, color: "#CCCCDD", lineHeight: 1.7, fontStyle: "italic" }}>
                    • {p.cvline}
                  </div>
                </div>
              ))}
            </div>

            <div style={{ marginTop: 32, padding: 20, background: "#0D0D14", border: "1px solid #1E1E2E", borderRadius: 4 }}>
              <div style={{ fontSize: 10, letterSpacing: "0.12em", color: "#00D4FF", textTransform: "uppercase", marginBottom: 12 }}>Project header line</div>
              <div style={{ fontSize: 13, color: "#CCCCDD", lineHeight: 1.8, fontStyle: "italic" }}>
                • <strong style={{ fontStyle: "normal" }}>Production GitOps Platform</strong> — Designed and deployed a full DevOps lifecycle system on AWS: Terraform-provisioned infrastructure, Dockerized microservices on EKS, GitOps CD with ArgoCD, observability with Prometheus/Grafana, and a DevSecOps pipeline with image scanning and secrets management.
              </div>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}
