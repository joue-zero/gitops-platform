# gitops-app

Helm chart for the gitops-platform Node.js health-check service (`app/` in this repository).

It renders a hardened, highly available Deployment plus the objects around it: Service, ConfigMap, ServiceAccount, PodDisruptionBudget, and optional Ingress and HorizontalPodAutoscaler.

## Design decisions

| Decision | Why |
|---|---|
| Non-root, read-only root filesystem, all capabilities dropped, `RuntimeDefault` seccomp | Least privilege by default. `runAsUser` is numeric because the image's `USER node` is a name, which the kubelet cannot check against `runAsNonRoot`. |
| `/tmp` is a small in-memory `emptyDir` | The root filesystem is read-only, but libraries still occasionally need scratch space. |
| Startup, liveness and readiness probes on `/health` | Slow starts are not mistaken for crashes; traffic only reaches ready pods. |
| `maxUnavailable: 0` rolling updates plus a `preStop` pause | Zero-downtime releases; the load balancer stops routing before SIGTERM arrives. |
| PodDisruptionBudget and zone/node topology spread | Node drains and AZ failures cannot take every replica down together. |
| `checksum/config` pod annotation | Pods restart automatically when the ConfigMap changes. |
| ServiceAccount token not mounted | The app never calls the Kubernetes API. |
| The chart never creates Secrets | Secret material does not belong in Git. Reference an existing Secret with `existingSecret`. |
| `values.schema.json` with `additionalProperties: false` | Typos and wrong types fail at render time instead of being silently ignored. |
| `image.repository` is required, tag defaults to `appVersion` | No environment-specific registry is baked into the chart; releases pin the immutable git SHA tag. |

## Accepted trade-offs

The rendered manifests are also scored with [`kube-score`](https://github.com/zegl/kube-score). Four of its checks are disabled in CI on purpose, each for a stated reason, rather than the gate being loosened globally:

| Check | Why it is accepted |
|---|---|
| `container-security-context-user-group-id` (UID/GID above 10000) | The image's `USER node` is fixed at uid 1000. Moving to a high UID is an image change (Dockerfile) and belongs with the next app release, not this chart. |
| `pod-probes-identical` | The app exposes a single `/health` endpoint and has no dependencies yet. Split into `/health/live` and `/health/ready` when the database is wired in. |
| `container-image-pull-policy` | The advice targets mutable tags. Tags here are immutable git SHAs in an `IMMUTABLE` ECR repository, so `IfNotPresent` is correct. |
| `deployment-has-host-podantiaffinity` | Topology spread constraints (zone and node) provide the same guarantee and are already enabled. |

## Usage

Render locally (the repository has no default, so supply one):

```bash
helm template gitops-app helm/app \
  --set image.repository=<account>.dkr.ecr.<region>.amazonaws.com/gitops-platform/app \
  --set image.tag=<git-sha>
```

In the cluster this chart is deployed by Argo CD, not by `helm install`. Environment values live in the [`gitops-platform-config`](https://github.com/joue-zero/gitops-platform-config) repository.

## Quality gates

`helm lint --strict`, Kubernetes API schema validation (`kubeconform`) and `kube-score` run in CI for two value sets in [`ci/`](ci/): the minimal defaults and a "full" set with every optional feature enabled.

## Values

| Key | Default | Description |
|---|---|---|
| `replicaCount` | `2` | Replicas (ignored while autoscaling is enabled) |
| `image.repository` | `""` | Full image repository. **Required.** |
| `image.tag` | `""` | Image tag, falls back to `appVersion` |
| `image.pullPolicy` | `IfNotPresent` | Safe because ECR tags are immutable |
| `containerPort` | `8080` | Port the app listens on; also written to the ConfigMap as `PORT` |
| `config` | `{NODE_ENV: production}` | Extra environment variables from a ConfigMap |
| `existingSecret` | `""` | Existing Secret injected with `envFrom` |
| `serviceAccount.create` | `true` | Create a ServiceAccount |
| `serviceAccount.automount` | `false` | Mount the API token |
| `serviceAccount.annotations` | `{}` | e.g. `eks.amazonaws.com/role-arn` for IRSA |
| `podSecurityContext` / `securityContext` | hardened | See `values.yaml` |
| `service.type` / `service.port` | `ClusterIP` / `80` | Service exposure |
| `ingress.enabled` | `false` | Create an Ingress |
| `ingress.className` | `""` | e.g. `alb` |
| `ingress.annotations` | `{}` | Controller-specific annotations |
| `ingress.hosts` / `ingress.tls` | catch-all `/` | Routing rules and TLS |
| `resources` | 50m/64Mi/64Mi-storage requests, 250m/128Mi/256Mi-storage limits | Container resources |
| `startupProbe` / `livenessProbe` / `readinessProbe` | `/health` | Health probes |
| `lifecycle` | `preStop: sleep 5` | Connection-drain pause |
| `strategy` | rolling, `maxUnavailable: 0` | Update strategy |
| `autoscaling.enabled` | `false` | Create an HPA (needs metrics-server) |
| `podDisruptionBudget.enabled` | `true` | Create a PodDisruptionBudget |
| `topologySpread.enabled` | `true` | Soft spread across zones and nodes |
| `networkPolicy.enabled` | `true` | Restrict ingress to the container port and egress to cluster DNS (enforced only if the CNI supports it) |
| `networkPolicy.ingressFrom` | `[]` | Allowed sources; empty allows any source on the port |
| `networkPolicy.extraEgress` | `[]` | Extra egress rules, e.g. the database later |
| `nodeSelector` / `tolerations` / `affinity` | empty | Scheduling controls |
| `testImage` | busybox from ECR Public | Image for `helm test` |
