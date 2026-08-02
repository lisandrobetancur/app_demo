part of com.demo.market.app_cross.ui.views.settings;

/// One selectable option inside a [_SettingsChoiceSection].
class _ChoiceOption {
  const _ChoiceOption({
    required this.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final Key key;
  final String label;
  final bool selected;
  final VoidCallback onSelected;
}

/// A titled group of choice chips (language, theme, currency).
class _SettingsChoiceSection extends StatelessWidget {
  const _SettingsChoiceSection({
    required this.sectionKey,
    required this.label,
    required this.options,
  });

  final Key sectionKey;
  final String label;
  final List<_ChoiceOption> options;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
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
                label: Text(option.label),
                selected: option.selected,
                onSelected: (bool _) => option.onSelected(),
              ),
          ],
        ),
      ],
    ),
  );
}
