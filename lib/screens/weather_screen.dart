import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const Color backgroundColor = Color(0xFFFEFFD2);
const Color secondaryColor = Color(0xFFFFEEA9);
const Color primaryColor = Color(0xFFFFBF78);
const Color accentColor = Color(0xFFFF7D29);

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _preferencesController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  double _luxuryLevel = 1.0; // 0=shoestring, 1=comfort, 2=luxury
  bool _isLoading = false;
  Map<String, dynamic>? _tripPlan;

  String getBudgetType() {
    if (_luxuryLevel < 0.5) return 'shoestring';
    if (_luxuryLevel < 1.5) return 'comfort';
    return 'luxury';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitPlanRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _tripPlan = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/plan_travel'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': _preferencesController.text,
          'start': _startDateController.text,
          'days': int.parse(_daysController.text),
          'budget': getBudgetType(),
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          if (responseData.containsKey('error')) {
            // API returned an error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${responseData['error']}')),
            );
          } else {
        setState(() {
              _tripPlan = responseData;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Trip plan generated successfully!')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error parsing response: ${e.toString()}')),
          );
        }
      } else {
        // Handle different status codes
        String errorMessage = 'Failed to generate trip plan (Status ${response.statusCode})';
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          if (errorData.containsKey('error')) {
            errorMessage = errorData['error'];
          }
        } catch (_) {
          // If we can't parse the error, just use the default message
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Trip Planner'),
        backgroundColor: accentColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                          'Plan Your Perfect Trip',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        SizedBox(height: 20),
                        
                        // Travel Preferences
                        Text(
                          'Where would you like to go? What interests you?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _preferencesController,
                          decoration: InputDecoration(
                            hintText: 'e.g., pyramids, temples, ancient ruins, local food',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your travel preferences';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        
                        // Start Date
                        Text(
                          'Trip Start Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _startDateController,
                          decoration: InputDecoration(
                            hintText: 'YYYY-MM-DD',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: Icon(Icons.calendar_today),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a start date';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        
                        // Number of Days
            Text(
                          'Number of Days',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _daysController,
                          decoration: InputDecoration(
                            hintText: 'e.g., 3',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter number of days';
                            }
                            if (int.tryParse(value) == null || int.parse(value) < 1) {
                              return 'Please enter a valid number of days';
                            }
                            return null;
                          },
            ),
            SizedBox(height: 20),
                        
                        // Budget Level Slider
                        Text(
                          'Budget Level: ${getBudgetType()}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Slider(
                          value: _luxuryLevel,
                          min: 0,
                          max: 2,
                          divisions: 2,
                          activeColor: accentColor,
                          inactiveColor: secondaryColor,
                          label: getBudgetType(),
                          onChanged: (value) {
                            setState(() {
                              _luxuryLevel = value;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Shoestring'),
                            Text('Comfort'),
                            Text('Luxury'),
                          ],
                        ),
                        SizedBox(height: 30),
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitPlanRequest,
                            child: _isLoading 
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                'Generate Trip Plan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Display Trip Plan if available
              if (_tripPlan != null) ...[
                SizedBox(height: 24),
                Text(
                  'Your Trip Plan',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'City: ${_tripPlan!['city']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        ..._tripPlan!['plan'].map<Widget>((day) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(),
                              Text(
                                'Day ${day['day']} - ${day['date']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                              SizedBox(height: 8),
                              ...day['entries'].map<Widget>((entry) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${entry['time']} - ${entry['place_name']}',
                                        style: TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      Text(entry['activity']),
                                      if (entry['notes'] != null) 
                                        Text(
                                          entry['notes'],
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      SizedBox(height: 4),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _preferencesController.dispose();
    _startDateController.dispose();
    _daysController.dispose();
    super.dispose();
  }
}
