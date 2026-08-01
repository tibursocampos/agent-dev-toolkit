# Frontend Testing (Cross-Stack)

Testing patterns shared across React, Angular, Vue, and vanilla frontends. Stack-specific runners live in each `*-guidelines/` folder.

## Structure

Every test uses explicit sections:

```typescript
// Arrange
// Act
// Assert
```

Extract shared setup to test utilities or fixtures - do not duplicate arrange logic in every file.

## Unit and component tests

| Stack | Typical tools |
|-------|----------------|
| React | Jest or Vitest + React Testing Library |
| Angular | Jasmine/Karma or Jest + TestBed |
| Vue | Vitest + Vue Test Utils |
| Vanilla | Vitest or Jest + jsdom |

**Assert behavior, not implementation** - query by role, label, or text; avoid testing private state.

## Integration and E2E smoke

- **Cypress** or **Playwright** for critical user paths (login, checkout, save).
- Keep smoke suites fast (< 5 minutes CI); full E2E optional on nightly.
- Use stable `data-testid` only when roles/labels are insufficient.

## Accessibility smoke

- Run **axe** (e.g. `jest-axe`, `@axe-core/playwright`) on representative pages or components.
- Fail on serious violations; document exceptions with issue links.
- Manual keyboard pass for new interactive flows.

## Coverage expectations

- New UI logic: tests for happy path and primary error/empty states per `DESIGN-BRIEF.md` state map.
- Do not add tests that only assert markup snapshots without behavior checks.

## CI alignment

Run the same commands locally before handoff:

```bash
npm test
npm run build
```

Use project-specific scripts when they differ (`ng test`, `vitest run`, etc.).
