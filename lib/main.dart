import 'package:flutter/material.dart';

void main() {
  runApp(const HedieatyApp());
}

class HedieatyApp extends StatelessWidget {
  const HedieatyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hedieaty',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final List<String> friends = const ['Alice', 'Bob', 'Charlie']; // Static data

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hedieaty')),
      body: ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(friends[index]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const GiftListPage()),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create event/list page (not implemented yet)
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class GiftListPage extends StatelessWidget {
  const GiftListPage({super.key});

  final List<String> gifts = const ['Gift 1', 'Gift 2', 'Gift 3']; // Static data

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gift List')),
      body: ListView.builder(
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(gifts[index]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GiftDetailsPage()),
              );
            },
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              // Add Gift functionality (not implemented yet)
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () {
              // Delete Gift functionality (not implemented yet)
            },
            child: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }
}

class GiftDetailsPage extends StatelessWidget {
  const GiftDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gift Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(decoration: const InputDecoration(labelText: 'Name')),
            TextFormField(
                decoration: const InputDecoration(labelText: 'Description')),
            TextFormField(
                decoration: const InputDecoration(labelText: 'Category')),
            TextFormField(
                decoration: const InputDecoration(labelText: 'Price')),
            // Add image upload option later
          ],
        ),
      ),
    );
  }
}