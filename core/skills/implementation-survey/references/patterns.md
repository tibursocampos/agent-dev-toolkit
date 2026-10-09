# Design pattern signals

The design pattern block is prose.

Name a pattern only when the opened structure shows that pattern. When no row below matches the structure, write that the pattern is not visible. Do not recommend a pattern.

| Visible structure | Name |
|-------------------|------|
| A caller passes a request object to one handler that performs that request | Command |
| A subject keeps listeners and notifies them when its state changes | Observer |
| One type presents a narrow surface and forwards the work to another type | Adapter |
| One type presents a single entry and forwards to several collaborators | Facade |
| One type hides construction of a family of related objects | Abstract Factory |
| One type assembles another through ordered steps on a builder | Builder |
| A caller depends on an abstraction while a separate type supplies the concrete object | Dependency Injection |
| One type holds the steps of a procedure and leaves a step to a subtype | Template Method |

An observed name cites `path:line` for the structure that shows the row. An inferred name states what was not in the diff. A partial resemblance is not a match: write that the pattern is not visible.
