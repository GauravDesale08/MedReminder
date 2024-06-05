import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'add_medicine_page.dart';
import 'profile_screen.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isConnected = true;
  int _medicinesLeft = 5;
  DateTime _selectedDate = DateTime.now();
  late StreamSubscription<InternetConnectionStatus> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
    _checkConnectivity();
    _connectivitySubscription = InternetConnectionChecker().onStatusChange.listen((InternetConnectionStatus status) {
      _updateConnectionStatus(status);
    });

    _firebaseMessaging.requestPermission();
    _firebaseMessaging.subscribeToTopic('medicine_reminders');
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await InternetConnectionChecker().hasConnection;
    setState(() {
      _isConnected = connectivityResult;
    });
  }

  void _updateConnectionStatus(InternetConnectionStatus status) {
    setState(() {
      _isConnected = status == InternetConnectionStatus.connected;
    });
    if (!_isConnected) {
      _showNoNetworkDialog();
    }
  }

  void _initializeFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground message received: ${message.notification?.title}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Background message opened: ${message.notification?.title}");
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.notification?.title}");
  }

  void _addMedicine() {
    if (_isConnected) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddMedicinePage()),
      ).then((newMedicine) {
        if (newMedicine != null) {
          // Code to handle the new medicine addition can go here
        }
      });
    } else {
      _showNoNetworkDialog();
    }
  }

  void _showNoNetworkDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Network'),
          content: Text('Please check your internet connection.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  Stream<QuerySnapshot> _getMedicinesForSelectedDate() {
    String selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    // Get the currently logged-in user
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return _firestore
          .collection('medicines')
          .where('userId', isEqualTo: user.uid) // Query medicines by user ID
          .where('scheduledDates', arrayContains: selectedDateStr)
          .snapshots();
    } else {
      // Return an empty stream if user is not logged in
      return Stream<QuerySnapshot>.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, MMM d').format(_selectedDate);

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 20),
                _buildDateSelector(formattedDate),
                SizedBox(height: 20),
                _buildMedicineList(),
              ],
            ),
          ),
          _buildProfileButton(),
        ],
      ),
      bottomNavigationBar: _buildBottomAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedicine,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    return Align(
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 30),
          Text(
            'Hi Harry!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            '$_medicinesLeft Medicines Left',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(String formattedDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.blue),
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(Duration(days: 1));
            });
          },
        ),
        Text(
          formattedDate,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: Colors.blue),
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.add(Duration(days: 1));
            });
          },
        ),
      ],
    );
  }

  Widget _buildMedicineList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _getMedicinesForSelectedDate(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyMedicineList();
          }

          // Group medicines by their dose times
          Map<String, List<DocumentSnapshot>> morningMedicines = {};
          Map<String, List<DocumentSnapshot>> afternoonMedicines = {};
          Map<String, List<DocumentSnapshot>> nightMedicines = {};

          for (var doc in snapshot.data!.docs) {
            var doseTimes = List<String>.from(doc['doses']);
            for (var time in doseTimes) {
              try {
                TimeOfDay doseTime = TimeOfDay(
                  hour: int.parse(time.split(':')[0]),
                  minute: int.parse(time.split(':')[1].split(' ')[0]),
                );

                if (doseTime.hour < 12) {
                  if (!morningMedicines.containsKey(time)) {
                    morningMedicines[time] = [];
                  }
                  morningMedicines[time]!.add(doc);
                } else if (doseTime.hour < 18) {
                  if (!afternoonMedicines.containsKey(time)) {
                    afternoonMedicines[time] = [];
                  }
                  afternoonMedicines[time]!.add(doc);
                } else {
                  if (!nightMedicines.containsKey(time)) {
                    nightMedicines[time] = [];
                  }
                  nightMedicines[time]!.add(doc);
                }
              } catch (e) {
                print("Error parsing time: $time");
              }
            }
          }

          return ListView(
            children: [
              if (morningMedicines.isNotEmpty)
                _buildMedicineGroup('Morning', morningMedicines),
              if (afternoonMedicines.isNotEmpty)
                _buildMedicineGroup('Afternoon', afternoonMedicines),
              if (nightMedicines.isNotEmpty)
                _buildMedicineGroup('Night', nightMedicines),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyMedicineList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 100,
            color: Colors.grey,
          ),
          Text(
            'Nothing Is Here, Add a Medicine',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _addMedicine,
            child: Text('Add Medicine'),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineGroup(String title, Map<String, List<DocumentSnapshot>> groupedMedicines) {
    List<Widget> buildMedicineList(Map<String, List<DocumentSnapshot>> groupedMedicines) {
      return groupedMedicines.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.key,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            ...entry.value.map((doc) {
              var medicine = doc.data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.medication, color: Colors.blue),
                  title: Text(medicine['name']),
                  subtitle: Text('${medicine['type']} - ${medicine['quantity']} - ${medicine['frequency']}'),
                  trailing: Text(medicine['status']),
                ),
              );
            }).toList(),
          ],
        );
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        ...buildMedicineList(groupedMedicines),
      ],
    );
  }

  Widget _buildProfileButton() {
    return Positioned(
      top: 20,
      right: 20,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue,
            child: Icon(
              Icons.person,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      notchMargin: 5.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.blue),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.insert_chart, color: Colors.blue),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
