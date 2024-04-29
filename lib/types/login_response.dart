class LoginResponse {
  final bool success;
  List<String> errors = [];

  void addError(String error) {
    errors.add(error);
  }

  LoginResponse({
    required this.success,
  });
}
