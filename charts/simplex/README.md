# SimpleX chart

This chart runs three containers in one pod:

- SimpleX SMP on `5223/TCP`.
- SimpleX XFTP on external `5225/TCP` (container port `443`).
- coturn on `3478/TCP+UDP` and `49160-49210/UDP` by default.

All services can use the same DNS name because they use different ports. The
single pod also allows SMP and XFTP to share one `ReadWriteOnce` PVC safely. An
init container creates these subdirectories before the servers start:

```text
smp/config
smp/state
xftp/config
xftp/state
xftp/files
turn
```

## Install

Create a DNS-only A record for `s.gtc.finance` pointing at the node's public IP.
Do not enable the Cloudflare HTTP proxy for this record.

Create credentials without putting them in Helm history:

```bash
kubectl create namespace simplex
kubectl create secret generic simplex-credentials \
  --namespace simplex \
  --from-literal=smp-password='replace-me' \
  --from-literal=xftp-password='replace-me' \
  --from-literal=turn-username='simplex' \
  --from-literal=turn-password='replace-me'
```

Install the chart:

```bash
helm upgrade --install simplex-smp ./charts/simplex \
  --namespace simplex \
  --set credentials.existingSecret=simplex-credentials \
  --set publicIP=65.108.49.23 \
  --set 'nodeSelector.kubernetes\.io/hostname=worker1'
```

If the current SMP installation already has a PVC, reuse it instead of allowing
this chart to create a new one:

```bash
helm upgrade --install simplex-smp ./charts/simplex \
  --namespace simplex \
  --set persistence.existingClaim='<current-pvc-name>' \
  --set credentials.existingSecret=simplex-credentials \
  --set publicIP=65.108.49.23 \
  --set 'nodeSelector.kubernetes\.io/hostname=worker1'
```

Check the current PVC and directory layout before upgrading. If its SMP data is
not already under `smp/config` and `smp/state`, override the corresponding
`persistence.subPaths` values. Preserving the existing SMP config directory
preserves the server certificate fingerprint/identity.

Pin the pod to the node that owns/routes the public IP. This is especially
important for coturn: its relayed UDP traffic must leave through the same public
address that it advertises to clients.

The default service names are:

```text
simplex-smp-simplex-smp
simplex-smp-xftp
simplex-smp-turn
```

Open these ports in the Hetzner firewall and the node firewall:

```text
5223/tcp
5225/tcp
3478/tcp
3478/udp
49160-49210/udp
```

The TURN relay range is intentionally bounded. Increase it for more concurrent
calls, and open the matching firewall range.

## Client configuration

Read the SMP and XFTP addresses from the containers:

```bash
kubectl logs -n simplex deployment/simplex-smp-simplex-smp -c smp
kubectl logs -n simplex deployment/simplex-smp-simplex-smp -c xftp
```

The XFTP container prints the hostname without the externally translated port.
Configure the client with `:5225`, for example:

```text
xftp://<fingerprint>:<password>@s.gtc.finance:5225
```

Configure the SimpleX WebRTC ICE list with only this server:

```text
stun:s.gtc.finance:3478
turn:<username>:<password>@s.gtc.finance:3478?transport=udp
turn:<username>:<password>@s.gtc.finance:3478?transport=tcp
```

Enable **Always use relay** if calls must always traverse this coturn instance.
Configure every client device and disable the preset XFTP/ICE servers if no
third-party relay should be used.

## Dynamic public IP

Use [`scripts/update-simplex-public-ip.sh`](../../scripts/update-simplex-public-ip.sh)
after updating DNS. It patches all three Services and updates the coturn
advertised address by changing the Deployment environment, which triggers a
pod rollout. Pass the current `publicIP` again on later Helm upgrades so Helm
does not restore an older address from its values.
