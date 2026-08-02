part of com.demo.market.app_cross.ui.views.about;

/// F16 · About: app name, version and platform.
class AboutView extends StatelessWidget {
  const AboutView({super.key});

  static const String route = AppCrossRoutes.aboutPath;
  static const String name = AppCrossRoutes.aboutName;

  /// Kept in sync with the workspace package version.
  static const String appVersion = '0.1.0';

  @override
  Widget build(BuildContext context) => AppScaffold(
    key: AppCrossKeys.aboutView,
    title: 'app_cross.about.title'.tr(),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Center(
          child: Icon(
            AppIcons.catalog,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            'app_cross.about.app_name'.tr(),
            style: AppTypography.displayTitle,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            'app_cross.about.description'.tr(),
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
        ),
        AppSpacing.sectionGap,
        ListTile(
          leading: const Icon(AppIcons.about),
          title: Text('app_cross.about.version_label'.tr()),
          trailing: const Text(appVersion),
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          leading: const Icon(AppIcons.settings),
          title: Text('app_cross.about.platform_label'.tr()),
          trailing: Text(PlatformGuard.platformName),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    ),
  );
}
