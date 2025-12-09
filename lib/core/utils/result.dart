/// İşlem sonucunu temsil eden sınıf
/// Success veya Error döndürür
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  /// Başarılı sonuç
  factory Result.success(T data) {
    return Result._(
      data: data,
      isSuccess: true,
    );
  }

  /// Hatalı sonuç
  factory Result.error(String error) {
    return Result._(
      error: error,
      isSuccess: false,
    );
  }

  /// Başarılı mı?
  bool get isError => !isSuccess;

  /// Veriyi getir veya exception fırlat
  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data!;
    }
    throw Exception(error ?? 'Unknown error');
  }

  /// Veriyi getir veya null döndür
  T? get dataOrNull => data;

  /// When metodları (Kotlin benzeri)
  R when<R>({
    required R Function(T data) success,
    required R Function(String error) error,
  }) {
    if (isSuccess && data != null) {
      return success(data!);
    } else {
      return error(this.error ?? 'Unknown error');
    }
  }

  /// Map metodu
  Result<R> map<R>(R Function(T data) transform) {
    if (isSuccess && data != null) {
      try {
        return Result.success(transform(data!));
      } catch (e) {
        return Result.error(e.toString());
      }
    } else {
      return Result.error(error ?? 'Unknown error');
    }
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'Result.success($data)';
    } else {
      return 'Result.error($error)';
    }
  }
}
