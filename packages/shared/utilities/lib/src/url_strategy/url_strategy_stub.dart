/// Mobile/desktop implementation: URL strategies are a web-only concern, so
/// this is a no-op. Deep links arrive through the `market://` scheme instead
/// (see the AndroidManifest intent-filter and the iOS CFBundleURLTypes).
void configureUrlStrategy() {}
