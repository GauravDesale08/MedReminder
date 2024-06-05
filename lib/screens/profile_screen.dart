import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicine_alert/screens/login_page.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Handle back button
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      'https://via.placeholder.com/150', // Replace with actual image URL
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Take Care!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Richa Bose',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.notifications),
                title: Text('Notification'),
                subtitle: Text('Check your medicine notification'),
              ),
              ListTile(
                leading: Icon(Icons.volume_up),
                title: Text('Sound'),
                subtitle: Text('Ring, Silent, Vibrate'),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Manage Your Account'),
                subtitle: Text('Password, Email ID, Phone Number'),
              ),
              ListTile(
                leading: Icon(Icons.notifications),
                title: Text('Notification'),
                subtitle: Text('Check your medicine notification'),
              ),
              ListTile(
                leading: Icon(Icons.notifications),
                title: Text('Notification'),
                subtitle: Text('Check your medicine notification'),
              ),
              SizedBox(height: 24),
              Text(
                'Device',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.bluetooth),
                      title: Text('Connect'),
                      subtitle: Text('Bluetooth, Wi-Fi'),
                    ),
                    ListTile(
                      leading: Icon(Icons.volume_up),
                      title: Text('Sound Option'),
                      subtitle: Text('Ring, Silent, Vibrate'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Caretakers: 03',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://via.placeholder.com/150', // Replace with actual image URL
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://via.placeholder.com/150', // Replace with actual image URL
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://via.placeholder.com/150', // Replace with actual image URL
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: Icon(Icons.add),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'Doctor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.add, color: Colors.white),
                ),
                title: Text('Add Your Doctor'),
                subtitle: Text.rich(
                  TextSpan(
                    text: 'Or use ',
                    children: [
                      TextSpan(
                        text: 'invite link',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              ListTile(
                title: Text('Privacy Policy'),
              ),
              ListTile(
                title: Text('Terms of Use'),
              ),
              ListTile(
                title: Text('Rate Us'),
              ),
              ListTile(
                title: Text('Share'),
              ),
              SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                            (route) => false,
                      );
                    } catch (e) {
                      print('Error signing out: $e');
                    }
                  },
                  child: Text('Log Out'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.grey[200],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
