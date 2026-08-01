# Python Clean Code & Design Principles

This document defines core clean code principles specifically adapted for Python applications. These guidelines ensure that any Python code generated or reviewed by the agent is simple, robust, and readable.

---

## 1. Clean Code Basics

* **The Zen of Python (PEP 20):** Read and follow the core philosophy of Python:
  * Beautiful is better than ugly.
  * Explicit is better than implicit.
  * Simple is better than complex.
  * Readability counts.
* **Meaningful Naming:**
  * Use descriptive, intention-revealing names for variables, functions, classes, and packages.
  * Avoid single-letter variables except for trivial loop counters (like `i`, `j`).
  * Variables and functions must use `snake_case`.
  * Classes must use `PascalCase`.
  * Constants must use `UPPER_SNAKE_CASE`.

---

## 2. Functions & Modular Design

* **Do One Thing (Single Responsibility):** Functions should be short and do exactly one thing. If a function contains nested logic that does something else (like formatting or validation), extract it.
* **Arguments Limit:** Keep the number of function arguments to a minimum (ideally 2 or fewer). Use dataclasses or dictionary configs if you need to pass multiple parameters.
* **No Side Effects:** Functions should avoid modifying global state or passed arguments unexpectedly unless that is the explicit, documented behavior.

---

## 3. SOLID Principles in Python

* **Single Responsibility Principle (SRP):** A class should have only one reason to change. Separate business logic from data access and API presentation.
* **Open/Closed Principle (OCP):** Modules should be open for extension but closed for modification. Use inheritance or composition (e.g., protocol classes, abstract base classes) to allow polymorphism.
* **Liskov Substitution Principle (LSP):** Subtypes must be substitutable for their base types without altering correctness.
* **Interface Segregation Principle (ISP):** Avoid fat interfaces. In Python, use small `Protocol` definitions (structural typing) rather than large abstract base classes.
* **Dependency Inversion Principle (DIP):** Depend upon abstractions (like Protocols or Abstract Base Classes) rather than concrete implementations.

---

## 4. Common Pythonic Idioms

* **List Comprehensions:** Use comprehensions for simple list/dictionary generation, but avoid them if they exceed a single line or become complex.
  ```python
  # Correct
  squares = [x * x for x in range(10)]
  
  # Wrong - too complex
  data = [item.name for item in items if item.is_active if item.role == 'admin' or item.is_super]
  ```
* **Explicit Exception Handling:**
  * Never catch a generic `Exception` unless you are re-raising it or logging it at a high-level boundary.
  * Catch specific exceptions (e.g. `KeyError`, `ValueError`, `FileNotFoundError`).
  * Use exception chaining (`raise CustomException("error") from original_err`) to preserve context.
* **Context Managers:** Always use `with` statements for resource management (files, network connections, locks) to ensure they are cleaned up.
