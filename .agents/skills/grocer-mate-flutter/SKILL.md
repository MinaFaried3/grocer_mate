---
name: grocer-mate-flutter
description: Generate and refactor Dart and Flutter code in GrocerMate. Use for changes to screens, controllers, routing, dependency injection, repositories, or platform services in this project.
---

# GrocerMate Flutter

1. Inspect `git status --short`, the relevant `git diff` and `git diff --cached` output, and any relevant untracked files. Follow the current code and the user's latest direction when the branch and working tree differ.
2. Trace the real entry point and choose the owner before editing. Read `lib/core/routing/app_router.dart` for route and shell lifetimes and `lib/core/injection/dependencies.dart` for factories. Browse and product details own separate controllers. The market shell shares shopping state across product pages, Cart, and Saved.
3. Make the smallest change that preserves existing callers. A product route can create its controller in `BlocProvider.create` and let the controller load data. A repository that only reads connectivity can accept `bool Function()` while a bloc that retries on reconnection can also accept a `Stream<bool>`. Keep platform imports in the adapter so controller tests can supply a fake.
4. Verify the affected behavior through its normal entry point. For startup or routing changes, check cold deep links, route-local initialization, and state shared across tabs. For connection changes, check cached reads, manual Offline mode, and queued checkout replay where affected. Run `dart format` on changed Dart files, `flutter analyze`, and the relevant `flutter test` cases. Verify runtime lifecycle changes with a Flutter hot reload or restart when available.

The [repository rule](../../../AGENTS.md) defines the conventions this workflow applies.
