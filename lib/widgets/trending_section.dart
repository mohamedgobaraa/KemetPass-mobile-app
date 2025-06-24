import 'package:flutter/material.dart';
import 'trending_card.dart';
import '../screens/trending_all_screen.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

const Color backgroundColor = Color(0xFFFEFFD2);
const Color secondaryColor = Color(0xFFFFEEA9);
const Color primaryColor = Color(0xFFFFBF78);
const Color accentColor = Color(0xFFFF7D29);
const Color inactiveIconColor = Colors.grey;

class TrendingSection extends StatefulWidget {
  @override
  _TrendingSectionState createState() => _TrendingSectionState();
}

class _TrendingSectionState extends State<TrendingSection> {
  List<Map<String, dynamic>> trendingPlaces = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistoricalPlaces();
  }

  Future<void> _loadHistoricalPlaces() async {
    try {
      final String response = await rootBundle.loadString('lib/python-backend copy/historical_places.json');
      final List<dynamic> data = json.decode(response);
      
      // Convert the data to the format needed for trending cards
      final List<Map<String, dynamic>> places = data.map((place) {
        return {
          'title': place['Name'],
          'location': '${place['Location']}, Egypt',
          'rating': 4.5, // Default rating since it's not in the data
          'imageUrl': 'assets/images/${place['Name'].replaceAll(' ', '_')}.jpeg',
        };
      }).toList();

      setState(() {
        trendingPlaces = places;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading historical places: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the first 6 items for home screen
    final homeScreenItems = trendingPlaces.take(6).toList();
    // Get the remaining items for the all trending screen
    final remainingItems = trendingPlaces.length > 6 
        ? trendingPlaces.sublist(6) 
        : <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trending Now',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TrendingAllScreen(places: remainingItems)),
                  );
                },
                child: Text('See all'),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        if (isLoading)
          Center(child: CircularProgressIndicator())
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: homeScreenItems.map((place) => TrendingCard(
                title: place['title'],
                location: place['location'],
                rating: place['rating'],
                imageUrl: place['imageUrl'],
              )).toList(),
            ),
          ),
      ],
    );
  }
}
