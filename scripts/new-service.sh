#!/usr/bin/env bash
# new-service.sh — scaffold a new microservice in the fintech platform.
#
# Usage:
#   ./scripts/new-service.sh <service-name> [options]
#
# Options:
#   --port PORT        Container port the service listens on (default: 8080)
#   --wave WAVE        ArgoCD sync wave (default: 20)
#   --cloud-sql        Enable Cloud SQL Auth Proxy sidecar in chart values
#   --virtual-service  Enable Istio VirtualService with /SERVICE_NAME path prefix
#   --lang LANG        Language hint for CI (node|python|go|java; default: node)
#
# Example:
#   ./scripts/new-service.sh payment-service --port 8080 --cloud-sql --wave 25

set -euo pipefail

# ─── Argument parsing ────────────────────────────────────────────────────────
SERVICE_NAME=""
PORT=8080
WAVE=20
CLOUD_SQL=false
VIRTUAL_SERVICE=false
LANG="node"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --port)            PORT="$2";    shift 2 ;;
    --wave)            WAVE="$2";    shift 2 ;;
    --cloud-sql)       CLOUD_SQL=true; shift ;;
    --virtual-service) VIRTUAL_SERVICE=true; shift ;;
    --lang)            LANG="$2";   shift 2 ;;
    -*)
      echo "Unknown flag: $1" >&2
      exit 1
      ;;
    *)
      if [[ -z "$SERVICE_NAME" ]]; then
        SERVICE_NAME="$1"
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$SERVICE_NAME" ]]; then
  echo "Usage: $0 <service-name> [--port PORT] [--wave WAVE] [--cloud-sql] [--virtual-service] [--lang node|python|go|java]" >&2
  exit 1
fi

# Validate service name: lowercase letters, digits, hyphens only
if ! [[ "$SERVICE_NAME" =~ ^[a-z][a-z0-9-]+$ ]]; then
  echo "Error: service name must be lowercase alphanumeric + hyphens, starting with a letter." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCAFFOLD_DIR="${REPO_ROOT}/scaffold/chart-template"
CHART_DIR="${REPO_ROOT}/${SERVICE_NAME}/chart"
WORKFLOW_FILE="${REPO_ROOT}/.github/workflows/ci-${SERVICE_NAME}.yml"
ARGOCD_APP_FILE="${REPO_ROOT}/gitops-manifests-dev/apps/services/${SERVICE_NAME}.yaml"

# ─── Guard against overwriting existing work ────────────────────────────────
if [[ -d "$CHART_DIR" || -f "$WORKFLOW_FILE" || -f "$ARGOCD_APP_FILE" ]]; then
  echo "Error: one or more output paths already exist — refusing to overwrite." >&2
  echo "  $CHART_DIR" >&2
  echo "  $WORKFLOW_FILE" >&2
  echo "  $ARGOCD_APP_FILE" >&2
  exit 1
fi

echo "=> Scaffolding ${SERVICE_NAME} (port=${PORT}, wave=${WAVE}, cloud-sql=${CLOUD_SQL})"

# ─── 1. Copy and customise the Helm chart ────────────────────────────────────
cp -r "${SCAFFOLD_DIR}" "${CHART_DIR}"

# Rename service name placeholder in every file
find "${CHART_DIR}" -type f | while read -r file; do
  sed -i "s/SERVICE_NAME/${SERVICE_NAME}/g" "$file"
done

# Patch port
sed -i "s/targetPort: 8080/targetPort: ${PORT}/" "${CHART_DIR}/values.yaml"

# Enable cloudSql sidecar if requested
if [[ "$CLOUD_SQL" == "true" ]]; then
  sed -i "s/  enabled: false/  enabled: true/" "${CHART_DIR}/values.yaml"
fi

# Enable VirtualService if requested
if [[ "$VIRTUAL_SERVICE" == "true" ]]; then
  sed -i "/virtualService:/,/pathPrefix:/ s/  enabled: false/  enabled: true/" "${CHART_DIR}/values.yaml"
  # Create a VirtualService template (copy from account-service pattern)
  cat > "${CHART_DIR}/templates/virtualservice.yaml" <<'VSEOF'
{{- if .Values.virtualService.enabled }}
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: {{ include "SERVICE_NAME.name" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "SERVICE_NAME.labels" . | nindent 4 }}
spec:
  hosts:
    {{- toYaml .Values.virtualService.hosts | nindent 4 }}
  gateways:
    - {{ .Values.virtualService.gateway }}
  http:
    - match:
        - uri:
            prefix: {{ .Values.virtualService.pathPrefix }}
      route:
        - destination:
            host: {{ include "SERVICE_NAME.name" . }}.{{ .Release.Namespace }}.svc.cluster.local
            port:
              number: {{ .Values.service.port }}
{{- end }}
VSEOF
  sed -i "s/SERVICE_NAME/${SERVICE_NAME}/g" "${CHART_DIR}/templates/virtualservice.yaml"
