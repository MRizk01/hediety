class Gift {
  String? id;
  String name;
  String description;
  String category;
  double price;
  String status;
  String? eventId; // New field to associate the gift with an event
  String? userId; // New field to associate the gift with a user

  Gift({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.status,
    this.eventId,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'status': status,
      'eventId': eventId,
      'userId': userId,
    };
  }

  factory Gift.fromFirestore(Map<String, dynamic> data, String id) {
    return Gift(
      id: id,
      name: data['name'] ?? 'Unknown',
      description: data['description'] ?? 'Unknown',
      category: data['category'] ?? 'Unknown',
      price: data['price']?.toDouble() ?? 0.0,
      status: data['status'] ?? 'available',
      eventId: data['eventId'],
      userId: data['userId'],
    );
  }

  static Gift fromSQLite(Map<String, dynamic> map) {
    return Gift(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      price: map['price'],
      status: map['status'],
      eventId: map['event_id'],
      userId: map['user_id'],
    );
  }
}