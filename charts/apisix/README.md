# Pingsix Helm Chart

Pingsix is a high-performance API gateway built on Cloudflare's Pingora framework, written in Rust. This Helm chart helps you deploy Pingsix on Kubernetes with support for dynamic configuration via etcd or static configuration.

## Features

- **High Performance**: Built on Pingora, a Rust-based framework designed for performance and reliability
- **Dynamic Configuration**: Support for etcd-based dynamic configuration management
- **Static Configuration**: Deploy with static routes, upstreams, and services when etcd is not needed
- **Multiple Listeners**: Configure HTTP and HTTPS listeners with HTTP/2 support
- **Admin API**: Built-in admin API for runtime configuration management
- **Health Checks**: Dedicated status endpoint for Kubernetes readiness probes
- **Prometheus Metrics**: Optional Prometheus metrics export
- **Ingress Controller Integration**: Works seamlessly with the Pingsix ingress controller
- **APISIX Compatible**: Maintains APISIX-like configuration patterns for easy migration

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+

## Installation

### Add the Helm repository

```bash
helm repo add pingsix https://zhu327.github.io/pingsix-helm-chart
helm repo update
```

### Install with default configuration (standalone mode)

```bash
helm install pingsix pingsix/pingsix
```

### Install with built-in etcd

```bash
helm install pingsix pingsix/pingsix \
  --set etcd.enabled=true
```

### Install with external etcd

```bash
helm install pingsix pingsix/pingsix \
  --set etcd.enabled=false \
  --set externalEtcd.host[0]=http://etcd.example.com:2379
```

### Install with ingress controller

```bash
helm install pingsix pingsix/pingsix \
  --set ingress-controller.enabled=true
```

## Configuration

The following table lists the main configurable parameters of the Pingsix chart and their default values.

**Security Note**: Passwords (etcd and admin API key) are stored in plain text in the ConfigMap. For production environments, consider using Kubernetes secrets management solutions like External Secrets Operator or Sealed Secrets.

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imagePullSecrets` | Global Docker registry secret names | `[]` |
| `image.repository` | Pingsix image repository | `zhu327/pingsix` |
| `image.tag` | Pingsix image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `replicaCount` | Number of Pingsix replicas | `1` |

### Pingora Framework Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `pingora.version` | Pingora config version | `1` |
| `pingora.threads` | Number of worker threads | `2` |
| `pingora.pidFile` | PID file path | `/run/pingora.pid` |
| `pingora.upgradeSock` | Upgrade socket path | `/tmp/pingora_upgrade.sock` |
| `pingora.user` | User to run as | `nobody` |
| `pingora.group` | Group to run as | `webusers` |

### Pingsix Gateway Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `pingsix.listeners` | HTTP/HTTPS listeners configuration | See values.yaml |
| `pingsix.listeners[].address` | Listener bind address (e.g., "0.0.0.0:8080") | - |
| `pingsix.listeners[].tls.secretName` | Kubernetes Secret name for TLS certificates | `nil` |
| `pingsix.listeners[].tls.certFilename` | Certificate filename in secret | `tls.crt` |
| `pingsix.listeners[].tls.keyFilename` | Private key filename in secret | `tls.key` |
| `pingsix.listeners[].tls.certPath` | Direct path to certificate file | `nil` |
| `pingsix.listeners[].tls.keyPath` | Direct path to private key file | `nil` |
| `pingsix.listeners[].offerH2` | Enable HTTP/2 over TLS | `false` |
| `pingsix.listeners[].offerH2c` | Enable HTTP/2 cleartext | `false` |
| `pingsix.admin.enabled` | Enable admin API | `true` |
| `pingsix.admin.address` | Admin API listen address | `0.0.0.0:9181` |
| `pingsix.admin.apiKey` | Admin API authentication key | `edd1c9f034335f136f87ad84b625c8f1` |
| `pingsix.status.enabled` | Enable status/health endpoint | `true` |
| `pingsix.status.address` | Status endpoint listen address | `127.0.0.1:7085` |
| `pingsix.prometheus.enabled` | Enable Prometheus metrics | `false` |
| `pingsix.prometheus.address` | Prometheus listen address | `0.0.0.0:9091` |
| `pingsix.sentry.enabled` | Enable Sentry integration | `false` |
| `pingsix.sentry.dsn` | Sentry DSN | `""` |

### Static Resources Configuration

These are used when etcd is NOT configured:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `routes` | Static routes configuration | `[]` |
| `upstreams` | Static upstreams configuration | `[]` |
| `services` | Static services configuration | `[]` |
| `globalRules` | Static global rules configuration | `[]` |
| `ssls` | Static SSL certificates configuration | `[]` |

### Etcd Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `etcd.enabled` | Enable built-in etcd | `true` |
| `etcd.prefix` | Etcd key prefix | `/apisix` |
| `etcd.timeout` | Etcd operation timeout (seconds) | `30` |
| `etcd.auth.rbac.create` | Enable etcd RBAC authentication | `false` |
| `etcd.auth.rbac.rootPassword` | Etcd root password | `""` |
| `externalEtcd.host` | External etcd addresses | `[]` |
| `externalEtcd.user` | External etcd username | `root` |
| `externalEtcd.password` | External etcd password (stored in plain text in ConfigMap) | `""` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `NodePort` |
| `service.externalTrafficPolicy` | External traffic policy | `Cluster` |
| `ingress.enabled` | Enable ingress for gateway | `false` |
| `metrics.serviceMonitor.enabled` | Enable Prometheus ServiceMonitor | `false` |

## Etcd Configuration Priority

When multiple etcd options are configured, Pingsix uses the following priority:

1. **Ingress Controller** (`ingress-controller.enabled=true`): Uses the ingress controller's built-in etcd adapter
2. **Built-in Etcd** (`etcd.enabled=true`): Uses the etcd deployed as a subchart
3. **External Etcd** (`externalEtcd.host`): Connects to an external etcd cluster
4. **Static Configuration**: If none of the above, uses static routes/upstreams from values.yaml

## Usage Examples

### Example 1: Standalone Mode with Static Routes

```yaml
# values.yaml
etcd:
  enabled: false

