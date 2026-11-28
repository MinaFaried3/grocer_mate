# GrocerMate

A Flutter grocery storefront with a local market. Browse and filter groceries, manage a cart and saved items, and review stock or price changes at checkout.

## Run

Use Flutter 3.50 or later with Dart 3.14 or later. By default, the app runs against the bundled JSON demo API.

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

For Chrome, run `flutter run -d chrome --no-web-resources-cdn`. Web storage requires HTTPS or localhost. Android, iOS, and web project files are included. The app follows the system light or dark theme.

## Try the offline checkout

The [25-second walkthrough](walkthrough/grocermate_walkthrough.mp4) shows search, the saved list, an offline purchase, and checkout review after reconnecting.

1. Browse the catalog online once. Search for **milk**, add **Milk 2%**, then clear the search and add **Sourdough Bread**.
2. In **Cart**, move an item to **Saved**, then open **Saved** and move it back. **Select items** enables bulk moves in both lists.
3. From the cart, open **Settings**, choose **Price and stock changes**, turn on **Offline mode**, and tap **Done**.
4. Tap **Queue purchase**. The app keeps the queued order and any new cart edits separate.
5. Turn off **Offline mode**. The app rechecks the queued order and opens a review sheet. Accept new prices, reduce quantities, or remove items before resubmitting.

The selected checkout update applies to the next purchase and saves the changes to the local catalog. The scenarios prefer the products in the checkout examples and fall back to positions in your cart. **Partial fulfillment** places an order for available quantities and returns the remaining quantities to your cart. **Offline mode** works independently of the device’s connection. A fresh web load still needs the static app files from its host.

## Run against an HTTP backend

To test the app over HTTP, start the local demo server from the repository root, then launch Flutter in a second terminal.

```sh
dart run tool/mock_api_server.dart 8080
flutter run -d chrome --no-web-resources-cdn --dart-define=GROCER_API_BASE_URL=http://127.0.0.1:8080
```

On an Android emulator, use `http://10.0.2.2:8080`. Use an HTTPS base URL for a deployed backend, including any path prefix such as `/v1`. For Flutter web, the backend must allow the app's origin and the `Content-Type` and `Idempotency-Key` headers.

The HTTP demo server resets inventory and orders on restart. Set `MOCK_CHECKOUT_SCENARIO` to `prices`, `stock`, `mixed` or `partial` when starting it to simulate that response on its next purchase. The bundled demo persists inventory and orders on the device and lets you select the scenario in Settings. Each backend URL has its own catalog, cart and outbox storage.

## Endpoint data

Each endpoint has a JSON fixture in `assets/mock_api/`. Edit `products.json` to change the searchable catalog, `product.json` for details, `brands.json` for brand choices, and `purchase.json` for checkout scenarios. The demo calculates product counts, totals and stock changes from the request and the dataset. It keeps the supplied example receipt at `/orders/o_7101`, and generates new receipts for completed purchases.

- Catalog reads use `GET /categories`, `/brands?categoryId=...`, `/products?category=...&page=...&pageSize=...&search=...&brand=...`, `/product/{id}` and `/deals-of-day`.
- Checkout uses `GET /flags` for the request currency and `POST /purchase` with integer quantities, decimal API prices and an `Idempotency-Key` header. Retries use the same key. Accepting a revised order generates a new key.
- The data layer also exposes `GET /price-history/{id}`, `/inventory/{id}`, `/suggest?q=...`, `/stock-check?ids=...`, `/orders/{id}`, and `POST /sync`. The app's outbox replays through `/purchase` so it can handle the receipt and review payloads. The supplied `/sync` response acknowledges a version and is available for standalone batch demos.

## Implementation

- `lib/core/injection` configures the shared HTTP interface with the demo or live client. The feature repositories and BLoCs use the same request and response formats in both modes.
- The catalog fetches pages and filters from the API. Offline browsing and details use downloaded products. Cart and Saved continue to use durable local storage.
- The checkout preview calculates prices in integer cents with the sample 5% tax and $1 delivery fee waived at $25. Completed receipts use the total returned by the server.
- The bundled demo uses product photography from `assets/photos` where available. The HTTP client also supports image URLs returned by a live backend.
