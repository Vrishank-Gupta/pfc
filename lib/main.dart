import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() => runApp(const MaterialApp(
  home: Home(),
));

const String name = "Hello";

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Future<List<FeedEvents>>? eventsFuture;
  void _refreshData() {
    setState(() {
      eventsFuture = fetchEvents();
    });
  }

  @override
  void initState() {
    super.initState();
    eventsFuture = fetchEvents();
  }

  static Future<List<FeedEvents>> fetchEvents() async {
    var url =
    Uri.parse("https://paws-for-cause.mangohill-61f2fe59.northeurope.azurecontainerapps.io/isb/feed/all");
    final response = await http.get(url, headers: {"Content-Type": "application/json"});
    final List body = json.decode(response.body);

    return body.map((e) => FeedEvents.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar:AppBar(
        title: const Text('Paws For Cause'),
        centerTitle: true,
        backgroundColor: Colors.grey[850],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _refreshData();
            },
          ),
        ],
      ),

      body: Container(
        padding: EdgeInsets.all(5),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              const Text(
                "A full bowl, a wagging tail – that's where happiness begins.",
                style: TextStyle(color: Colors.red, fontSize: 19),
              ),
              Image.network(
                  "https://images.unsplash.com/photo-1611003228941-98852ba62227?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1974&q=80"),
              Expanded(
                child: FutureBuilder<List<FeedEvents>>(
                  future: eventsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasData) {
                      final events = snapshot.data!;
                      return buildPosts(filterLatestEvents(events), _refreshData);
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else {
                      return const Text("No Data Available");
                    }
                  },
                ),

              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Adding new pot");
        },
        backgroundColor: Colors.red,
        child: const Text(
          "+",
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}

List<FeedEvents> filterLatestEvents(List<FeedEvents> events) {
  // Create a map to store the latest events for each spotName
  Map<String, FeedEvents> latestEventsMap = {};

  // Create a DateFormat instance for UTC time format
  final dateFormat = DateFormat("dd-MM-yyyy HH:mm:ss");

  // Iterate through the list of events
  for (var event in events) {
    if (event.spot != null && event.timeOfDay != null) {
      // Parse the timeOfDay string to DateTime in UTC
      DateTime utcDateTime = dateFormat.parse(event.timeOfDay!);

      // Convert UTC DateTime to IST (Indian Standard Time)
      final istDateTime = utcDateTime.toLocal().add(DateTime.now().timeZoneOffset);

      // Check if we have a previous event for the same spotName
      if (latestEventsMap.containsKey(event.spot!)) {
        // Compare the timeOfDay of the current event with the stored event
        var storedEvent = latestEventsMap[event.spot!];
        if (storedEvent != null &&
            istDateTime.isAfter(dateFormat.parse(storedEvent.timeOfDay!))) {
          // If the current event is newer, replace the stored event
          latestEventsMap[event.spot!] = event;
        }
      } else {
        // If no event is stored for this spotName, add it to the map
        latestEventsMap[event.spot!] = event;
      }
    }
  }

  // Convert the map values to a list and return it
  List<FeedEvents> filteredEvents = latestEventsMap.values.toList();
  return filteredEvents;
}

Widget buildPosts(List<FeedEvents> events, Function refreshCallback) {
  int length = events.length;
  // ListView Builder to show data in a list
  return ListView.builder(
    itemCount: events.length,
    itemBuilder: (context, index) {
      final event = events[index];
      return Container(
        color: Colors.grey.shade300,
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        height: 100,
        width: double.maxFinite,
        child: Column(
          children: [
            SizedBox(width: 10),
            Expanded(flex: 3, child: Text("Location: " + event.spot!.toUpperCase())),
            SizedBox(width: 10),
            Expanded(flex: 3, child: Text("Last fed: ${event.timeOfDay}")),
            TextButton(
              child: const Text('FEED NOW'),
              onPressed: () {
                showFeedConfirmationDialog(context, event.spot!, refreshCallback);
              },
            ),
          ],
        ),
      );
    },
  );
}


Future<void> showFeedConfirmationDialog(
    BuildContext context, String spotName, Function refreshCallback) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Feed the dogs at $spotName?'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Yes'),
            onPressed: () async {
              final success = await makeFeedApiCall(spotName);
              if (success) {
                Fluttertoast.showToast(
                  msg: 'Feeding completed successfully',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
                Navigator.of(context).pop(); // Close the dialog
                refreshCallback(); // Refresh the list view
              } else {
                Fluttertoast.showToast(
                  msg: 'Failed to complete feeding',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
              }
            },
          ),
        ],
      );
    },
  );
}



Future<bool> makeFeedApiCall(String spotName) async {
  final url = Uri.parse("https://paws-for-cause.mangohill-61f2fe59.northeurope.azurecontainerapps.io/isb/feed");
  final body = spotName; // Assuming your API expects a JSON body with the spot name
  final response = await http.post(url, body: body, headers: {"Content-Type": "application/json"});

  if (response.statusCode == 200) {
    return true; // Success
  } else {
    return false; // Failure
  }
}

class FeedEvents {
  String? timeOfDay;
  bool? fed;
  String? spot;

  FeedEvents({this.spot, this.fed, this.timeOfDay});

  factory FeedEvents.fromJson(Map<String, dynamic> json1) => FeedEvents(
    timeOfDay: json1['timeOfDay'],
    spot: json1['feedingSpot'],
    fed: json1['fed'],
  );

  Map<String, dynamic> toJson() => {
    "timeOfDay": timeOfDay,
    "fed": fed,
    "spot": spot,
  };
}
