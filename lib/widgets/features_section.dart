import 'package:flutter/material.dart';
import '/screens/know_me_screen.dart';  // Import KnowMeScreen
import '/screens/weather_screen.dart';  // Import WeatherScreen instead of TripPlannerScreen
import 'feature_button.dart';  // Import the updated FeatureButton

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Explore Our Latest Features',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        SizedBox(height: 8),
        const FeatureButton(
          title: 'Tutankhamun',
          icon: Icons.account_balance,
        ),
        Container(
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              title: Text(
                'Nefertiti', // Use Nefertiti as the feature name
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Learn about the Great Queen of Egypt'),
              leading: Icon(Icons.account_balance, color: Colors.orange),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.orange),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => KnowMeScreen()),
                );
              },
            ),
          ),
        ),
        // Trip Planner Feature
        Container(
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              title: Text(
                'Trip Planner',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Create personalized ancient Egypt itineraries'),
              leading: Icon(Icons.map, color: Colors.orange),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.orange),
              onTap: () {
                Navigator.pushNamed(context, '/get_temp');
              },
            ),
          ),
        ),
      ],
    );
  }
}
