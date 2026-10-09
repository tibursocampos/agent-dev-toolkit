# Design patterns

Single vocabulary for naming a design pattern. English only. One file for the closed list. Do not add a file per pattern.

Name a pattern only when its **Signals** appear in the diff or in the immediate callee. Cite the name. Do not recommend adopting a pattern. Do not use a name outside this list.

## Closed list

### Strategy

**Intent:** Swap one algorithm behind a stable operation.

**Signals:** One operation, several interchangeable implementations, and the caller selects an implementation without a growing conditional.

**Not this:** A single branch that still owns the algorithm, or a subclass that changes unrelated behavior.

**Name only:** Strategy.

### State

**Intent:** Let an object change behavior when its internal state changes.

**Signals:** Behavior depends on an explicit state, and transitions move between state types rather than through a central conditional.

**Not this:** A status flag checked in one method, or a workflow engine.

**Name only:** State.

### Decorator

**Intent:** Add behavior by wrapping an object that already satisfies the same contract.

**Signals:** A wrapper implements the same contract as the wrapped object and forwards the call after or before the added behavior.

**Not this:** A subclass that replaces the original type, or a helper that the caller invokes beside the object.

**Name only:** Decorator.

### Factory

**Intent:** Hide which concrete type is created behind a creation operation.

**Signals:** Callers ask a creation operation for a contract and do not construct the concrete type themselves.

**Not this:** A constructor called at the use site, or a builder that assembles a complex object step by step.

**Name only:** Factory.

### Builder

**Intent:** Assemble a complex object through ordered steps and a final build.

**Signals:** Construction is split into steps, optional parts stay out of a long constructor, and a final operation returns the object.

**Not this:** A factory that returns one ready object in a single call, or a mutable DTO filled by property assignment.

**Name only:** Builder.

### Facade

**Intent:** Offer one simpler entry over a set of collaborating types.

**Signals:** Callers use one type, and that type forwards to several existing collaborators that stay hidden from the caller.

**Not this:** A new domain model, or a wrapper around a single object.

**Name only:** Facade.

### Adapter

**Intent:** Make an existing type satisfy a contract the caller already uses.

**Signals:** A thin type translates one contract into another, and the caller depends on the target contract.

**Not this:** A decorator that keeps the same contract, or a rewrite of the adapted type.

**Name only:** Adapter.

### Observer

**Intent:** Notify dependents when a subject changes, without the subject naming them.

**Signals:** A subject keeps subscribers, and a change notifies those subscribers through a shared notification contract.

**Not this:** A direct call to a known collaborator, or a message bus with its own delivery guarantees.

**Name only:** Observer.

### Specification

**Intent:** Express a business rule as an object that can be checked and combined.

**Signals:** A rule object answers whether a candidate matches, and rules combine without embedding the predicate in the caller.

**Not this:** A one-off `if` in the use site, or a persistence query that only the database understands.

**Name only:** Specification.

### Chain of responsibility

**Intent:** Pass a request along handlers until one handles it.

**Signals:** Handlers share a contract, each may decline, and the next handler receives the request.

**Not this:** A fixed pipeline where every stage always runs, or one method with an ordered conditional.

**Name only:** Chain of responsibility.

### Template method

**Intent:** Fix the steps of an algorithm and let subclasses replace selected steps.

**Signals:** A base operation calls overridable steps in a fixed order, and subclasses replace steps without reordering the algorithm.

**Not this:** A strategy object selected by the caller, or a copy of the whole algorithm in each subclass.

**Name only:** Template method.

### Null object

**Intent:** Represent "nothing to do" with an object that satisfies the contract.

**Signals:** Callers invoke the contract without a null check, and the do-nothing implementation is a real type.

**Not this:** A null check at every call site, or an optional value the caller still unwraps.

**Name only:** Null object.

### Singleton

**Intent:** None as a recommended pattern. A single shared instance is a smell when the code reaches for global mutable access.

**Signals:** One process-wide instance, usually reached through a static accessor, with callers that cannot substitute a different instance.

**Not this:** A smell to praise. Prefer an explicit dependency passed into the caller. A single composition-root registration is not this name.

**Name only:** Singleton. Mark it as a smell.

## Architecture pointers

These names are not in the closed list. Point at the architecture file that already describes them. Do not restate that file here.

| Name | Pointer |
|------|---------|
| Ports and adapters | [concentric-dependency.md](architecture/concentric-dependency.md) |
| Aggregate | [ddd-tactical.md](architecture/ddd-tactical.md) |
| Value object | [ddd-tactical.md](architecture/ddd-tactical.md) |
| Repository | [ddd-tactical.md](architecture/ddd-tactical.md) |
| Outbox | [event-driven.md](architecture/event-driven.md) |
