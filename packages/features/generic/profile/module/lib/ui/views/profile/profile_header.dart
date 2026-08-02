part of com.demo.market.profile.ui.views.profile;

/// Avatar + name + email header.
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProfileState state = ref.watch(profileViewModelProvider);
    final AuthUser? user = ref.watch(authSessionProvider);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Uint8List? avatar = state.pendingAvatarBytes ?? state.avatarBytes;
    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 36,
          backgroundColor: scheme.primaryContainer,
          backgroundImage: avatar == null ? null : MemoryImage(avatar),
          child: avatar == null
              ? Icon(
                  AppIcons.profile,
                  size: 36,
                  color: scheme.onPrimaryContainer,
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                user?.fullName ?? '',
                style: AppTypography.sectionTitle,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                user?.email ?? '',
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (user?.phone != null)
                Text(
                  user!.phone!,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
