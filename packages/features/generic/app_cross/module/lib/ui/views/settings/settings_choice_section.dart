part of com.demo.market.app_cross.ui.views.settings;

/// One selectable option inside a [_SettingsChoiceSection].
class _ChoiceOption {
  const _ChoiceOption({
    required this.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.semanticsId,
  });

  final Key key;
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final String semanticsId;
}

/// A titled group of choice chips (language, theme, currency).
class _SettingsChoiceSection extends StatelessWidget {
  const _SettingsChoiceSection({
    required this.sectionKey,
    required this.label,
    required this.options,
    required this.semanticsId,
  });

  final Key sectionKey;
  final String label;
  final List<_ChoiceOption> options;
  final String semanticsId;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: SemanticRegion(
      identifier: semanticsId,
      child: Column(
        key: sectionKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: <Widget>[
              for (final _ChoiceOption option in options)
                ChoiceChip(
                  key: option.key,
                  // On the label, which joins the chip's own node — the one
                  // with the selected state and the tap.
                  label: Semantics(
                    identifier: option.semanticsId,
                    child: Text(option.label),
                  ),
                  selected: option.selected,
                  onSelected: (bool _) => option.onSelected(),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
