class Event {
  String? id;
  String name;
  String date;
  String location;
  String description;

  Event({
    this.id,
    required this.name,
    required this.date,
    required this.location,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'location': location,
      'description': description,
    };
  }

  static Event fromSQLite(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      name: map['name'],
      date: map['date'],
      location: map['location'],
      description: map['description'],
    );
  }

  static Event fromFirestore(Map<String, dynamic> map, String id) {
    return Event(
      id: id,
      name: map['name'],
      date: map['date'],
      location: map['location'],
      description: map['description'],
    );
  }
}