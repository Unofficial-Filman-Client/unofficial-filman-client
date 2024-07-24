String createTimeBasedGreeting(final String name) {
  final now = DateTime.now();
  final hour = now.hour;

  if (hour >= 5 && hour < 12) {
    return "Miłego dnia, $name";
  } else if (hour >= 12 && hour < 18) {
    return "Miłego popołudnia, $name";
  } else if (hour >= 18 && hour < 22) {
    return "Dobry wieczór, $name";
  } else {
    return "$name 😴";
  }
}
