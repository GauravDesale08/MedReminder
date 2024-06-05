import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddMedicinePage extends StatefulWidget {
  @override
  _AddMedicinePageState createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _medicineNameController = TextEditingController();
  int _compartment = 1;
  Color _color = Colors.pink;
  String _type = 'Tablet';
  String _quantity = 'Take 1/2 Pill';
  int _totalCount = 1;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 7));
  String _frequency = 'Everyday';
  String _timesADay = 'Three Times';
  List<String> _doses = ['Dose 1', 'Dose 2', 'Dose 3'];
  List<TimeOfDay> _doseTimes = [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 12, minute: 0), TimeOfDay(hour: 18, minute: 0)];
  String _foodIntake = 'Before Food';

  void _pickStartDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  void _pickEndDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  void _pickTime(int index) async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _doseTimes[index],
    );
    if (time != null) {
      setState(() {
        _doseTimes[index] = time;
      });
    }
  }

  List<String> _generateScheduledDates() {
    List<String> scheduledDates = [];
    DateTime currentDate = _startDate;
    while (currentDate.isBefore(_endDate) || currentDate.isAtSameMomentAs(_endDate)) {
      scheduledDates.add(DateFormat('yyyy-MM-dd').format(currentDate));
      currentDate = currentDate.add(Duration(days: 1));
    }
    return scheduledDates;
  }

  void _addMedicine() async {
    // Get the currently logged-in user
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Validate input fields
      if (_medicineNameController.text.isEmpty ||
          _color == null ||
          _type.isEmpty ||
          _totalCount <= 0 ||
          _startDate == null ||
          _endDate == null ||
          _frequency.isEmpty ||
          _doseTimes.isEmpty ||
          _foodIntake.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all fields')),
        );
        return;
      }

      List<String> scheduledDates = _generateScheduledDates();
      List<String> doseTimesFormatted =
      _doseTimes.map((time) => time.format(context)).toList();
      try {
        // Add medicine data to Firestore
        await _firestore.collection('medicines').add({
          'name': _medicineNameController.text,
          'compartment': _compartment,
          'color': _color.value.toRadixString(16),
          'type': _type,
          'quantity': _quantity,
          'totalCount': _totalCount,
          'startDate': _startDate,
          'endDate': _endDate,
          'frequency': _frequency,
          'timesADay': _timesADay,
          'doses': doseTimesFormatted,
          'foodIntake': _foodIntake,
          'scheduledDates': scheduledDates,
          'status': 'Pending',
          'userId': user.uid, // Associate medicine with user
        });
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Medicine added successfully')),
        );
        // Close the current screen
        Navigator.of(context).pop();
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add medicine')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Medicine'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _medicineNameController,
              decoration: InputDecoration(labelText: 'Medicine Name'),
            ),
            SizedBox(height: 20),
            Text('Compartment'),
            Row(
              children: List.generate(6, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _compartment = index + 1;
                    });
                  },
                  child: CircleAvatar(
                    child: Text('${index + 1}'),
                    backgroundColor:
                    _compartment == index + 1 ? Colors.blue : Colors.grey,
                  ),
                );
              }),
            ),
            SizedBox(height: 20),
            Text('Color'),
            Row(
              children: [
                _buildColorCircle(Colors.pink),
                _buildColorCircle(Colors.purple),
                _buildColorCircle(Colors.red),
                _buildColorCircle(Colors.green),
                _buildColorCircle(Colors.orange),
                _buildColorCircle(Colors.blue),
              ],
            ),
            SizedBox(height: 20),
            Text('Type'),
            Wrap(
              spacing: 10.0,
              children: [
                _buildTypeChip('Tablet'),
                _buildTypeChip('Capsule'),
                _buildTypeChip('Cream'),
                _buildTypeChip('Liquid'),
              ],
            ),
            SizedBox(height: 20),
            Text('Quantity'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController()..text = _quantity,
                    decoration: InputDecoration(labelText: 'Quantity'),
                    onChanged: (value) {
                      setState(() {
                        _quantity = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text('Total Count'),
            Slider(
              value: _totalCount.toDouble(),
              min: 1,
              max: 100,
              divisions: 100,
              label: _totalCount.toString(),
              onChanged: (double value) {
                setState(() {
                  _totalCount = value.toInt();
                });
              },
            ),
            SizedBox(height: 20),
            Text('Set Date'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _pickStartDate,
                  child: Text('Start Date: ${DateFormat.yMd().format(_startDate)}'),
                ),
                ElevatedButton(
                  onPressed: _pickEndDate,
                  child: Text('End Date: ${DateFormat.yMd().format(_endDate)}'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text('Frequency of Days'),
            DropdownButton<String>(
              value: _frequency,
              onChanged: (String? newValue) {
                setState(() {
                  _frequency = newValue!;
                });
              },
              items: <String>['Everyday', 'Alternate Days', 'Custom']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Text('How many times a Day'),
            DropdownButton<String>(
              value: _timesADay,
              onChanged: (String? newValue) {
                setState(() {
                  _timesADay = newValue!;
                });
              },
              items: <String>['One Time', 'Two Times', 'Three Times']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Column(
              children: _doses.asMap().entries.map((entry) {
                int idx = entry.key;
                String dose = entry.value;
                return ListTile(
                  leading: Icon(Icons.timer),
                  title: Text(dose),
                  subtitle: Text(_doseTimes[idx].format(context)),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () => _pickTime(idx),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Text('Food Intake'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFoodButton('Before Food'),
                _buildFoodButton('After Food'),
                _buildFoodButton('Before Sleep'),
              ],
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _addMedicine,
                child: Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCircle(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _color = color;
        });
      },
      child: CircleAvatar(
        backgroundColor: color,
        radius: 20,
        child: _color == color ? Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }

  Widget _buildTypeChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _type == label,
      onSelected: (bool selected) {
        setState(() {
          _type = label;
        });
      },
    );
  }

  Widget _buildFoodButton(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _foodIntake == label,
      onSelected: (bool selected) {
        setState(() {
          _foodIntake = label;
        });
      },
    );
  }
}
