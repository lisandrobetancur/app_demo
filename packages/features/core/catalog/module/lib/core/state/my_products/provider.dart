part of com.demo.market.catalog.core.state.my_products;

/// Riverpod handle for [MyProductsViewModel].
final NotifierProvider<MyProductsViewModel, MyProductsState>
myProductsViewModelProvider =
    NotifierProvider<MyProductsViewModel, MyProductsState>(
      MyProductsViewModel.new,
    );
