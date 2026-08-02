part of com.demo.market.dashboard.ui.views.home;

/// Data state: summary cards, category and recent carousels, quick actions.
class _HomeData extends ConsumerWidget {
  const _HomeData();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeState state = ref.watch(homeViewModelProvider);
    final HomeViewModel viewModel = ref.read(homeViewModelProvider.notifier);
    final DashboardNavigator navigatorNotifier = ref.read(
      dashboardNavigator.notifier,
    );
    final DisplayCurrency currency = ref.watch(displayCurrencyProvider);
    final String locale = context.locale.toString();
    return RefreshIndicator(
      onRefresh: viewModel.load,
      child: ListView(
        key: DashboardKeys.state('data'),
        padding: AppSpacing.pagePadding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: <Widget>[
              _SummaryCard(
                cardKey: DashboardKeys.summaryCard('active_products'),
                icon: AppIcons.catalog,
                label: 'dashboard.home.summary_active_products'.tr(),
                value: '${state.summary.activePublications}',
              ),
              _SummaryCard(
                cardKey: DashboardKeys.summaryCard('cart_items'),
                icon: AppIcons.cart,
                label: 'dashboard.home.summary_cart_items'.tr(),
                value: '${state.summary.cartItemCount}',
              ),
              _SummaryCard(
                cardKey: DashboardKeys.summaryCard('cart_total'),
                icon: AppIcons.payment,
                label: 'dashboard.home.summary_cart_total'.tr(),
                value: Formatters.formatPrice(
                  currency.display(state.summary.cartSubtotal),
                  locale: locale,
                  currencyCode: currency.code,
                ),
              ),
              _SummaryCard(
                cardKey: DashboardKeys.summaryCard('month_orders'),
                icon: AppIcons.orders,
                label: 'dashboard.home.summary_month_orders'.tr(),
                value: '${state.summary.ordersThisMonth}',
              ),
            ],
          ),
          AppSpacing.sectionGap,
          Text(
            'dashboard.home.categories_title'.tr(),
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 96,
            child: ListView(
              key: DashboardKeys.categoryCarousel,
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                for (final Category category in state.categories)
                  _CategoryChip(
                    key: DashboardKeys.categoryItem(category.id),
                    category: category,
                    onTap: navigatorNotifier.goToCatalog,
                  ),
              ],
            ),
          ),
          AppSpacing.sectionGap,
          Text(
            'dashboard.home.recent_title'.tr(),
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 168,
            child: ListView(
              key: DashboardKeys.recentProductsCarousel,
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                for (final Product product in state.recentProducts)
                  _RecentProductCard(
                    key: DashboardKeys.recentItem(product.id),
                    product: product,
                    locale: locale,
                    currency: currency,
                    onTap: () =>
                        navigatorNotifier.goToProductDetail(product.id),
                  ),
              ],
            ),
          ),
          AppSpacing.sectionGap,
          Text(
            'dashboard.home.quick_actions_title'.tr(),
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              AppButton(
                key: DashboardKeys.goToCatalogButton,
                label: 'dashboard.home.go_to_catalog'.tr(),
                icon: AppIcons.catalog,
                variant: AppButtonVariant.secondary,
                onPressed: navigatorNotifier.goToCatalog,
              ),
              AppButton(
                key: DashboardKeys.goToCreateProductButton,
                label: 'dashboard.home.go_to_create_product'.tr(),
                icon: AppIcons.add,
                variant: AppButtonVariant.secondary,
                onPressed: navigatorNotifier.goToCreateProduct,
              ),
              AppButton(
                key: DashboardKeys.goToCartButton,
                label: 'dashboard.home.go_to_cart'.tr(),
                icon: AppIcons.cart,
                variant: AppButtonVariant.secondary,
                onPressed: navigatorNotifier.goToCart,
              ),
              AppButton(
                key: DashboardKeys.goToFavoritesButton,
                label: 'dashboard.home.go_to_favorites'.tr(),
                icon: AppIcons.favoriteOutline,
                variant: AppButtonVariant.secondary,
                onPressed: navigatorNotifier.goToFavorites,
              ),
              AppButton(
                key: DashboardKeys.goToMyProductsButton,
                label: 'dashboard.home.go_to_my_products'.tr(),
                icon: AppIcons.edit,
                variant: AppButtonVariant.secondary,
                onPressed: navigatorNotifier.goToMyProducts,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One metric card of the summary row.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.cardKey,
    required this.icon,
    required this.label,
    required this.value,
  });

  final Key cardKey;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 168,
      child: AppCard(
        key: cardKey,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: scheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: AppTypography.sectionTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One category bubble of the carousel.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.onTap, super.key});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              radius: 28,
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                AppIcons.forCategoryCode(category.code),
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(category.labelKey.tr(), style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

/// One recent product card of the carousel.
class _RecentProductCard extends StatelessWidget {
  const _RecentProductCard({
    required this.product,
    required this.locale,
    required this.currency,
    required this.onTap,
    super.key,
  });

  final Product product;
  final String locale;
  final DisplayCurrency currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: SizedBox(
        width: 168,
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                AppIcons.forCategoryCode(product.categoryCode),
                size: 40,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                product.name,
                style: AppTypography.cardTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                Formatters.formatPrice(
                  currency.display(product.price),
                  locale: locale,
                  currencyCode: currency.code,
                ),
                style: AppTypography.caption.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
