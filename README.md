# Prometheus PostgreSQL exporter

This helm chart enables the deployment of a Prometheus metrics exporter for PostgreSQL databases and allows the
individual configuration of additional containers/initContainers, mounting of volumes, defining additional environment
variables, apply a user-defined web-config.yaml and much more.

Chapter [configuration and installation](#helm-configuration-and-installation) describes the basics how to configure helm
and use it to deploy the exporter. It also contains further configuration examples.

Furthermore, this helm chart unit tests to detect regressions and stabilize the deployment. Additionally, this helm
chart is tested for deployment scenarios with ArgoCD.

> ![NOTE]
> This is not the official *community* helm chart of the Prometheus metric exporter for PostgreSQL databases. You can
> find the official community chart [here](https://github.com/prometheus-community/helm-charts).

## Helm: configuration and installation

1. A helm chart repository must be configured, to pull the helm charts from.
2. All available parameters are [here](#parameters). The parameters can be defined via the helm `--set` flag or directly
   as part of a `values.yaml` file. The following example defines the `prometheus-exporter` repository and use the
   `--set` flag for a basic deployment.

```bash
helm repo add prometheus-exporter https://charts.cryptic.systems/prometheus-exporter
helm repo update
helm install prometheus-exporter/prometheus-postgres-exporter prometheus-postgres-exporter \
  --set 'config.database.secret.databaseUsername=postgres' \
  --set 'config.database.secret.databasePassword=postgres' \
  --set 'config.database.secret.databaseConnectionUrl="postgres.example.local:5432/postgres?ssl=disable"'
```

Instead of passing all parameters via the *set* flag, it is also possible to define them as part of the `values.yaml`.
The following command downloads the `values.yaml` for a specific version of this chart. Please keep in mind, that the
version of the chart must be in sync with the `values.yaml`. Newer *minor* versions can have new features. New *major*
versions can break something!

```bash
helm show values prometheus-exporter/prometheus-postgres-exporter --version 0.1.0 > values.yaml
```

A complete list of available helm chart versions can be displayed via the following command:

```bash
helm search repo prometheus-postgres-exporter --versions
```

### Examples

The following examples serve as individual configurations and as inspiration for how deployment problems can be solved.

### TLS authentication and encryption

The first example shows how to deploy the metric exporter with TLS encryption. The verification of the custom TLS
certification will be skipped by Prometheus.

> [!WARN]
> A TLS secret with the name `prometheus-postgresql-exporter-http` containing a `ca.crt`, `tls.key` and `tls.crt` is
> already present.

```bash
helm install prometheus-exporter/prometheus-postgres-exporter prometheus-postgres-exporter \
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
  --set 'prometheus.serviceMonitor.enabled=true' \
  --set 'prometheus.serviceMonitor.scheme=https' \
  --set 'prometheus.serviceMonitor.tlsConfig.insecureSkipVerify=true'
```

If the Prometheus pod has a TLS certificate mounted and is also signed by the private key of the CA which issued the TLS
certificate for the metrics exporter - TLS certificate verification can be enabled. The following flags must be
replaced:

```diff
  helm install prometheus-exporter/prometheus-postgres-exporter prometheus-postgres-exporter \
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
    --set 'prometheus.serviceMonitor.enabled=true' \
    --set 'prometheus.serviceMonitor.scheme=https' \
-   --set 'prometheus.serviceMonitor.tlsConfig.insecureSkipVerify=true' \
+   --set 'prometheus.serviceMonitor.tlsConfig.caFile=/etc/prometheus/tls/ca.crt' \
+   --set 'prometheus.serviceMonitor.tlsConfig.certFile=/etc/prometheus/tls/tls.crt' \
+   --set 'prometheus.serviceMonitor.tlsConfig.keyFile=/etc/prometheus/tls/tls.key'
```

## Parameters

### Global

| Name               | Description                               | Value |
| ------------------ | ----------------------------------------- | ----- |
| `nameOverride`     | Individual release name suffix.           | `""`  |
| `fullnameOverride` | Override the complete release name logic. | `""`  |

### Configuration

| Name                                              | Description                                                                                                                                       | Value   |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `config.database.existingSecret.enabled`          | Mount an existing secret containing the application specific `DATA_SOURCE_` prefixed environment variables.                                       | `false` |
| `config.database.existingSecret.secretName`       | Name of the existing secret containing the application specific `DATA_SOURCE_` prefixed environment variables.                                    | `""`    |
| `config.database.secret.annotations`              | Additional annotations of the secret containing the database credentials.                                                                         | `{}`    |
| `config.database.secret.labels`                   | Additional labels of the secret containing the database credentials.                                                                              | `{}`    |
| `config.database.secret.databaseUsername`         | Database username. Will be defined as env `DATA_SOURCE_USER` as part of a secret.                                                                 | `""`    |
| `config.database.secret.databasePassword`         | Database password. Will be defined as env `DATA_SOURCE_PASS` as part of a secret.                                                                 | `""`    |
| `config.database.secret.databaseConnectionUrl`    | Complex database connection URL. Will be defined as env `DATA_SOURCE_URI` as part of a secret.                                                    | `""`    |
| `config.exporterConfig.existingSecret.enabled`    | Mount an existing secret containing the key `exporter_config.yaml`.                                                                               | `false` |
| `config.exporterConfig.existingSecret.secretName` | Name of the existing secret containing the key `exporter_config.yaml`.                                                                            | `""`    |
| `config.exporterConfig.secret.annotations`        | Additional annotations of the secret containing the `exporterConfig.yaml`.                                                                        | `{}`    |
| `config.exporterConfig.secret.labels`             | Additional labels of the secret containing the `exporterConfig.yaml`.                                                                             | `{}`    |
| `config.exporterConfig.secret.exporterConfig`     | Content of the `exporterConfig.yaml`. Further information can be found [here](https://prometheus.io/docs/prometheus/latest/configuration/https/). | `{}`    |
| `config.webConfig.existingSecret.enabled`         | Mount an existing secret containing the key `webConfig.yaml`.                                                                                     | `false` |
| `config.webConfig.existingSecret.secretName`      | Name of the existing secret containing the key `webConfig.yaml`.                                                                                  | `""`    |
| `config.webConfig.secret.annotations`             | Additional annotations of the secret containing the `webConfig.yaml`.                                                                             | `{}`    |
| `config.webConfig.secret.labels`                  | Additional labels of the secret containing the `webConfig.yaml`.                                                                                  | `{}`    |
| `config.webConfig.secret.webConfig`               | Content of the `webConfig.yaml`. Further information can be found [here](https://prometheus.io/docs/prometheus/latest/configuration/https/).      | `{}`    |

### Deployment

| Name                                               | Description                                                                                                | Value                                   |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| `deployment.annotations`                           | Additional deployment annotations.                                                                         | `{}`                                    |
| `deployment.labels`                                | Additional ingress labels.                                                                                 | `{}`                                    |
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
| `deployment.postgresExporter.volumeMounts`         | Additional volume mounts.                                                                                  | `{}`                                    |
| `deployment.nodeSelector`                          | NodeSelector of the postgres-exporter deployment.                                                          | `{}`                                    |
| `deployment.priorityClassName`                     | PriorityClassName of the postgres-exporter deployment.                                                     | `""`                                    |
| `deployment.replicaCount`                          | Number of replicas for the postgres-exporter deployment.                                                   | `1`                                     |
| `deployment.securityContext`                       | Security context of the postgres-exporter deployment.                                                      | `{}`                                    |
| `deployment.strategy.type`                         | Strategy type - `Recreate` or `Rollingupdate`.                                                             | `Recreate`                              |
| `deployment.strategy.rollingUpdate.maxSurge`       | The maximum number of pods that can be scheduled above the desired number of pods during a rolling update. | `1`                                     |
| `deployment.strategy.rollingUpdate.maxUnavailable` | The maximum number of pods that can be unavailable during a rolling update.                                | `1`                                     |
| `deployment.terminationGracePeriodSeconds`         | How long to wait until forcefully kill the pod.                                                            | `60`                                    |
| `deployment.tolerations`                           | Tolerations of the postgres-exporter deployment.                                                           | `[]`                                    |
| `deployment.topologySpreadConstraints`             | TopologySpreadConstraints of the postgres-exporter deployment.                                             | `[]`                                    |
| `deployment.volumes`                               | Additional volumes to mount into the pods of the Prometheus-exporter deployment.                           | `[]`                                    |

### Grafana

| Name                                 | Description                                               | Value   |
| ------------------------------------ | --------------------------------------------------------- | ------- |
| `grafana.enabled`                    | Enable integration into Grafana.                          | `false` |
| `grafana.dashboards.businessMetrics` | Enable deployment of Grafana dashboard `businessMetrics`. | `true`  |

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

### Network

| Name              | Description                                                                                                        | Value |
| ----------------- | ------------------------------------------------------------------------------------------------------------------ | ----- |
| `networkPolicies` | Deploy network policies based on the used container network interface (CNI) implementation - like calico or weave. | `{}`  |

### Prometheus

| Name                                                | Description                                                                                                                                  | Value      |
| --------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| `prometheus.metrics.enabled`                        | Enable of scraping metrics by Prometheus.                                                                                                    | `true`     |
| `prometheus.metrics.podMonitor.enabled`             | Enable creation of a podMonitor. Excludes the existence of a serviceMonitor resource.                                                        | `false`    |
| `prometheus.metrics.podMonitor.annotations`         | Additional podMonitor annotations.                                                                                                           | `{}`       |
| `prometheus.metrics.podMonitor.enableHttp2`         | Enable HTTP2.                                                                                                                                | `false`    |
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
| `prometheus.metrics.serviceMonitor.enableHttp2`     | Enable HTTP2.                                                                                                                                | `false`    |
| `prometheus.metrics.serviceMonitor.followRedirects` | FollowRedirects configures whether scrape requests follow HTTP 3xx redirects.                                                                | `false`    |
| `prometheus.metrics.serviceMonitor.honorLabels`     | Honor labels.                                                                                                                                | `false`    |
| `prometheus.metrics.serviceMonitor.interval`        | Interval at which metrics should be scraped. If not specified Prometheus' global scrape interval is used.                                    | `60s`      |
| `prometheus.metrics.serviceMonitor.path`            | HTTP path for scraping Prometheus metrics.                                                                                                   | `/metrics` |
| `prometheus.metrics.serviceMonitor.port`            | HTTP port for scraping Prometheus metrics.                                                                                                   | `9187`     |
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