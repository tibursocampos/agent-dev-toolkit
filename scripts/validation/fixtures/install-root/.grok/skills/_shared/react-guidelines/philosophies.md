# React Development Philosophies & Best Practices

This document outlines standard react best practices, state management patterns, and hook guidelines adapted from `mithi/react-philosophies`.

---

## 1. State Management Guidelines

* **Keep State Local by Default:** Do not put state in global stores (Redux, Zustand, Context) unless it is actually shared across multiple distant screens.
* **Lift State Up Wisely:** Lift state only to the nearest common ancestor of components that require the state.
* **Server State vs. UI State:**
  * Use dedicated query libraries (like **TanStack Query / SWR**) for caching, updating, and synchronizing data fetched from APIs.
  * Use local component states (`useState`, `useReducer`) strictly for temporary UI variables (like modal toggles, dropdown values, input fields).

---

## 2. Rules of Hooks and Custom Hooks

* **Follow the Rules of Hooks:** Never call hooks conditionally, inside loops, or inside nested helper functions.
* **Custom Hooks Composition:** Combine multiple primitive hooks (`useState`, `useEffect`) into clean custom hooks that describe the business capability (e.g. `useCart`, `useAuth`).
* **Clean Effects:** Minimize `useEffect` usage. Most effects can be replaced by event-driven event handlers or derived state.
  ```typescript
  // Bad - Unnecessary useEffect
  const [fullName, setFullName] = useState('');
  useEffect(() => {
      setFullName(`${firstName} ${lastName}`);
  }, [firstName, lastName]);

  // Good - Derived state
  const fullName = `${firstName} ${lastName}`;
  ```

---

## 3. Performance Optimization

* **Avoid Premature Optimization:** Do not wrap every callback or value in `useCallback` or `useMemo` unless you identify actual performance bottlenecks (like expensive computations or unnecessary renders of heavy child components).
* **React 19 Auto-Memoization:** Be aware of automatic compiler compiler optimization in React 19, which reduces the need for manual memoization.
* **Component Keys:** Always use unique, stable identifiers (like database IDs) for mapping lists in JSX. **Never** use array indexes as keys if the list can be filtered, sorted, or mutated.
