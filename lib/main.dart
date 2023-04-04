import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

void main() => runApp(const AttendanceApp());

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AttendanceScreen(),
    );
  }
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<AttendanceRecord> _attendanceRecords = [];
  List<AttendanceRecord> _filteredRecords = [];
  String _dateFormat = 'dd/MM/yyyy';

  //Get Attendance Record from given dataset in PDF
  //Dataset was converted to JSON format
  Future<void> _fetchAttendanceData() async {
    final String jsonString =
        await rootBundle.loadString('assets/attendance_records.json');
    final data = json.decode(jsonString);
    final records = List<AttendanceRecord>.from(
        data.map((record) => AttendanceRecord.fromJson(record)));
    setState(() {
      _attendanceRecords = records;
    });
  }

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
    developer.log(_attendanceRecords.toString(), name: "My Log");
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addRecord(String name) {
    setState(() {
      _attendanceRecords.insert(
          0,
          AttendanceRecord(
              user: _nameController.text, checkIn: DateTime.now().toUtc()));
      _filteredRecords = _attendanceRecords;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Record added successfully!'),
      ),
    );
  }

  void _sortRecordsByTime() {
    setState(() {
      _filteredRecords.sort((a, b) => b.checkIn!.compareTo(a.checkIn!));
    });
  }

  void _changeDateFormat() {
    setState(() {
      _dateFormat =
          _dateFormat == 'dd/MM/yyyy' ? 'dd MMM yyyy, h:mm a' : 'dd/MM/yyyy';
    });
  }

  void _filterRecords(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRecords = _attendanceRecords;
      } else {
        _filteredRecords = _attendanceRecords
            .where((record) =>
                record.user!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
      ),
      body: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              _filterRecords(value);
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredRecords.length,
              itemBuilder: (context, index) {
                AttendanceRecord record = _filteredRecords[index];
                return ListTile(
                  title: Text(record.user.toString()),
                  subtitle:
                      Text(DateFormat(_dateFormat).format(record.checkIn!)),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              _changeDateFormat();
            },
            child: const Icon(Icons.date_range),
          ),
          FloatingActionButton(
            onPressed: () {
              _sortRecordsByTime();
            },
            child: const Icon(Icons.sort),
          ),
          FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Add Record'),
                  content: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter name',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _nameController.clear();
                      },
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () {
                        _addRecord(_nameController.text);
                        Navigator.pop(context);
                        _nameController.clear();
                      },
                      child: const Text('ADD'),
                    ),
                    showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: lastDate)
                  ],
                ),
              );
            },
            child: const Icon(Icons.add),
          )
        ],
      ),
    );
  }
}

class AttendanceRecord {
  String? user;
  String? phone;
  DateTime? checkIn;

  AttendanceRecord({this.user, this.phone, this.checkIn});

  AttendanceRecord.fromJson(Map<String, dynamic> json) {
    user = json['user'];
    phone = json['phone'];
    checkIn = DateTime.tryParse(json['check-in']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user'] = user;
    data['phone'] = phone;
    data['check-in'] = checkIn;
    return data;
  }
}
