# PingSIX Helm Charts

Helm charts for deploying [PingSIX](https://github.com/zhu327/pingsix) and a [PingSIX-adapted APISIX Ingress Controller](https://github.com/zhu327/pingsix-ingress-controller) on Kubernetes.

This repository is based on [apache/apisix-helm-chart](https://github.com/apache/apisix-helm-chart). Chart directory names (`apisix`, `apisix-ingress-controller`) are kept for compatibility; the deployed gateway image is `zhu327/pingsix`, and the ingress controller image is `zhu327/pingsix-ingress-controller`.

## Related projects

| Project | Repository |
|---------|------------|
| PingSIX gateway | [zhu327/pingsix](https://github.com/zhu327/pingsix) |
| Ingress Controller (PingSIX fork) | [zhu327/pingsix-ingress-controller](https://github.com/zhu327/pingsix-ingress-controller) |
| This Helm chart | [zhu327/pingsix-helm-chart](https://github.com/zhu327/pingsix-helm-chart) |

## Charts

| Chart | Path | Description |
|-------|------|-------------|
| Gateway | [`charts/apisix`](./charts/apisix) | Deploy PingSIX (optional built-in etcd, optional ingress controller subchart) |
| Ingress Controller | [`charts/apisix-ingress-controller`](./charts/apisix-ingress-controller) | Deploy the PingSIX ingress controller standalone |

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+

## Quick start

Recommended: PingSIX + ingress controller, without built-in etcd. The ingress controller exposes an etcd-compatible adapter that PingSIX uses for dynamic configuration.

```bash
git clone https://github.com/zhu327/pingsix-helm-chart.git
cd pingsix-helm-chart/charts/apisix

helm dependency update

helm install apisix \
  --namespace ingress-apisix \
  --create-namespace \
  --set etcd.enabled=false \
  --set ingress-controller.enabled=true \
  --set ingress-controller.gatewayProxy.createDefault=true \
  .
```

### Verify

```bash
kubectl -n ingress-apisix get pods
kubectl -n ingress-apisix get gatewayproxy
```

### Uninstall

```bash
helm uninstall apisix --namespace ingress-apisix
```

## Other install modes

### Standalone PingSIX (static config, no etcd)

```bash
helm install apisix . \
  --namespace ingress-apisix \
  --create-namespace \
  --set etcd.enabled=false
```

Configure static `routes` / `upstreams` in `values.yaml`.

### Built-in etcd (dev / test only)

```bash
helm install apisix . \
  --namespace ingress-apisix \
  --create-namespace \
  --set etcd.enabled=true
```

### External etcd

```bash
helm install apisix . \
  --namespace ingress-apisix \
  --create-namespace \
  --set etcd.enabled=false \
  --set externalEtcd.host[0]=http://etcd.example.com:2379
```

### Ingress controller only

```bash
cd ../apisix-ingress-controller
helm install apisix-ingress-controller . \
  --namespace ingress-apisix \
  --create-namespace
```

## Configuration priority

When multiple configuration backends are available, PingSIX uses this order:

1. **Ingress Controller** (`ingress-controller.enabled=true`) — etcd adapter
2. **Built-in etcd** (`etcd.enabled=true`)
3. **External etcd** (`externalEtcd.host`)
4. **Static resources** in `values.yaml` (`routes`, `upstreams`, …)

## Images

| Component | Default image |
|-----------|---------------|
| Gateway | `zhu327/pingsix:latest` |
| Ingress Controller | `zhu327/pingsix-ingress-controller:2.0.0` |
| Built-in etcd | `bitnamilegacy/etcd:latest` |

## Documentation

- [PingSIX chart values & examples](./charts/apisix/README.md)
- [Ingress Controller chart values](./charts/apisix-ingress-controller/README.md)
- [PingSIX User Guide](https://github.com/zhu327/pingsix/blob/main/USER_GUIDE.md)

## License

Apache License 2.0. See [LICENSE](./LICENSE).
