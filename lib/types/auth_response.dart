class AuthResponse {
  final bool success;
  List<String> errors = [];

  void addError(final String error) {
    errors.add(error);
  }

  AuthResponse({
    required this.success,
  });
}
