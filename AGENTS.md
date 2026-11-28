# GrocerMate agent guidance

When generating or refactoring Dart code, use the [GrocerMate Flutter skill](.agents/skills/grocer-mate-flutter/SKILL.md) and follow these conventions.

- Read the current working tree before editing. Review relevant staged, unstaged, and untracked changes. Build on those edits and preserve unrelated work.
- Keep composition in `lib/main.dart`, dependency registration in `lib/core/injection`, and routing in `lib/core/routing`. Keep shared platform services under `lib/core` and controllers and widgets in the feature that owns them, including `lib/features/app` for app presentation.
- Use one idempotent dependency initializer at startup for app-wide needs. Resolve feature dependencies when the destination builds or the operation needs them. Keep tap handlers limited to navigation and put controller providers at the smallest route or shell that shares their state.
- Let controllers handle loading, retries, and state. Keep repositories out of widget context and keep the root provider scope for app-wide state.
- Isolate a third-party package behind a small interface and one adapter when callers need to be package-independent. Use the package's existing behavior and ordinary Dart values at the boundary. For example, `ConnectionChecker` exposes a boolean status and `PlatformConnectionChecker` owns the `connectivity_plus` import.
- Pass the smallest dependency the caller needs. Use `() => connection.online` for a live read and pass a stream where a consumer reacts to changes. Use direct names and introduce a class, interface, package, or global widget only when it serves a concrete requirement.
- Let controllers subscribe when created and cancel subscriptions when closed. Wait at startup only for required app-wide state, such as connectivity for a cold deep link. Keep offline behavior and reconnect retries independent of connectivity feedback in the UI.
