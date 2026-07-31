# Deployment Process

This page describes how to deploy an application using our central GitOps `argo-apps` repository.

Every deployment is a **pull request** - ArgoCD syncs automatically after the PR is merged into the `main` branch.

## Folder Structure

The repository stores the Helm values and application settings for all applications deployed via ArgoCD.

```text
argo-apps/
├── applications/
│   └── {app-name}/
│       ├── {app-name}.yaml        # ArgoCD ApplicationSet definition
│       ├── shared.yaml            # Values shared across all environments (optional)
│       ├── non-prod/
│       │   └── {cluster}/
│       │       ├── Chart.yaml     # Helm chart reference
│       │       ├── values.yaml    # Application Helm values
│       │       └── appsettings.yaml  # App-specific settings (optional)
│       └── prod/
│           └── {cluster}/
│               ├── Chart.yaml
│               ├── values.yaml
│               └── appsettings.yaml
│
└── clusters/
    ├── non-prod/
    │   └── {cluster}/
    │       └── shared.yaml       # Shared values for ALL apps in this cluster
    └── prod/
        └── {cluster}/
            └── shared.yaml
```

- `shared.yaml` files are optional and can be used to define values common to all environments or all applications in a cluster, reducing duplication. 
- `appsettings.yaml` files are optional and can be used to define application configurations that will be mounted as ConfigMaps.

## Deploying a New Version

To deploy a new image version of an existing application:

1. Open `applications/{app-name}/{environmentType}/{cluster}/values.yaml`
2. Update the image tag:
   ```yaml
   image:
     tag: "1.2.3"
   ```
3. Open a Pull Request targeting the `main` branch.
4. Get your PR reviewed and approved.
5. Merge - ArgoCD will sync automatically.

## Adding a New Application

When creating a new application, the folder structure above must be created. 

1. **Create the folder structure** for your application.
2. **Create the ApplicationSet definition** (`{app-name}.yaml`). Adjust cluster selectors, paths, and sync policies.
3. **Create values** (`values.yaml`) for each cluster/environment with your application configuration.
4. **Create appsettings** (`appsettings.yaml`) if your app requires specific JSON-based or text configuration.
5. **Add CODEOWNERS entry**: Update `.github/CODEOWNERS` to assign the responsible team for your application folder.
6. **Commit and open a PR**.

After the PR is merged, ArgoCD detects the new ApplicationSet and deploys automatically to matching clusters.
