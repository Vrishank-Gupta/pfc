import 'package:flutter/material.dart';

class AddEventScreen extends StatefulWidget {
  final Function onEventAdded;

  const AddEventScreen({Key? key, required this.onEventAdded}) : super(key: key);

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final TextEditingController spotNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: spotNameController,
              decoration: InputDecoration(labelText: 'Spot Name'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Get the entered spot name
                final spotName = spotNameController.text.trim();
                if (spotName.isNotEmpty) {
                  // Call the callback function to add the event
                  widget.onEventAdded(spotName);
                  // Navigate back to the main screen
                  Navigator.pop(context);
                }
              },
              child: Text('Add Event'),
            ),
          ],
        ),
      ),
    );
  }
}
