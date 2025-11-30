# Prometheus PostgreSQL exporter

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/prometheus-exporters)](https://artifacthub.io/packages/search?repo=prometheus-exporters)

> [!NOTE]
> This is not the official *community* helm chart of the Prometheus metric exporter for PostgreSQL databases. If you are
> looking for the official helm chart, checkout the GitHub project
> [helm-charts](https://github.com/prometheus-community/helm-charts) of the [Prometheus
> community](https://github.com/prometheus-community).

This helm chart enables the deployment of a Prometheus metrics exporter for PostgreSQL databases and allows the
individual configuration of additional containers/initContainers, mounting of volumes, defining additional environment
variables, apply a user-defined `webConfig.yaml` and much more.

Chapter [configuration and installation](#helm-configuration-and-installation) describes the basics how to configure helm
and use it to deploy the exporter. It also contains further configuration examples.

Furthermore, this helm chart contains unit tests to detect regressions and stabilize the deployment. Additionally, this
helm chart is tested for deployment scenarios with **ArgoCD**, but please keep in mind, that this chart supports the
*[Automatically Roll Deployment](https://helm.sh/docs/howto/charts_tips_and_tricks/#automatically-roll-deployments)*
concept of Helm, which can trigger unexpected rolling releases. Further configuration instructions are described in a
separate [chapter](#argocd).

## Helm: configuration and installation

1. A helm chart repository must be configured, to pull the helm charts from.
2. All available [parameters](#parameters) are documented in detail below. The parameters can be defined via the helm
   `--set` flag or directly as part of a `values.yaml` file. The following example defines the `prometheus-exporter`
   repository and use the `--set` flag for a basic deployment.

> [!IMPORTANT]
> By default is neither a serviceMonitor nor a podMonitor enabled. Use `prometheus.metrics.serviceMonitor.enabled=true`
> or `prometheus.metrics.podMonitor.enabled=true` to enable one monitor deployment. Deploying both monitors at the same
> time is not possible.

```bash
helm repo add prometheus-exporters https://charts.cryptic.systems/prometheus-exporters
helm repo update
CHART_VERSION=0.5.5
helm install --version "${CHART_VERSION}" prometheus-postgres-exporter prometheus-exporters/prometheus-postgres-exporter \
  --set 'config.database.secret.databaseUsername=postgres' \
  --set 'config.database.secret.databasePassword=postgres' \
  --set 'config.database.secret.databaseConnectionUrl="postgres.example.local:5432/postgres?ssl=disable"' \
  --set 'prometheus.metrics.enabled=true' \
  --set 'prometheus.metrics.serviceMonitor.enabled=true'
```

Instead of passing all parameters via the *set* flag, it is also possible to define them as part of the `values.yaml`.
The following command downloads the `values.yaml` for a specific version of this chart. Please keep in mind, that the
version of the chart must be in sync with the `values.yaml`. Newer *minor* versions can have new features. New *major*
versions can break something!

```bash
CHART_VERSION=0.5.5
helm show values --version "${CHART_VERSION}" prometheus-exporters/prometheus-postgres-exporter > values.yaml
```

A complete list of available helm chart versions can be displayed via the following command:

```bash
helm search repo prometheus-postgres-exporter --versions
```

The helm chart also contains some prometheusRules. These are deactivated by default and serve as examples/inspiration
for customizations. These can be configured in more detail via `values.yaml`.

### Examples

The following examples serve as individual configurations and as inspiration for how deployment problems can be solved.

#### Avoid CPU throttling by defining a CPU limit

If the application is deployed with a CPU resource limit, Prometheus may throw a CPU throttling warning for the
application. This has more or less to do with the fact that the application finds the number of CPUs of the host, but
cannot use the available CPU time to perform computing operations.

The application must be informed that despite several CPUs only a part (limit) of the available computing time is
available. As this is a Golang application, this can be implemented using `GOMAXPROCS`. The following example is one way
of defining `GOMAXPROCS` automatically based on the defined CPU limit like `1000m`. Please keep in mind, that the CFS
rate of `100ms` - default on each kubernetes node, is also very important to avoid CPU throttling.

Further information about this topic can be found in one of Kanishk's blog
[posts](https://kanishk.io/posts/cpu-throttling-in-containerized-go-apps/).

> [!NOTE]
> The environment variable `GOMAXPROCS` is set automatically, when a CPU limit is defined. An explicit configuration is
> not anymore required.
>
> Please take care the a CPU limit < `1000m` can also lead to CPU throttling. Please read the linked documentation carefully.

```bash
CHART_VERSION=0.5.5
helm install --version "${CHART_VERSION}" prometheus-postgres-exporter prometheus-exporters/prometheus-postgres-exporter \
  --set 'config.database.secret.databaseUsername=postgres' \
  --set 'config.database.secret.databasePassword=postgres' \
  --set 'config.database.secret.databaseConnectionUrl="postgres.example.local:5432/postgres?ssl=disable"' \
  --set 'prometheus.metrics.enabled=true' \
  --set 'prometheus.metrics.serviceMonitor.enabled=true' \
  --set 'deployment.postgresExporter.env.name=GOMAXPROCS' \
  --set 'deployment.postgresExporter.env.valueFrom.resourceFieldRef.resource=limits.cpu' \
  --set 'deployment.postgresExporter.resources.limits.cpu=1000m'
```

#### TLS authentication and encryption

The example shows how to deploy the metric exporter with TLS encryption. The verification of the custom TLS
certification will be skipped by Prometheus.

> [!WARNING]
> The secret `prometheus-postgresql-exporter-http` containing the TLS certificate is already present. The keys `ca.crt`,
> `tls.key` and `tls.crt` of the secret can be mounted into the container filesystem for TLS authentication / encryption.

```bash
CHART_VERSION=0.5.5
helm install --version "${CHART_VERSION}" prometheus-postgres-exporter prometheus-exporters/prometheus-postgres-exporter \
  --set 'config.database.secret.databaseUsername=postgres' \
  --set 'config.database.secret.databasePassword=postgres' \
  --set 'config.database.secret.databaseConnectionUrl="postgres.example.local:5432/postgres?ssl=disable"' \
  --set 'config.webConfig.secret.webConfig.cert_file=/etc/prometheus-postgres-exporter/tls/tls.crt' \
  --set 'config.webConfig.secret.webConfig.client_ca_file=/etc/prometheus-postgres-exporter/tls/ca.crt' \
  --set 'config.webConfig.secret.webConfig.key_file=/etc/prometheus-postgres-exporter/tls/tls.key'
  --set 'deployment.volumes[0].name=tls' \
  --set 'deployment.volumes[0].secret.secretName=prometheus-postgresql-exporter-http' \
  --set 'deployment.postgresExporter.volumeMounts[0].name=tls' \
  --set 'deployment.postgresExporter.volumeMounts[0].mountPath=/etc/prometheus-postgres-exporter/tls' \
  --set 'deployment.postgresExporter.volumeMounts[0].readOnly=true' \
  --set 'prometheus.metrics.enabled=true' \
  --set 'prometheus.metrics.serviceMonitor.enabled=true' \
  --set 'prometheus.metrics.serviceMonitor.scheme=https' \
  --set 'prometheus.metrics.serviceMonitor.tlsConfig.insecureSkipVerify=true'
```

If the Prometheus pod has a TLS certificate mounted and is also signed by the private key of the CA which issued the TLS
certificate for the metrics exporter - TLS certificate verification can be enabled. The following flags must be
replaced:

```diff
  CHART_VERSION=0.5.5
  helm install --version "${CHART_VERSION}" prometheus-postgres-exporter prometheus-exporters/prometheus-postgres-exporter \
    --set 'config.database.secret.databaseUsername=postgres' \
    --set 'config.database.secret.databasePassword=postgres' \
    --set 'config.database.secret.databaseConnectionUrl="postgres.example.local:5432/postgres?ssl=disable"' \
    --set 'config.webConfig.secret.webConfig.cert_file=/etc/prometheus-postgres-exporter/tls/tls.crt' \
    --set 'config.webConfig.secret.webConfig.client_ca_file=/etc/prometheus-postgres-exporter/tls/ca.crt' \
    --set 'config.webConfig.secret.webConfig.key_file=/etc/prometheus-postgres-exporter/tls/tls.key'
    --set 'deployment.volumes[0].name=tls' \
    --set 'deployment.volumes[0].secret.secretName=prometheus-postgresql-exporter-http' \
    --set 'deployment.postgresExporter.volumeMounts[0].name=tls' \
    --set 'deployment.postgresExporter.volumeMounts[0].mountPath=/etc/prometheus-postgres-exporter/tls' \
    --set 'deployment.postgresExporter.volumeMounts[0].readOnly=true' \
    --set 'prometheus.metrics.enabled=true' \
    --set 'prometheus.metrics.serviceMonitor.enabled=true' \
    --set 'prometheus.metrics.serviceMonitor.scheme=https' \
-   --set 'prometheus.metrics.serviceMonitor.tlsConfig.insecureSkipVerify=true' \
+   --set 'prometheus.metrics.serviceMonitor.tlsConfig.caFile=/etc/prometheus/tls/ca.crt' \
+   --set 'prometheus.metrics.serviceMonitor.tlsConfig.certFile=/etc/prometheus/tls/tls.crt' \
+   --set 'prometheus.metrics.serviceMonitor.tlsConfig.keyFile=/etc/prometheus/tls/tls.key'
```

#### TLS certificate rotation

If the exporter uses TLS certificates that are mounted as a secret in the container file system like the example
[above](#tls-authentication-and-encryption), the exporter will not automatically apply them when the TLS certificates
are rotated. Such a rotation can be for example triggered, when the [cert-manager](https://cert-manager.io/) issues new
TLS certificates before expiring.

Until the exporter does not support rotating TLS certificate a workaround can be applied. For example stakater's
[reloader](https://github.com/stakater/Reloader) controller can be used to trigger a rolling update. The following
annotation must be added to instruct the reloader controller to trigger a rolling update, when the mounted secret has
been changed.

> [!IMPORTANT]
> The Helm chart already adds annotations to trigger a rolling release. Helm describes this approach under
> [Automatically Roll Deployments](https://helm.sh/docs/howto/charts_tips_and_tricks/#automatically-roll-deployments).
> For this reason, **only external** configMaps or secrets need to be monitored by reloader.

```yaml
deployment:
  annotations:
    secret.reloader.stakater.com/reload: "prometheus-postgresql-exporter-http"
```

#### Grafana dashboard

The helm chart includes Grafana dashboards. These can be deployed as a configMap by activating Grafana integration. It
is assumed that the dashboard is consumed by Grafana or a sidecar container itself and that the dashboard is stored in
the Grafana container file system so that it is subsequently available to the user. The
[kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) deployment
makes this possible.

```bash
CHART_VERSION=0.5.5
helm install --version "${CHART_VERSION}" prometheus-postgres-exporter prometheus-exporters/prometheus-postgres-exporter \
  --set 'config.database.secret.databaseUsername=postgres' \
  --set 'config.database.secret.databasePassword=postgres' \
  --set 'config.database.secret.databaseConnectionUrl="postgres.example.local:5432/postgres?ssl=disable"' \
  --set 'grafana.enabled=true'
```

#### Avoid deploying on same node / bare metal host as PostgresDB

As a best practice, avoid running the postgres-exporter on the same node / bare-metal host as the PostgresDB. This is
because if the postgres-exporter is running on the same node and this node fails, Prometheus can send an alert about the
failure of the node or that the postgres-exporter cannot be reached. However, it is not possible to react based on the
metrics that the postgres-exporter explicitly provides. Depending on the configuration of alerts, this may mean that the
corresponding notifications are not sent to the right person or group of people.

The following example prevent the postgres-exporter from running on nodes with a PostgresDB. The PostgresDB nodes has an
additional label `database=postgres`. The configuration is carried out in `values.yaml`.

```yaml
deployment:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
          - key: database
            operator: NotIn
            values:
            - postgres
```

### Network policies

Network policies can only take effect, when the used CNI plugin support network policies. The chart supports no custom
network policy implementation of CNI plugins. It's support only the official API resource of `networking.k8s.io/v1`.

The object networkPolicies can contains multiple networkPolicy definitions. There is currently only one example
predefined - it's named `default`. Further networkPolicy rules can easy be added by defining additional objects. For example:

> [!NOTE]
> The structure of each custom network policy must be equal like that of default. For this reason don't forget to define
> `annotations`, `labels` and the other properties as well.

```yaml
networkPolicies:
  enabled: false
  default: {}
  my-custom-network-policy: {}
```

The example below is an excerpt of the `values.yaml` file. The network policy `default` contains ingress rules to allow
incoming traffic from Prometheus. Additionally two egress rules are defined, to allow the application outgoing access to
the internal running DNS server `core-dns` and the external running postgres database listen on `10.14.243.12`.

> [!IMPORTANT]
> Please keep in mind, that the namespace and pod selector labels can be different from environment to environment. For
> this reason, there is are not default network policy rules defined.

```yaml
networkPolicies:
  enabled: true
  default:
    enabled: true
    annotations: {}
    labels: {}
    policyTypes:
    - Egress
    - Ingress
    egress:
    - to:
      - ipBlock:
          cidr: 10.14.243.12/32
      ports:
      - port: 5432
        protocol: TCP
    - to:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: kube-system
        podSelector:
          matchLabels:
           k8s-app: kube-dns
      ports:
      - port: 53
        protocol: TCP
      - port: 53
        protocol: UDP
    ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: monitoring
        podSelector:
          matchLabels:
            app.kubernetes.io/name: prometheus
      ports:
      - port: http
        protocol: TCP
```

## ArgoCD

### Daily execution of rolling updates

The behavior whereby ArgoCD triggers a rolling update even though nothing appears to have changed often occurs in
connection with the helm concept `checksum/secret`, `checksum/configmap` or more generally, [Automatically Roll
Deployments](https://helm.sh/docs/howto/charts_tips_and_tricks/#automatically-roll-deployments).

The problem with combining this concept with ArgoCD is that ArgoCD re-renders the Helm chart every time. Even if the
content of the config map or secret has not changed, there may be minimal differences (e.g., whitespace, chart version,
Helm render order, different timestamps).

This changes the SHA256 hash, Argo sees a drift and trigger a rolling update of the deployment. Among other things, this
can lead to unnecessary notifications from ArgoCD.

To avoid this, the annotation with the shasum must be ignored. Below is a diff that adds the `Application` to ignore all
annotations with the prefix `checksum`.

```diff
  apiVersion: argoproj.io/v1alpha1
  kind: Application
  spec:
+   ignoreDifferences:
+   - group: apps/v1
+     kind: Deployment
+     jqPathExpressions:
+     - '.spec.template.metadata.annotations | with_entries(select(.key | startswith("checksum")))'
```

## Parameters

### Global

| Name               | Description                               | Value |
| ------------------ | ----------------------------------------- | ----- |
| `nameOverride`     | Individual release name suffix.           | `""`  |
| `fullnameOverride` | Override the complete release name logic. | `""`  |

### Configuration

| Name                                              | Description                                                                                                                                                                                                                          | Value   |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------- |
| `config.database.existingSecret.enabled`          | Mount an existing secret containing the application specific `DATA_SOURCE_` prefixed environment variables.                                                                                                                          | `false` |
| `config.database.existingSecret.secretName`       | Name of the existing secret containing the application specific `DATA_SOURCE_` prefixed environment variables.                                                                                                                       | `""`    |
| `config.database.secret.annotations`              | Additional annotations of the secret containing the database credentials.                                                                                                                                                            | `{}`    |
| `config.database.secret.labels`                   | Additional labels of the secret containing the database credentials.                                                                                                                                                                 | `{}`    |
| `config.database.secret.databaseUsername`         | Database username. Will be defined as env `DATA_SOURCE_USER` as part of a secret.                                                                                                                                                    | `""`    |
| `config.database.secret.databasePassword`         | Database password. Will be defined as env `DATA_SOURCE_PASS` as part of a secret.                                                                                                                                                    | `""`    |
| `config.database.secret.databaseConnectionUrl`    | Complex database connection URL. Will be defined as env `DATA_SOURCE_URI` as part of a secret.                                                                                                                                       | `""`    |
| `config.exporterConfig.existingSecret.enabled`    | Mount an existing secret containing the key `exporterConfig.yaml`.                                                                                                                                                                   | `false` |
| `config.exporterConfig.existingSecret.secretName` | Name of the existing secret containing the key `exporterConfig.yaml`.                                                                                                                                                                | `""`    |
| `config.exporterConfig.secret.annotations`        | Additional annotations of the secret containing the `exporterConfig.yaml`.                                                                                                                                                           | `{}`    |
| `config.exporterConfig.secret.labels`             | Additional labels of the secret containing the `exporterConfig.yaml`.                                                                                                                                                                | `{}`    |
| `config.exporterConfig.secret.exporterConfig`     | Content of the `exporterConfig.yaml`. Further information can be found in the [README](https://github.com/prometheus-community/postgres_exporter?tab=readme-ov-file#multi-target-support-beta) file of the Postgres exporter binary. | `{}`    |
| `config.webConfig.existingSecret.enabled`         | Mount an existing secret containing the key `webConfig.yaml`.                                                                                                                                                                        | `false` |
| `config.webConfig.existingSecret.secretName`      | Name of the existing secret containing the key `webConfig.yaml`.                                                                                                                                                                     | `""`    |
| `config.webConfig.secret.annotations`             | Additional annotations of the secret containing the `webConfig.yaml`.                                                                                                                                                                | `{}`    |
| `config.webConfig.secret.labels`                  | Additional labels of the secret containing the `webConfig.yaml`.                                                                                                                                                                     | `{}`    |
| `config.webConfig.secret.webConfig`               | Content of the `webConfig.yaml`. Further [documentation](https://prometheus.io/docs/prometheus/latest/configuration/https/) is available on the official Prometheus website.                                                         | `{}`    |

### Deployment

| Name                                               | Description                                                                                                | Value                                   |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| `deployment.annotations`                           | Additional deployment annotations.                                                                         | `{}`                                    |
| `deployment.labels`                                | Additional deployment labels.                                                                              | `{}`                                    |
| `deployment.additionalContainers`                  | List of additional containers.                                                                             | `[]`                                    |
| `deployment.affinity`                              | Affinity for the postgres-exporter deployment.                                                             | `{}`                                    |
| `deployment.initContainers`                        | List of additional init containers.                                                                        | `[]`                                    |
| `deployment.dnsConfig`                             | dnsConfig of the postgres-exporter deployment.                                                             | `{}`                                    |
| `deployment.dnsPolicy`                             | dnsPolicy of the postgres-exporter deployment.                                                             | `""`                                    |
| `deployment.hostname`                              | Individual hostname of the pod.                                                                            | `""`                                    |
| `deployment.subdomain`                             | Individual domain of the pod.                                                                              | `""`                                    |
| `deployment.hostNetwork`                           | Use the kernel network namespace of the host system.                                                       | `false`                                 |
| `deployment.imagePullSecrets`                      | Secret to use for pulling the image.                                                                       | `[]`                                    |
| `deployment.postgresExporter.args`                 | Arguments passed to the postgres-exporter container.                                                       | `[]`                                    |
| `deployment.postgresExporter.env`                  | List of environment variables for the postgres-exporter container.                                         | `[]`                                    |
| `deployment.postgresExporter.envFrom`              | List of environment variables mounted from configMaps or secrets for the postgres-exporter container.      | `[]`                                    |
| `deployment.postgresExporter.image.registry`       | Image registry, eg. `docker.io`.                                                                           | `quay.io`                               |
| `deployment.postgresExporter.image.repository`     | Image repository, eg. `library/busybox`.                                                                   | `prometheuscommunity/postgres-exporter` |
| `deployment.postgresExporter.image.tag`            | Custom image tag, eg. `0.1.0`. Defaults to `appVersion`.                                                   | `""`                                    |
| `deployment.postgresExporter.image.pullPolicy`     | Image pull policy.                                                                                         | `IfNotPresent`                          |
| `deployment.postgresExporter.resources`            | CPU and memory resources of the pod.                                                                       | `{}`                                    |
| `deployment.postgresExporter.securityContext`      | Security context of the container of the deployment.                                                       | `{}`                                    |
| `deployment.postgresExporter.volumeMounts`         | Additional volume mounts.                                                                                  | `[]`                                    |
| `deployment.nodeSelector`                          | NodeSelector of the postgres-exporter deployment.                                                          | `{}`                                    |
| `deployment.priorityClassName`                     | PriorityClassName of the postgres-exporter deployment.                                                     | `""`                                    |
| `deployment.replicas`                              | Number of replicas for the postgres-exporter deployment.                                                   | `1`                                     |
| `deployment.restartPolicy`                         | Restart policy of the postgres-exporter deployment.                                                        | `""`                                    |
| `deployment.securityContext`                       | Security context of the postgres-exporter deployment.                                                      | `{}`                                    |
| `deployment.strategy.type`                         | Strategy type - `Recreate` or `RollingUpdate`.                                                             | `RollingUpdate`                         |
| `deployment.strategy.rollingUpdate.maxSurge`       | The maximum number of pods that can be scheduled above the desired number of pods during a rolling update. | `1`                                     |
| `deployment.strategy.rollingUpdate.maxUnavailable` | The maximum number of pods that can be unavailable during a rolling update.                                | `1`                                     |
| `deployment.terminationGracePeriodSeconds`         | How long to wait until forcefully kill the pod.                                                            | `60`                                    |
| `deployment.tolerations`                           | Tolerations of the postgres-exporter deployment.                                                           | `[]`                                    |
| `deployment.topologySpreadConstraints`             | TopologySpreadConstraints of the postgres-exporter deployment.                                             | `[]`                                    |
| `deployment.volumes`                               | Additional volumes to mount into the pods of the prometheus-exporter deployment.                           | `[]`                                    |

### Grafana

| Name                                              | Description                                                                                              | Value       |
| ------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | ----------- |
| `grafana.enabled`                                 | Enable integration into Grafana. Require the Prometheus operator deployment.                             | `false`     |
| `grafana.dashboardDiscoveryLabels`                | Labels that Grafana uses to discover resources. The labels may vary depending on the Grafana deployment. | `undefined` |
| `grafana.dashboards.postgresExporter.enabled`     | Enable deployment of Grafana dashboard `postgresExporter`.                                               | `true`      |
| `grafana.dashboards.postgresExporter.annotations` | Additional configmap annotations.                                                                        | `{}`        |
| `grafana.dashboards.postgresExporter.labels`      | Additional configmap labels.                                                                             | `{}`        |

### Ingress

| Name                  | Description                                                                                                          | Value   |
| --------------------- | -------------------------------------------------------------------------------------------------------------------- | ------- |
| `ingress.enabled`     | Enable creation of an ingress resource. Requires, that the http service is also enabled.                             | `false` |
| `ingress.className`   | Ingress class.                                                                                                       | `nginx` |
| `ingress.annotations` | Additional ingress annotations.                                                                                      | `{}`    |
| `ingress.labels`      | Additional ingress labels.                                                                                           | `{}`    |
| `ingress.hosts`       | Ingress specific configuration. Specification only required when another ingress controller is used instead of `t1k. | `[]`    |
| `ingress.tls`         | Ingress TLS settings. Specification only required when another ingress controller is used instead of `t1k``.         | `[]`    |

### Pod disruption

| Name                  | Description            | Value |
| --------------------- | ---------------------- | ----- |
| `podDisruptionBudget` | Pod disruption budget. | `{}`  |

### NetworkPolicies

| Name                                  | Description                                                                                           | Value   |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------- | ------- |
| `networkPolicies.enabled`             | Enable network policies in general.                                                                   | `false` |
| `networkPolicies.default.enabled`     | Enable the network policy for accessing the application by default. For example to scape the metrics. | `false` |
| `networkPolicies.default.annotations` | Additional network policy annotations.                                                                | `{}`    |
| `networkPolicies.default.labels`      | Additional network policy labels.                                                                     | `{}`    |
| `networkPolicies.default.policyTypes` | List of policy types. Supported is ingress, egress or ingress and egress.                             | `[]`    |
| `networkPolicies.default.egress`      | Concrete egress network policy implementation.                                                        | `[]`    |
| `networkPolicies.default.ingress`     | Concrete ingress network policy implementation.                                                       | `[]`    |

### Prometheus

| Name                                                | Description                                                                                                                                  | Value      |
| --------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| `prometheus.metrics.enabled`                        | Enable of scraping metrics by Prometheus.                                                                                                    | `true`     |
| `prometheus.metrics.podMonitor.enabled`             | Enable creation of a podMonitor. Excludes the existence of a serviceMonitor resource.                                                        | `false`    |
| `prometheus.metrics.podMonitor.annotations`         | Additional podMonitor annotations.                                                                                                           | `{}`       |
| `prometheus.metrics.podMonitor.enableHttp2`         | Enable HTTP2.                                                                                                                                | `true`     |
| `prometheus.metrics.podMonitor.followRedirects`     | FollowRedirects configures whether scrape requests follow HTTP 3xx redirects.                                                                | `false`    |
| `prometheus.metrics.podMonitor.honorLabels`         | Honor labels.                                                                                                                                | `false`    |
| `prometheus.metrics.podMonitor.labels`              | Additional podMonitor labels.                                                                                                                | `{}`       |
| `prometheus.metrics.podMonitor.interval`            | Interval at which metrics should be scraped. If not specified Prometheus' global scrape interval is used.                                    | `60s`      |
| `prometheus.metrics.podMonitor.path`                | HTTP path for scraping Prometheus metrics.                                                                                                   | `/metrics` |
| `prometheus.metrics.podMonitor.relabelings`         | RelabelConfigs to apply to samples before scraping. Prometheus Operator automatically adds relabelings for a few standard Kubernetes fields. | `[]`       |
| `prometheus.metrics.podMonitor.scrapeTimeout`       | Timeout after which the scrape is ended. If not specified, global Prometheus scrape timeout is used.                                         | `30s`      |
| `prometheus.metrics.podMonitor.scheme`              | HTTP scheme to use for scraping. For example `http` or `https`.                                                                              | `http`     |
| `prometheus.metrics.podMonitor.tlsConfig`           | TLS configuration to use when scraping the metric endpoint by Prometheus.                                                                    | `{}`       |
| `prometheus.metrics.serviceMonitor.enabled`         | Enable creation of a serviceMonitor. Excludes the existence of a podMonitor resource.                                                        | `false`    |
| `prometheus.metrics.serviceMonitor.annotations`     | Additional serviceMonitor annotations.                                                                                                       | `{}`       |
| `prometheus.metrics.serviceMonitor.labels`          | Additional serviceMonitor labels.                                                                                                            | `{}`       |
| `prometheus.metrics.serviceMonitor.enableHttp2`     | Enable HTTP2.                                                                                                                                | `true`     |
| `prometheus.metrics.serviceMonitor.followRedirects` | FollowRedirects configures whether scrape requests follow HTTP 3xx redirects.                                                                | `false`    |
| `prometheus.metrics.serviceMonitor.honorLabels`     | Honor labels.                                                                                                                                | `false`    |
| `prometheus.metrics.serviceMonitor.interval`        | Interval at which metrics should be scraped. If not specified Prometheus' global scrape interval is used.                                    | `60s`      |
| `prometheus.metrics.serviceMonitor.path`            | HTTP path for scraping Prometheus metrics.                                                                                                   | `/metrics` |
| `prometheus.metrics.serviceMonitor.relabelings`     | RelabelConfigs to apply to samples before scraping. Prometheus Operator automatically adds relabelings for a few standard Kubernetes fields. | `[]`       |
| `prometheus.metrics.serviceMonitor.scrapeTimeout`   | Timeout after which the scrape is ended. If not specified, global Prometheus scrape timeout is used.                                         | `30s`      |
| `prometheus.metrics.serviceMonitor.scheme`          | HTTP scheme to use for scraping. For example `http` or `https`.                                                                              | `http`     |
| `prometheus.metrics.serviceMonitor.tlsConfig`       | TLS configuration to use when scraping the metric endpoint by Prometheus.                                                                    | `{}`       |
| `prometheus.rules`                                  | Array of Prometheus rules for monitoring the application and triggering alerts.                                                              | `[]`       |

### Service

| Name                                     | Description                                                                                                                                                                                                | Value       |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `services.http.enabled`                  | Enable the service.                                                                                                                                                                                        | `true`      |
| `services.http.annotations`              | Additional service annotations.                                                                                                                                                                            | `{}`        |
| `services.http.externalIPs`              | External IPs for the service.                                                                                                                                                                              | `[]`        |
| `services.http.externalTrafficPolicy`    | If `service.type` is `NodePort` or `LoadBalancer`, set this to `Local` to tell kube-proxy to only use node local endpoints for cluster external traffic. Furthermore, this enables source IP preservation. | `Cluster`   |
| `services.http.internalTrafficPolicy`    | If `service.type` is `NodePort` or `LoadBalancer`, set this to `Local` to tell kube-proxy to only use node local endpoints for cluster internal traffic.                                                   | `Cluster`   |
| `services.http.ipFamilies`               | IPFamilies is list of IP families (e.g. `IPv4`, `IPv6`) assigned to this service. This field is usually assigned automatically based on cluster configuration and only required for customization.         | `[]`        |
| `services.http.labels`                   | Additional service labels.                                                                                                                                                                                 | `{}`        |
| `services.http.loadBalancerClass`        | LoadBalancerClass is the class of the load balancer implementation this Service belongs to. Requires service from type `LoadBalancer`.                                                                     | `""`        |
| `services.http.loadBalancerIP`           | LoadBalancer will get created with the IP specified in this field. Requires service from type `LoadBalancer`.                                                                                              | `""`        |
| `services.http.loadBalancerSourceRanges` | Source range filter for LoadBalancer. Requires service from type `LoadBalancer`.                                                                                                                           | `[]`        |
| `services.http.port`                     | Port to forward the traffic to.                                                                                                                                                                            | `9187`      |
| `services.http.sessionAffinity`          | Supports `ClientIP` and `None`. Enable client IP based session affinity via `ClientIP`.                                                                                                                    | `None`      |
| `services.http.sessionAffinityConfig`    | Contains the configuration of the session affinity.                                                                                                                                                        | `{}`        |
| `services.http.type`                     | Kubernetes service type for the traffic.                                                                                                                                                                   | `ClusterIP` |

### ServiceAccount

| Name                                              | Description                                                                                                                                         | Value   |
| ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `serviceAccount.existing.enabled`                 | Use an existing service account instead of creating a new one. Assumes that the user has all the necessary kubernetes API authorizations.           | `false` |
| `serviceAccount.existing.serviceAccountName`      | Name of the existing service account.                                                                                                               | `""`    |
| `serviceAccount.new.annotations`                  | Additional service account annotations.                                                                                                             | `{}`    |
| `serviceAccount.new.labels`                       | Additional service account labels.                                                                                                                  | `{}`    |
| `serviceAccount.new.automountServiceAccountToken` | Enable/disable auto mounting of the service account token.                                                                                          | `true`  |
| `serviceAccount.new.imagePullSecrets`             | ImagePullSecrets is a list of references to secrets in the same namespace to use for pulling any images in pods that reference this serviceAccount. | `[]`    |
| `serviceAccount.new.secrets`                      | Secrets is the list of secrets allowed to be used by pods running using this ServiceAccount.                                                        | `[]`    |
