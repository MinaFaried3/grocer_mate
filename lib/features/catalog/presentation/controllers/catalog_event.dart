sealed class CatalogEvent {
  const CatalogEvent();
}

class SearchTyped extends CatalogEvent {
  const SearchTyped(this.input);
  final String input;
}

class CategorySelected extends CatalogEvent {
  const CategorySelected(this.id);
  final String? id;
}

class BrandSelected extends CatalogEvent {
  const BrandSelected(this.name);
  final String? name;
}

class DealsSelected extends CatalogEvent {
  const DealsSelected();
}

class CatalogRefreshed extends CatalogEvent {
  const CatalogRefreshed();
}

class NextPageRequested extends CatalogEvent {
  const NextPageRequested();
}

class SearchSettled extends CatalogEvent {
  const SearchSettled(this.input);
  final String input;
}