pingsix:
  listeners:
    - address: "0.0.0.0:8080"

routes:
  - id: "1"
    uri: /api
    host: api.example.com
    upstream:
      nodes:
        "backend.svc.cluster.local:8080": 1
      type: roundrobin
      scheme: http

upstreams:
  - id: "1"
    nodes:
      "backend1.example.com:8080": 1
      "backend2.example.com:8080": 1
    type: roundrobin
    checks:
      active:
        type: http
        http_path: /health
        healthy:
          interval: 5
          http_statuses: [200]
          successes: 2
```

### Example 2: HTTPS Listener with HTTP/2 (Using Kubernetes Secret)

First, create a TLS secret:

```bash
kubectl create secret tls pingsix-tls \
  --cert=server.crt \
  --key=server.key \
  --namespace=default
```

Then configure:

```yaml
pingsix:
  listeners:
    - address: "0.0.0.0:8080"
      offerH2c: false
    - address: "0.0.0.0:8443"
      tls:
        secretName: pingsix-tls
        # Optional: specify custom filenames in the secret
        # certFilename: tls.crt  # default
        # keyFilename: tls.key   # default
      offerH2: true
```

**Alternative**: Use direct file paths (not recommended for production):

```yaml
pingsix:
  listeners:
    - address: "0.0.0.0:8443"
      tls:
        certPath: /etc/ssl/certs/server.crt
        keyPath: /etc/ssl/private/server.key
      offerH2: true
```

### Example 3: With Prometheus Metrics

```yaml
pingsix:
  prometheus:
    enabled: true
    address: "0.0.0.0:9091"

metrics:
  serviceMonitor:
    enabled: true
    interval: 15s
```

### Example 4: With External Etcd Authentication

**Note**: The password will be stored in plain text in the ConfigMap.

```yaml
etcd:
  enabled: false

externalEtcd:
  host:
    - http://etcd.example.com:2379
  user: root
  password: "your-etcd-password"
```

For better security in production, consider using network policies to restrict access to the ConfigMap.

## Migration from APISIX

If you're migrating from APISIX, Pingsix maintains similar configuration patterns:

### Key Differences

1. **No Nginx Configuration**: Pingsix uses Pingora instead of Nginx/OpenResty
2. **No Lua Plugins**: Pingsix plugins are written in Rust
3. **Simplified Listeners**: Instead of separate `service.http` and `apisix.ssl`, use `pingsix.listeners`
4. **No Control API**: Pingsix doesn't have a separate control plane API
5. **Single Admin Role**: No separate viewer role, only admin

### Configuration Mapping

| APISIX | Pingsix |
|--------|---------|
| `apisix.admin.enabled` | `pingsix.admin.enabled` |
| `apisix.admin.port` | `pingsix.admin.address` |
| `apisix.admin.credentials.admin` | `pingsix.admin.apiKey` |
| `service.http.containerPort` | `pingsix.listeners[].address` |
| `apisix.ssl.enabled` | `pingsix.listeners[].tls` |
| `apisix.prometheus` | `pingsix.prometheus` |

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=pingsix
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=pingsix -f
```

### Test Health Endpoint

```bash
kubectl port-forward svc/pingsix-status 7085:7085
curl http://localhost:7085/status/ready
```

### Test Admin API

```bash
kubectl port-forward svc/pingsix-admin 9181:9181
curl -H "X-API-KEY: your-api-key" http://localhost:9181/apisix/admin/routes
```

## Uninstallation

```bash
helm uninstall pingsix
```

To also remove the etcd PVCs:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=pingsix
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Licensed under the Apache License, Version 2.0.

## Links

- [Pingsix GitHub](https://github.com/zhu327/pingsix)
- [Pingora Documentation](https://github.com/cloudflare/pingora)
- [APISIX Documentation](https://apisix.apache.org/docs/)
