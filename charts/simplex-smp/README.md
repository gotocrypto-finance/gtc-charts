# SimpleX SMP

Deploys one SimpleX Messaging Protocol relay using the official `simplexchat/smp-server` image.

## Networking

Expose inbound TCP `5223` and point `server.address` to the load balancer with an A/AAAA record. SMP is raw TLS/TCP, so an ordinary HTTP Ingress is not used. Do not expose the administrative control port `5224`.

## Storage

Both PVCs are enabled by default. The `config` claim contains the permanent server identity and certificates. The `state` claim contains queue/connection records and undelivered messages. Losing the state claim invalidates existing queues; it does not only discard pending messages.

For a disposable test relay, set both `persistence.config.enabled` and `persistence.state.enabled` to `false`.

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

