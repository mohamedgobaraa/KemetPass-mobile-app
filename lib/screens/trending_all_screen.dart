import 'package:flutter/material.dart';
import '../widgets/trending_card.dart';

class TrendingAllScreen extends StatelessWidget {
  final List<Map<String, dynamic>> places;

  const TrendingAllScreen({Key? key, required this.places}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Trending Places'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two cards per row
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 0.75, // Adjust aspect ratio as needed
        ),
        itemCount: places.length,
        itemBuilder: (context, index) {
          final place = places[index];
          return TrendingCard(
            title: place['title'],
            location: place['location'],
            rating: place['rating'],
            imageUrl: place['imageUrl'],
          );
        },
      ),
    );
  }
} 