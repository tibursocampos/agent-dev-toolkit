# Project References vs Package References

This page provides an overview of how to easily switch between **PackageReference** and **ProjectReference** in .NET projects. This workflow is especially useful when multiple shared libraries are extracted from a monolithic repository, and developers need to locally test changes in these shared libraries without publishing new NuGet packages.

## What is DNT?

**DNT (DotNetTools)** is a command-line tool that helps automate the replacement of `PackageReference` entries with `ProjectReference` entries (and vice-versa) based on a configuration file.

## How to Use

### 1. Clone the repositories

Clone both the main application repository and the shared library repository **in the same root folder**, for example:

```text
/workspace/
   ├── application-repo
   └── shared-library-repo
```

### 2. Run DNT commands

With a `switcher.json` file configured and committed into the main application repository, you can simply run the following commands:

#### Switch to local project references

```bash
dnt switch-to-projects
```

This command updates all `.csproj` files, replacing:
- `PackageReference` -> `ProjectReference`

Now you can easily test local changes from the shared library inside the main project.

#### Switch back to package references

```bash
dnt switch-to-packages
```

This restores the original references:
- `ProjectReference` -> `PackageReference`

## About `switcher.json`

The `switcher.json` file is committed to the repository, allowing any developer to use the tool consistently without additional setup. It defines which packages map to which local project paths during the switch process.

> [!TIP]
> For more details and to learn how to create your own `switcher.json`, check the DNT documentation: https://github.com/RicoSuter/DNT
