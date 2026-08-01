# Angular Naming and Layout Conventions

These layout, folder structure, and naming conventions for Angular applications are adapted from the classic `johnpapa/angular-styleguide`.

---

## 1. File Naming Rules

* **Pattern:** Name files using kebab-case and include the type of the class as a second suffix:
  `[name].[type].ts`
* **Extensions:**
  * Components: `order-list.component.ts`
  * Services: `order.service.ts`
  * Directives: `dropdown.directive.ts`
  * Pipes: `currency-format.pipe.ts`
  * Guards: `auth.guard.ts`
* **Unit Tests:** Co-locate unit test specs next to their target files using the `.spec.ts` suffix (e.g. `order-list.component.spec.ts`).

---

## 2. Structural Conventions

* **Rule of One:** Define exactly one component, service, or pipe per file.
* **Component Selectors:** Always use kebab-case for element selectors and camelCase for attribute selectors. Use a consistent custom prefix to avoid conflicts with HTML5 tags:
  ```typescript
  @Component({
      selector: 'ag-order-card', // Custom prefix 'ag'
      ...
  })
  ```
* **Separation of Template/Styles:** For components containing more than 3 lines of HTML or CSS, write the template and styles in separate files (`.component.html`, `.component.css`).

---

## 3. Directory Organization

* **Feature Folder Structure:** Group files in a folder named after the business feature it represents.
* **Core & Shared:**
  * `core/`: Singleton services, interceptors, and guards needed globally.
  * `shared/`: Reusable dumb components, pipes, and directives shared across multiple feature modules.
