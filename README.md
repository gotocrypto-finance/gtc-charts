# GTC Helm Charts

Helm charts maintained by GoToCrypto Finance.

## Add the repository

```sh
helm repo add gtc https://gotocrypto-finance.github.io/gtc-charts
helm repo update
```

## Install SimpleX SMP

```sh
helm upgrade --install simplex-smp gtc/simplex-smp \
  --namespace simplex \
  --create-namespace \
  --set server.address=smp.example.com
```

See [`charts/simplex-smp/README.md`](charts/simplex-smp/README.md) for networking, storage and configuration details.

## Publishing

Merging a chart change to `main` runs the chart-releaser workflow. Increase the chart's `version` in `Chart.yaml` for every release. GitHub Releases contains the packaged charts and the `gh-pages` branch contains the Helm repository index.
