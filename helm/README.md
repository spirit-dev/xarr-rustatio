# Rustatio Helm Chart

A Helm chart for deploying [Rustatio](https://github.com/takitsu21/rustatio) - a modern BitTorrent ratio faker on Kubernetes.

## Overview

Rustatio is a modern, cross-platform BitTorrent ratio management tool that emulates popular torrent clients (uTorrent, qBittorrent, Transmission, Deluge). This Helm chart deploys the self-hosted server version with a web UI.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.12+
- PV provisioner support in the underlying infrastructure (for persistence)

## Installation

### Add the repository (if applicable)

```bash
helm repo add rustatio https://your-repo-url
helm repo update
```

### Install the chart

```bash
# Basic installation
helm install rustatio ./rustatio --namespace rustatio --create-namespace

# With authentication enabled
helm install rustatio ./rustatio --namespace rustatio --create-namespace \
  --set auth.enabled=true \
  --set auth.token="your-secure-token"

# With VPN routing (recommended for privacy)
helm install rustatio ./rustatio --namespace rustatio --create-namespace \
  --values values-vpn.yaml
```

## Configuration

### Common Parameters

| Parameter          | Description                      | Default                      |
| ------------------ | -------------------------------- | ---------------------------- |
| `replicaCount`     | Number of replicas (should be 1) | `1`                          |
| `image.repository` | Image repository                 | `ghcr.io/takitsu21/rustatio` |
| `image.tag`        | Image tag                        | `0.12.1`                     |
| `image.pullPolicy` | Image pull policy                | `IfNotPresent`               |

### Authentication

| Parameter                | Description            | Default               |
| ------------------------ | ---------------------- | --------------------- |
| `auth.enabled`           | Enable authentication  | `false`               |
| `auth.token`             | Authentication token   | `""` (auto-generated) |
| `auth.existingSecret`    | Use existing secret    | `""`                  |
| `auth.existingSecretKey` | Key in existing secret | `AUTH_TOKEN`          |

### Persistence

| Parameter                       | Description             | Default |
| ------------------------------- | ----------------------- | ------- |
| `persistence.data.enabled`      | Enable data persistence | `true`  |
| `persistence.data.size`         | Data PVC size           | `1Gi`   |
| `persistence.data.storageClass` | Storage class           | `""`    |
| `persistence.torrents.enabled`  | Enable torrents folder  | `false` |
| `persistence.torrents.size`     | Torrents PVC size       | `5Gi`   |

### VPN Configuration

| Parameter                | Description               | Default          |
| ------------------------ | ------------------------- | ---------------- |
| `vpn.enabled`            | Enable VPN routing        | `false`          |
| `vpn.gluetun.enabled`    | Enable gluetun sidecar    | `true`           |
| `vpn.gluetun.repository` | Gluetun image             | `qmcgaw/gluetun` |
| `vpn.gluetun.env`        | VPN environment variables | `[]`             |

### Watch Folder

| Parameter         | Description                    | Default |
| ----------------- | ------------------------------ | ------- |
| `watch.enabled`   | Enable watch folder            | `false` |
| `watch.autoStart` | Auto-start faking new torrents | `false` |

### Ingress

| Parameter           | Description                 | Default                                                          |
| ------------------- | --------------------------- | ---------------------------------------------------------------- |
| `ingress.enabled`   | Enable ingress              | `false`                                                          |
| `ingress.className` | Ingress class name          | `""`                                                             |
| `ingress.hosts`     | Ingress hosts configuration | `[{host: rustatio.local, paths: [{path: /, pathType: Prefix}]}]` |
| `ingress.tls`       | TLS configuration           | `[]`                                                             |

## Usage Examples

### Basic Installation

```bash
helm install rustatio ./rustatio --namespace rustatio --create-namespace
kubectl port-forward svc/rustatio 8080:8080 -n rustatio
# Access http://localhost:8080
```

### With Authentication

```bash
helm install rustatio ./rustatio \
  --namespace rustatio \
  --create-namespace \
  --set auth.enabled=true \
  --set auth.token=$(openssl rand -hex 32)
```

### With VPN (ProtonVPN Example)

Create a values file `my-vpn-values.yaml`:

```yaml
vpn:
  enabled: true
  gluetun:
    env:
      - name: VPN_SERVICE_PROVIDER
        value: "protonvpn"
      - name: VPN_TYPE
        value: "wireguard"
      - name: WIREGUARD_PRIVATE_KEY
        valueFrom:
          secretKeyRef:
            name: vpn-credentials
            key: private-key
      - name: SERVER_COUNTRIES
        value: "Switzerland"
```

```bash
kubectl create secret generic vpn-credentials \
  --from-literal=private-key="your-wireguard-private-key"

helm install rustatio ./rustatio \
  --namespace rustatio \
  --create-namespace \
  --values my-vpn-values.yaml
```

### With Ingress

```bash
helm install rustatio ./rustatio \
  --namespace rustatio \
  --create-namespace \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set 'ingress.hosts[0].host=rustatio.example.com' \
  --set 'ingress.hosts[0].paths[0].path=/' \
  --set 'ingress.hosts[0].paths[0].pathType=Prefix'
```

### With Persistent Torrents Watch Folder

```bash
helm install rustatio ./rustatio \
  --namespace rustatio \
  --create-namespace \
  --set persistence.torrents.enabled=true \
  --set persistence.torrents.size=10Gi \
  --set watch.enabled=true
```

## Post-Installation

### Get Authentication Token

If authentication is enabled and you didn't provide a token:

```bash
kubectl get secret rustatio -n rustatio -o jsonpath="{.data.AUTH_TOKEN}" | base64 --decode
```

### Access the Web UI

```bash
# Port-forward
kubectl port-forward svc/rustatio 8080:8080 -n rustatio

# Then open http://localhost:8080
```

### Add Torrent Files

If using the watch folder feature, copy torrent files to the mounted PVC:

```bash
kubectl cp ./my-torrent.torrent rustatio-0:/torrents/ -n rustatio
```

## Uninstall

```bash
helm uninstall rustatio -n rustatio
```

## Storage

The chart supports two types of persistence:

1. **Data Persistence** (`persistence.data`): Stores Rustatio configuration and state
2. **Torrents Persistence** (`persistence.torrents`): Stores torrent files for watch folder feature

Both PVCs have `retain: true` by default, meaning the PVCs will be retained when the release is deleted.

## Security Considerations

1. **Authentication**: When exposing Rustatio to the internet, always enable authentication
2. **VPN**: Consider routing tracker requests through a VPN for privacy
3. **Network Policies**: Consider using network policies to restrict egress traffic

## Troubleshooting

### Pod fails to start

Check logs:

```bash
kubectl logs -n rustatio deployment/rustatio
```

### Permission issues with torrents folder

Ensure the torrents directory exists and has correct permissions:

```bash
kubectl exec -it -n rustatio deployment/rustatio -- ls -la /torrents
```

### VPN connection issues

Check gluetun logs:

```bash
kubectl logs -n rustatio deployment/rustatio -c gluetun
```

## License

This Helm chart follows the same license as the Rustatio project (MIT).
