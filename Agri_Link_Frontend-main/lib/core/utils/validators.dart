class AppValidators {
  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    if (!re.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Minimum 8 characters';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'Must contain an uppercase letter';
    if (!v.contains(RegExp(r'[a-z]'))) return 'Must contain a lowercase letter';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Must contain a digit';
    return null;
  }

  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required';
    if (v.trim().length < 2) return 'Too short';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.isEmpty) return null; // optional
    final re = RegExp(r'^\+?[\d\s\-]{7,20}$');
    if (!re.hasMatch(v)) return 'Enter a valid phone number';
    return null;
  }

  static String? required(String? v, [String field = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? positiveNumber(String? v, [String field = 'Value']) {
    if (v == null || v.isEmpty) return '$field is required';
    final n = double.tryParse(v);
    if (n == null) return 'Must be a valid number';
    if (n <= 0) return 'Must be greater than 0';
    return null;
  }

  static String? positiveInt(String? v, [String field = 'Value']) {
    if (v == null || v.isEmpty) return '$field is required';
    final n = int.tryParse(v);
    if (n == null) return 'Must be a whole number';
    if (n < 0) return 'Must be 0 or more';
    return null;
  }
}
