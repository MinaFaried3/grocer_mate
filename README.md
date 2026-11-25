# GrocerMate

A Flutter grocery storefront with a local mock market. Browse and filter groceries, manage a cart and saved items, and review stock or price changes at checkout.

## Run

Use Flutter 3.50 or later with Dart 3.14 or later. No API credentials or backend are required.

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

For Chrome, run `flutter run -d chrome --no-web-resources-cdn`. Android, iOS, and web project files are included. The app follows the system light or dark theme.

## Try the offline checkout

The [25-second walkthrough](demo/grocermate_walkthrough.mp4) shows search, the saved list, an offline purchase, and checkout review after reconnecting.

1. Browse the catalog online once. Search for **milk**, add **Milk 2%**, then clear the search and add **Sourdough Bread**.
2. In **Cart**, move an item to **Saved**, then open **Saved** and move it back. **Select items** enables bulk moves in both lists.
3. From the cart, open **Demo settings**, choose **Price and stock changes**, turn on **Simulate offline**, and tap **Done**.
4. Tap **Queue purchase**. The app keeps the queued order and any new cart edits separate.
5. Turn off **Simulate offline**. The app rechecks the queued order and opens a review sheet. Accept new prices, reduce quantities, or remove items before resubmitting.

The mock scenario applies to the next purchase and persists its catalog changes. The mixed scenario increases the first cart line’s price and makes the second line unavailable. The stock scenario demonstrates a reduced quantity when the first line has at least two units. The demo mode works independently of the device’s connection. A fresh web load still needs the static app files from its host.

## Implementation

- `lib/main.dart` initializes Flutter and launches the app. `lib/app` wires dependencies, navigation, theming, and the local mock market.
- `lib/core` contains shared connectivity, storage, formatting, and UI components.
- `lib/features/catalog` handles browsing, product details, category and brand filters, 400 ms debounced search, and page retries. It uses the latest cached snapshot for filtering and pagination and refreshes on reconnect, a checkout update, or pull to refresh.
- `lib/features/shopping` handles cart, saved items, and checkout. Totals use integer cents. Discounts are applied before 5% tax, and the $1 delivery fee is waived at $25.
- The outbox stores one pending purchase, retries it on reconnect or relaunch, and reuses its idempotency key. The mock market records the order and inventory together so a repeated request returns the original receipt.
- `assets/photos` contains optimized WebP artwork created with built-in ImageGen from two prompts, a 20-product grocery atlas on pastel studio backdrops and an overhead produce tote on forest green. All product images ship with the mobile app.
