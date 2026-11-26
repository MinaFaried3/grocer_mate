# GrocerMate take-home notes

## Easy-to-miss requirements

- **Offline mode.** Show an offline banner. Let users open cached categories, products and product details, and edit Cart and Saved. The offline story mentions queuing a purchase, but the bonus section and checklist label it optional. Checkout must still check prices and stock after reconnecting. (pp. 3, 10–11)
- **Cart totals.** The PDF gives the same order ID two totals. The purchase shows $7.86 for milk, an apple and bread. The order lookup leaves out the bread and shows $6.32 with tax and delivery. Calculate totals from the actual basket, count each discount once, and use the same calculation at checkout. (pp. 7–10)
- **Checkout changes.** Prices can go up or down, and stock can change in the same order. Show all changes in the review sheet. If someone wants two loaves and only one remains, let them reduce the quantity. If none remain, let them remove the item. Submit once they accept the changes, and make retries safe. (pp. 3, 7–8, 10)
- **Search and scrolling.** The sample search for `ap` includes Banana. Use the actual product names, category and brand to find matches. Wait briefly after typing, then start the results at page one. If loading the next page fails, keep the products already on screen and retry that page. (pp. 3–5, 10)
- **Deals and stock.** Sourdough has a discount even though its only badge is `fresh`. An orange can be discounted and sold out. Use prices to calculate savings, stock to show availability, and the price the shopper saw when adding the item as the starting point for checkout. (pp. 4–5, 7, 9)
- **Saved items.** Users can move one item or several between Cart and Saved in either direction. Try moving two items with different quantities, restarting the app and moving them back. Check both quantities and the total. (pp. 3, 10)

## Scope and hand-in

Use BLoC, data/domain/presentation layers and repository interfaces. Local JSON is enough. Price history, search suggestions and order lookup are example endpoints. The brief also requires system light/dark themes and distinct loading, empty and error states. (pp. 3, 7–10)

Submit the Git repo and a short README within three days of receiving the task. Register any JSON assets in `pubspec.yaml`. Keep the recording to **two minutes or less**. Show search, add to Cart, save for later, go offline, reconnect and resolve a checkout change. Show offline queuing if implemented. (pp. 10–11)

## Optional AI-agent tip

Ask the agent to trace one basket from Cart through a price change and a retry. Have it identify the PDF page and the code behind each issue, then reproduce the issue in the app before making a change.
