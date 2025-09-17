import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Map<String, User> _users = {};
  String? _currentUserEmail;

  bool registerUser(String email, String password, String name) {
    if (_users.containsKey(email)) {
      return false;
    }

    _users[email] = User(email: email, password: password, name: name);
    return true;
  }

  bool loginUser(String email, String password) {
    if (_users.containsKey(email) && _users[email]!.password == password) {
      _currentUserEmail = email;
      return true;
    }
    return false;
  }

  void logout() {
    _currentUserEmail = null;
  }

  bool get isLoggedIn => _currentUserEmail != null;

  User? get currentUser {
    if (_currentUserEmail != null && _users.containsKey(_currentUserEmail)) {
      return _users[_currentUserEmail];
    }
    return null;
  }

  String? get currentUserName => currentUser?.name;
  String? get currentUserEmail => _currentUserEmail;
}
