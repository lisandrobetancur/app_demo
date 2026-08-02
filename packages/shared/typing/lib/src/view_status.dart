/// Cross-cutting status for every data-backed view in the app.
///
/// Each view renders exactly one of the four canonical states
/// (loading / data / empty / error), each in its own `part` file.
enum ViewStatus {
  loading,
  data,
  empty,
  error;

  bool get isLoading => this == ViewStatus.loading;

  bool get isData => this == ViewStatus.data;

  bool get isEmpty => this == ViewStatus.empty;

  bool get isError => this == ViewStatus.error;
}
