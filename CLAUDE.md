# Farshore: notes for Claude

- Read `docs/design-spec.md` before proposing features. Every feature must serve at least one pillar and break none.
- Scope moves right, never left: new ideas go into a later phase unless something of equal size comes out. The "Cap (not in v1)" column is a promise.
- Server-authoritative from day one: clients send intents, the server decides. Every player action goes through the single `can(player, action, target)` gate.
- GDScript only unless profiling demands C++. Design for gamepad from the start.
- Never use em dashes in docs, comments or commit messages.