fi

echo "   [ok] chart  → ${SERVICE_NAME}/chart/"

# ─── 2. Generate CI workflow ─────────────────────────────────────────────────
TEST_STEPS=""
if [[ "$LANG" == "node" ]]; then
  TEST_STEPS="  test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${SERVICE_NAME}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: \"20\"
          cache: npm
          cache-dependency-path: ${SERVICE_NAME}/package.json
      - run: npm install
      - run: npm test
      - run: npm audit --omit=dev --audit-level=high

"
  BUILD_NEEDS="needs: [test, sast]"
elif [[ "$LANG" == "go" ]]; then
  TEST_STEPS="  test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${SERVICE_NAME}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: ${SERVICE_NAME}/go.mod
      - run: go test ./...
      - run: go vet ./...

"
  BUILD_NEEDS="needs: [test, sast]"
elif [[ "$LANG" == "python" ]]; then
  TEST_STEPS="  test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${SERVICE_NAME}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: \"3.12\"
      - run: pip install -r requirements.txt
      - run: pytest

"
  BUILD_NEEDS="needs: [test, sast]"
else
  BUILD_NEEDS="needs: [sast]"
fi

cat > "${WORKFLOW_FILE}" <<WEOF
name: ci-${SERVICE_NAME}

on:
  push:
    branches: [main]
    paths:
      - "${SERVICE_NAME}/**"
      - ".github/workflows/ci-${SERVICE_NAME}.yml"
  pull_request:
    paths:
      - "${SERVICE_NAME}/**"
      - ".github/workflows/ci-${SERVICE_NAME}.yml"
  workflow_dispatch:

permissions:
  contents: write
  id-token: write
  pull-requests: read

env:
  SERVICE: ${SERVICE_NAME}
  IMAGE_REPO: \${{ vars.AR_HOST }}/\${{ vars.AR_PROJECT }}/docker/${SERVICE_NAME}
  GITOPS_APP_FILE: gitops-manifests-dev/apps/services/${SERVICE_NAME}.yaml

