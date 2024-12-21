class Friend {
  String? id;
  String name;
  String phoneNumber;
  // String? profilePictureUrl; // For later use

  Friend({this.id, required this.name, required this.phoneNumber,});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }

  static Friend fromSQLite(Map<String, dynamic> map) {
    return Friend(
      id: map['id'],
      name: map['name'] ?? 'Unknown', 
      phoneNumber: map['phoneNumber'] ?? 'Unknown', 
    );
  }


  static Friend fromFirestore(Map<String, dynamic> map, String id) {
    return Friend(
      id: id,
      name: map['name'] ?? 'Unknown', 
      phoneNumber: map['phoneNumber'] ?? 'Unknown', 
    );
  }
}