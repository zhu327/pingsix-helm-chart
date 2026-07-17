#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

extract_etcd_service_name() {
  local out="$1"
  awk '
    $0 == "kind: Service" { in_svc = 1; name = ""; component = 0; next }
    in_svc && /^---$/ {
      if (component && name != "") { print name; exit 0 }
      in_svc = 0; next
    }
    in_svc && $1 == "name:" { name = $2 }
    in_svc && /app\.kubernetes\.io\/component:[[:space:]]*etcd-adapter/ { component = 1 }
    END {
      if (component && name != "") print name
    }
  ' "$out" | head -n1 | tr -d '\r'
}

assert_case() {
  local label="$1"
  shift
  local out
  out="$(mktemp)"
  # shellcheck disable=SC2068
  helm template "$@" \
    --set ingress-controller.enabled=true \
    --set etcd.enabled=false >"$out"

  local host
  host="$(extract_etcd_service_name "$out")"
  host="${host//$'\n'/}"
  if [[ -z "$host" ]]; then
    echo "FAIL [$label]: etcd-adapter Service not rendered" >&2
    rm -f "$out"
    exit 1
  fi
  if (( ${#host} > 63 )); then
    echo "FAIL [$label]: Service name exceeds 63 chars (${#host}): ${host}" >&2
    rm -f "$out"
    exit 1
  fi
  if ! grep -qF "http://${host}:12379" "$out"; then
    echo "FAIL [$label]: config does not reference Service ${host}" >&2
    rm -f "$out"
    exit 1
  fi
  if ! grep -qF "until nc -z ${host} 12379" "$out"; then
    echo "FAIL [$label]: initContainer does not wait for Service ${host}" >&2
    rm -f "$out"
    exit 1
  fi
  echo "OK [$label]: Service=${host} (len=${#host})"
  rm -f "$out"
}

assert_case "default" \
  review "$ROOT/charts/apisix"

assert_case "long-release" \
  release-name-abcdefghijklmnopqrstuvwxyz-abcdefghijklm "$ROOT/charts/apisix"

assert_case "fullnameOverride" \
  custom "$ROOT/charts/apisix" \
  --set ingress-controller.fullnameOverride=my-controller
