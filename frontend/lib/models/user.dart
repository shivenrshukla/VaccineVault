class User {
  final String email;
  final String name;
  final String password;

  User({required this.email, required this.name, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'name': name, 'password': password};
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'],
      name: json['name'],
      password: json['password'],
    );
  }
}