jobs:
${TEST_STEPS}  sast:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript-typescript
      - uses: github/codeql-action/analyze@v3

  build-and-push:
    ${BUILD_NEEDS}
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    outputs:
      image_tag: \${{ steps.meta.outputs.tag }}
    steps:
      - uses: actions/checkout@v4
      - id: meta
        run: echo "tag=\$(git rev-parse --short=12 HEAD)" >> "\$GITHUB_OUTPUT"
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: \${{ vars.WIF_PROVIDER }}
          service_account: \${{ vars.CI_SERVICE_ACCOUNT }}
      - uses: google-github-actions/setup-gcloud@v2
      - run: gcloud auth configure-docker "\${{ vars.AR_HOST }}" --quiet
      - uses: docker/setup-buildx-action@v3
      - uses: docker/build-push-action@v5
        with:
          context: ${SERVICE_NAME}
          load: true
          tags: \${{ env.IMAGE_REPO }}:\${{ steps.meta.outputs.tag }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
      - uses: aquasecurity/trivy-action@0.24.0
        with:
          image-ref: \${{ env.IMAGE_REPO }}:\${{ steps.meta.outputs.tag }}
          format: table
          exit-code: 1
          ignore-unfixed: true
          vuln-type: os,library
          severity: HIGH,CRITICAL
      - run: docker push "\${{ env.IMAGE_REPO }}:\${{ steps.meta.outputs.tag }}"
      - name: Get image digest
        id: digest
        run: |
          DIGEST=\$(gcloud artifacts docker images describe \\
            "\${{ env.IMAGE_REPO }}:\${{ steps.meta.outputs.tag }}" \\
            --format='get(image_summary.digest)')
          echo "value=\${DIGEST}" >> "\$GITHUB_OUTPUT"
      - name: Attest image (Binary Authorization)
        env:
          ARTIFACT_URL: \${{ env.IMAGE_REPO }}@\${{ steps.digest.outputs.value }}
        run: |
          gcloud container binauthz attestations sign-and-create \\
            --artifact-url="\${ARTIFACT_URL}" \\
            --attestor="\${{ vars.BINAUTHZ_ATTESTOR }}" \\
            --attestor-project="\${{ vars.AR_PROJECT }}" \\
            --keyversion="\${{ vars.BINAUTHZ_KEY_VERSION_ID }}"

  deploy-to-dev:
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          token: \${{ secrets.GITHUB_TOKEN }}
          fetch-depth: 0
      - name: Bump image tag in Argo Application
        env:
          NEW_TAG: \${{ needs.build-and-push.outputs.image_tag }}
        run: |
          python3 - <<'PY'
          import os, re, pathlib
          path = pathlib.Path(os.environ["GITOPS_APP_FILE"])
          text = path.read_text()
          text = re.sub(
              r'(-\s*name:\s*image\\.tag\s*\n\s*value:\s*)"[^"]*"',
              rf'\1"{os.environ["NEW_TAG"]}"', text, count=1)
          path.write_text(text)
          PY
      - name: Commit and push
        env:
          NEW_TAG: \${{ needs.build-and-push.outputs.image_tag }}
        run: |
          if git diff --quiet -- "\$GITOPS_APP_FILE"; then exit 0; fi
          git config user.name  "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add "\$GITOPS_APP_FILE"
          git commit -m "ci(${SERVICE_NAME}): bump image to \${NEW_TAG}"
          git push origin HEAD:main
WEOF

echo "   [ok] workflow → .github/workflows/ci-${SERVICE_NAME}.yml"

# ─── 3. Generate ArgoCD Application ─────────────────────────────────────────
mkdir -p "$(dirname "${ARGOCD_APP_FILE}")"
cat > "${ARGOCD_APP_FILE}" <<AEOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${SERVICE_NAME}
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  annotations:
    argocd.argoproj.io/sync-wave: "${WAVE}"
spec:
  project: default
  source:
    repoURL: https://github.com/arun-territory/demo-live-project.git
    targetRevision: main
    path: ${SERVICE_NAME}/chart
    helm:
      releaseName: ${SERVICE_NAME}
      parameters:
        - name: image.repository
          value: REPLACE-WITH-AR-URL/${SERVICE_NAME}
        - name: image.tag
          value: "0.1.0"
        - name: gsaEmail
          value: REPLACE-WITH-GSA-EMAIL
  destination:
    server: https://kubernetes.default.svc
    namespace: ${SERVICE_NAME}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=false
      - ServerSideApply=true
      - ApplyOutOfSyncOnly=true
    retry:
      limit: 5
      backoff:
        duration: 10s
        factor: 2
        maxDuration: 5m
AEOF

echo "   [ok] argocd  → gitops-manifests-dev/apps/services/${SERVICE_NAME}.yaml"

# ─── 4. Print Terraform snippet ──────────────────────────────────────────────
CLOUD_SQL_ROLE=""
if [[ "$CLOUD_SQL" == "true" ]]; then
  CLOUD_SQL_ROLE='
    "roles/cloudsql.client",'
fi

cat <<TFEOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Next: add this block to infra/envs/dev/main.tf (or a new file)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

module "svc_${SERVICE_NAME//-/_}" {
  source = "../../modules/service-baseline"

  project_id         = var.project_id
  env                = var.env
  service_name       = "${SERVICE_NAME}"
  asm_revision_label = module.asm.control_plane_revision_label

  project_roles = [${CLOUD_SQL_ROLE}
    # add more roles as needed
  ]

  depends_on = [module.asm]
}

# Then reference module.svc_${SERVICE_NAME//-/_}.gsa_email in your
# ArgoCD Application REPLACE-WITH-GSA-EMAIL placeholder above.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
After Terraform apply, set these GitHub Actions repo variables:
  BINAUTHZ_ATTESTOR       = <from module.binary_authorization.attestor_name>
  BINAUTHZ_KEY_VERSION_ID = <from module.binary_authorization.attestor_kms_key_version_id>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Scaffold complete for ${SERVICE_NAME}. Files created:
  ${SERVICE_NAME}/chart/
  .github/workflows/ci-${SERVICE_NAME}.yml
  gitops-manifests-dev/apps/services/${SERVICE_NAME}.yaml
TFEOF
