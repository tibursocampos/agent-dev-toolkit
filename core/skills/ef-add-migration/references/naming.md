## Naming patterns

| Change | Pattern | Example |
|--------|---------|---------|
| New entity | `Create<Entity>` | `CreateOrderLine` |
| Add column | `Add<Property>To<Entity>` | `AddExternalCodeToMaterial` |
| Remove column | `Remove<Property>From<Entity>` | `RemoveLegacyIdFromCustomer` |
| Schema tweak | `Alter<Entity>` | `AlterInvoice` |
| Seed data | `<Entity>Seed` or `<Description>Seed` | `PermissionsSeed` |

Infer from `git diff` / `git status` when the user does not supply a name.

---
