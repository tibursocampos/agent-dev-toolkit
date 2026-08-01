# GitOps with ArgoCD

This page provides an overview of our GitOps architecture using ArgoCD for Kubernetes deployments.

## Architecture

We follow a **hub-and-spoke** architecture with two ArgoCD runtimes separated by environment type:

| Runtime | Clusters managed |
|---|---|
| `runtime-production` | All **production** clusters |
| `runtime-non-production` | All **non-production** clusters |

ArgoCD uses **ApplicationSets** to automatically generate `Application` resources for each cluster that matches a set of labels, eliminating the need to manually create individual ArgoCD Applications per cluster.

## Repositories

We separate deployment concerns into different repositories:

| Repository | Purpose | Audience |
|---|---|---|
| `argo-apps` | Application deployments (Helm values, appsettings) | **All developers** |
| `argo-apps-sre` | SRE services and raw Kubernetes manifests | SRE team |
| `platform-isc` | ArgoCD system configuration (cluster registrations, runtimes) | Platform / SRE |

## Cluster Labels

Each cluster registered in ArgoCD carries labels used to target deployments:

| Label | Description | Example values |
|---|---|---|
| `clusterNormalizedName` | Short, unique name per environment | `cluster-a`, `cluster-b` |
| `environmentType` | Environment classification | `prod`, `non-prod` |
| `clusterType` | Workload category | `payments`, `observability`, `core` |

## How Deployments Work

1. A change is merged into the `main` branch of `argo-apps`.
2. ArgoCD detects the change and syncs the corresponding ApplicationSet.
3. Helm renders the chart with the merged values and applies the resulting manifests to the target cluster.
4. The application status is visible in the GitOps UI platform.

> [!NOTE]
> ArgoCD merges Helm values in the order they are listed in the Argo ApplicationSet/Application manifest (later entries override earlier ones).
