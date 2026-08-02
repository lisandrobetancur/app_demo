part of com.demo.market.catalog.ui.views.review_form;

/// Stars + comment form.
class _ReviewFormBody extends ConsumerStatefulWidget {
  const _ReviewFormBody();

  @override
  ConsumerState<_ReviewFormBody> createState() => _ReviewFormBodyState();
}

class _ReviewFormBodyState extends ConsumerState<_ReviewFormBody> {
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(
      text: ref.read(reviewFormViewModelProvider).comment,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ReviewFormState state = ref.watch(reviewFormViewModelProvider);
    final ReviewFormViewModel viewModel = ref.read(
      reviewFormViewModelProvider.notifier,
    );
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(state.productName, style: AppTypography.sectionTitle),
          AppSpacing.sectionGap,
          Text(
            'catalog.review_form.rating_label'.tr(),
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: RatingStars(
              rating: state.rating.toDouble(),
              size: 40,
              starKeys: ReviewFormKeys.ratingStars,
              onRatingSelected: viewModel.setRating,
            ),
          ),
          AppSpacing.sectionGap,
          AppTextField(
            key: ReviewFormKeys.commentInput,
            label: 'catalog.review_form.comment_label'.tr(),
            controller: _commentController,
            maxLength: CatalogLimits.reviewCommentMaxLength,
            maxLines: 4,
            onChanged: viewModel.setComment,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (state.errorKey != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                state.errorKey!.tr(),
                style: AppTypography.body.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          AppButton(
            key: ReviewFormKeys.submitButton,
            label: 'catalog.review_form.submit_button'.tr(),
            isLoading: state.isSubmitting,
            onPressed: state.canSubmit ? viewModel.submit : null,
            expand: true,
          ),
        ],
      ),
    );
  }
}
