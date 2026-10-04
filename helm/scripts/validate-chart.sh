#!/usr/bin/env bash
# Runs the chart quality gate, identically locally and in CI.
# Requires helm, kubeconform and kube-score on PATH. Override the schema version with K8S_VERSION.
set -euo pipefail

CHART_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../app" && pwd)"
K8S_VERSION="${K8S_VERSION:-1.33.0}"
RELEASE="gitops-app"
NAMESPACE="app"

# Disabled on purpose; the reasons are in helm/app/README.md.
KUBE_SCORE_IGNORES=(
  container-security-context-user-group-id
  pod-probes-identical
  container-image-pull-policy
  deployment-has-host-podantiaffinity
)
ignore_flags=()
for check in "${KUBE_SCORE_IGNORES[@]}"; do
  ignore_flags+=(--ignore-test "$check")
done

for tool in helm kubeconform kube-score; do
  command -v "$tool" >/dev/null || { echo "missing required tool: $tool" >&2; exit 1; }
done

shopt -s nullglob
value_files=("$CHART_DIR"/ci/*-values.yaml)
[ "${#value_files[@]}" -gt 0 ] || { echo "no value files found in $CHART_DIR/ci" >&2; exit 1; }

for values in "${value_files[@]}"; do
  echo "==> $(basename "$values")"

  echo "--- helm lint --strict"
  helm lint --strict "$CHART_DIR" -f "$values"

  echo "--- kubeconform (Kubernetes $K8S_VERSION)"
  helm template "$RELEASE" "$CHART_DIR" -f "$values" --namespace "$NAMESPACE" \
    | kubeconform -strict -summary -kubernetes-version "$K8S_VERSION" -

  # --skip-tests: the helm test hook pod is not a workload
  echo "--- kube-score"
  helm template "$RELEASE" "$CHART_DIR" -f "$values" --namespace "$NAMESPACE" --skip-tests \
    | kube-score score --kubernetes-version "v${K8S_VERSION%.*}" --exit-one-on-warning "${ignore_flags[@]}" -
done

echo "==> guard rails"
base="$CHART_DIR/ci/default-values.yaml"

if helm template "$RELEASE" "$CHART_DIR" >/dev/null 2>&1; then
  echo "FAIL: rendering without image.repository was accepted" >&2
  exit 1
fi
echo "ok: image.repository is required"

if helm template "$RELEASE" "$CHART_DIR" -f "$base" --set replicaCout=3 >/dev/null 2>&1; then
  echo "FAIL: values schema accepted an unknown key" >&2
  exit 1
fi
echo "ok: values schema rejects unknown keys"

if helm template "$RELEASE" "$CHART_DIR" -f "$base" --set service.port=http >/dev/null 2>&1; then
  echo "FAIL: values schema accepted a wrong type" >&2
  exit 1
fi
echo "ok: values schema rejects wrong types"

echo "All chart checks passed."
