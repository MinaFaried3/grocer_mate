sealed class const CatalogEvent();

class const SearchTyped(final String input) extends CatalogEvent;

class const CategorySelected(final String? id) extends CatalogEvent;

class const BrandSelected(final String? name) extends CatalogEvent;

class const DealsSelected() extends CatalogEvent;

class const CatalogRefreshed() extends CatalogEvent;

class const NextPageRequested() extends CatalogEvent;

class const SearchSettled(final String input) extends CatalogEvent;
