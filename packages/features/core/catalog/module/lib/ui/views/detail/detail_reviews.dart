part of com.demo.market.catalog.ui.views.detail;

/// Reviews section of the detail (list + review CTA when allowed).
class _DetailReviews extends ConsumerWidget {
  const _DetailReviews();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DetailState state = ref.watch(detailViewModelProvider);
    final DetailViewModel viewModel = ref.read(
      detailViewModelProvider.notifier,
    );
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'catalog.detail.reviews_title'.tr(),
              style: AppTypography.sectionTitle,
            ),
            const Spacer(),
            if (state.canReview)
              TextButton(
                key: state.myReview == null
                    ? ProductDetailKeys.writeReviewButton
                    : ReviewFormKeys.editOwnReviewButton,
                onPressed: viewModel.goToReviewForm,
                child: Text(
                  state.myReview == null
                      ? 'catalog.detail.write_review_button'.tr()
                      : 'catalog.detail.edit_review_button'.tr(),
                ),
              ),
          ],
        ),
        if (state.reviews.isEmpty)
          Text(
            'catalog.detail.no_reviews'.tr(),
            style: AppTypography.body.copyWith(color: scheme.onSurfaceVariant),
          )
        else
          Column(
            key: ProductDetailKeys.reviewsList,
            children: <Widget>[
              for (final Review review in state.reviews)
                _ReviewTile(
                  key: ProductDetailKeys.reviewItem(review.id),
                  review: review,
                ),
            ],
          ),
      ],
    );
  }
}

/// One review row.
class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, super.key});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  review.userName,
                  style: AppTypography.cardTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              RatingStars(rating: review.rating.toDouble(), size: 14),
            ],
          ),
          if (review.comment != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(review.comment!, style: AppTypography.body),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            Formatters.formatDate(
              review.createdAt,
              locale: context.locale.toString(),
            ),
            style: AppTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
