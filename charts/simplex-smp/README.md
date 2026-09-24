# SimpleX SMP

Deploys one SimpleX Messaging Protocol relay using the official `simplexchat/smp-server` image.

## Networking

Expose inbound TCP `5223` and point `server.address` to the load balancer with an A/AAAA record. SMP is raw TLS/TCP, so an ordinary HTTP Ingress is not used. Do not expose the administrative control port `5224`.

## Storage

One `10Gi` PVC is enabled by default. It contains separate `config/` and `state/` directories mounted with `subPath`. Configuration contains the permanent server identity and certificates; state contains queue/connection records and undelivered messages. Losing the volume changes the server identity and invalidates all existing queues.

For a disposable test relay, set `persistence.enabled=false`.

Upgrading from chart `0.1.x` requires a fresh StatefulSet or a manual data migration because Kubernetes does not allow changing existing `volumeClaimTemplates` from two claims to one.

## Installation

```sh
helm upgrade --install simplex-smp gtc/simplex-smp \
  --namespace simplex \
  --create-namespace \
  --set server.address=smp.example.com
```

For production, provide an existing Secret containing `PASS`:

```yaml
server:
  address: smp.example.com
  existingSecret: simplex-smp-password
  existingSecretKey: PASS
```
