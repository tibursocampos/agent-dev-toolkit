# Google Python Style & Coding Conventions

These style conventions represent the code layout, typing, and formatting standards adapted from Google's Python Style Guide.

---

## 1. Code Style and Formatting

* **Indentation:** Use 4 spaces per indentation level. Do not use tabs.
* **Line Length Limit:** Limit lines to **80 characters** for code. You may wrap lines using parenthesis or backslashes if necessary.
* **Imports:**
  * Imports should be on separate lines.
  * Group imports in the following order, separated by a blank line:
    1. Standard library imports.
    2. Related third-party imports.
    3. Local application/library-specific imports.
  * Avoid wildcard imports (`from module import *`).
* **Braces and Whitespace:**
  * Do not use spaces directly inside parentheses, brackets, or braces.
  * Avoid trailing whitespace.

---

## 2. Naming Conventions

* **Modules/Packages:** `module_name.py`, `package_name`. Short, lowercase names. Avoid underscores if possible.
* **Classes:** `ClassName`. CapitalizedWords (PascalCase).
* **Functions / Methods:** `function_name()`, `method_name()`. Lowercase with words separated by underscores (snake_case).
* **Variables:** `variable_name`. Lowercase with words separated by underscores.
* **Constants:** `CONSTANT_NAME`. All capital letters with underscores.
* **Internal Attributes:** `_private_attribute`. Use a leading underscore for non-public API members (protected/private).

---

## 3. Type Annotations & Type Checking

* Use **type hints** for all function signatures and public members to enable static analysis:
  ```python
  from typing import List, Optional

  def fetch_user_names(user_ids: List[int]) -> List[str]:
      names: List[str] = []
      for user_id in user_ids:
          name = get_user_name(user_id)
          if name:
              names.append(name)
      return names
  ```
* Enforce type checking with `mypy` before committing or reviewing code.

---

## 4. Docstrings (Google Format)

* Use triple double-quotes (`"""`) for all docstrings.
* All modules, classes, and public functions must have a docstring describing their behavior, arguments, and return types:
  ```python
  def calculate_discount(price: float, discount_rate: float) -> float:
      """Calculates the final price after applying a discount rate.

      Args:
          price: The original price of the item.
          discount_rate: The rate of the discount (between 0.0 and 1.0).

      Returns:
          The discounted price.

      Raises:
          ValueError: If the discount rate is outside the valid range.
          TypeError: If inputs are not numbers.
      """
      if not (0.0 <= discount_rate <= 1.0):
          raise ValueError("Discount rate must be between 0.0 and 1.0")
      return price * (1.0 - discount_rate)
  ```
