# NuGet Package Source Mapping

We have adopted **NuGet Package Source Mapping** to increase security, reliability, and control over which packages can be downloaded from each NuGet feed.

This configuration is now **mandatory for any project that uses more than one NuGet source** (for example: `nuget.org` alongside `InternalFeed`).

Using package source mapping ensures:
- Packages from external feeds cannot accidentally override our internal packages  
- Build reproducibility  
- Protection against dependency poisoning  
- Consistent behavior across all repositories  
- Clear separation of public vs. internal packages

## When You Must Configure Package Source Mapping

If your `NuGet.config` contains **more than one package source**, you **must** configure a `<packageSourceMapping>` section to ensure each package resolves from the correct source.

## Required Package Source Mapping Example

```xml
<configuration>
  <packageSources>
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
    <add
      key="INTERNAL_FEED"
      value="https://pkgs.internal-registry.com/_packaging/InternalFeed/nuget/v3/index.json"
    />
  </packageSources>
  <packageSourceMapping>
    <packageSource key="nuget.org">
      <!-- Wildcard for nuget.org handles all standard packages not matched elsewhere -->
      <package pattern="*" />
    </packageSource>
    <packageSource key="INTERNAL_FEED">
      <!-- Only specific internal namespaces should be fetched from the private feed -->
      <package pattern="InternalNamespace.*" />
      <package pattern="CompanyPlatform.*" />
    </packageSource>
  </packageSourceMapping>
</configuration>
```

## Notes

- **Any package not matching the patterns in the specific internal feeds will fall back to `nuget.org`.**
- You may add patterns if new internal packages are created, but avoid wildcards in private feeds that could redirect public packages unintentionally.
- If using custom or additional internal sources, you must extend this mapping.
