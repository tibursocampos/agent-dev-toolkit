# React Clean Architecture and Component Design

This document details structural patterns and clean code principles specifically for React development, adapted from `rmanguinho/clean-react` and `askides/clean-architecture-react`.

---

## 1. Separation of Concerns & Clean Architecture

To keep components maintainable and testable, split the user interface from business logic:
* **Presentation Components:** Components should strictly focus on rendering markup, styling, and receiving event handlers via props. They must have no knowledge of HTTP clients, caching, or global stores.
* **Custom Hooks as Controllers:** Extract side effects, data fetching, validation, and local state coordination into custom hooks.
  ```tsx
  // Correct - Component only handles UI rendering
  export const UserProfile = () => {
      const { user, isLoading, handleUpdate } = useUserProfileController();

      if (isLoading) return <Spinner />;
      return <ProfileCard data={user} onSave={handleUpdate} />;
  };
  ```
* **Infrastructure Layer:** Network calls (axios/fetch), storage access, and external packages must live in separate helper services, not directly inside component files.

---

## 2. SOLID Principles in React

* **Single Responsibility Principle (SRP):**
  * One component should render a single distinct piece of UI. If a file grows to include multiple sub-components, split them into a nested folder or sister files.
* **Open/Closed Principle (OCP):**
  * Favor **composition** (`children` prop) over complex configurations to extend components.
* **Dependency Inversion Principle (DIP):**
  * Components should rely on data models/interfaces, not concrete HTTP client instances. Inject service contexts or pass clients via providers.

---

## 3. Directory and Folder Structure

Organize files by **Feature / Domain** rather than technical roles:
```
src/
├── features/
│   └── authentication/
│       ├── components/
│       │   ├── LoginForm.tsx
│       │   └── LoginForm.styles.css
│       ├── hooks/
│       │   └── useLoginController.ts
│       ├── services/
│       │   └── authService.ts
│       └── index.ts (Public API of the feature)
```
Keep CSS/styles co-located with their respective components.
