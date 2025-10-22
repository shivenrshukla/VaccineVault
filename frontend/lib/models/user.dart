class User {
  // All fields from your Node.js model
  final String username;
  final String password;
  final String email;
  final String dateOfBirth; // Use String in 'YYYY-MM-DD' format
  final String gender;
  final String addressPart1;
  final String? addressPart2; // Nullable
  final String city;
  final String state;
  final String pinCode;
  final String phoneNumber;

  User({
    required this.username,
    required this.password,
    required this.email,
    required this.dateOfBirth,
    required this.gender,
    required this.addressPart1,
    this.addressPart2,
    required this.city,
    required this.state,
    required this.pinCode,
    required this.phoneNumber,
  });

  // This method prepares the data to be sent for registration
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'email': email,
      'dateOfBirth': dateOfBirth,
      "gender": gender,
      'addressPart1': addressPart1,
      'addressPart2': addressPart2,
      'city': city,
      'state': state,
      'pinCode': pinCode,
      'phoneNumber': phoneNumber,
    };
  }
}
