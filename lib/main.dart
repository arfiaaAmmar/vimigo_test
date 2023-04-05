import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share/share.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:vimigo_test/attendance_record.dart';
import 'package:vimigo_test/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstOpen = prefs.getBool("isFirstOpen") ?? true;

  runApp(AttendanceApp(isFirstOpen: isFirstOpen));
}

class AttendanceApp extends StatelessWidget {
  final bool isFirstOpen;

  const AttendanceApp({super.key, required this.isFirstOpen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isFirstOpen ? const AttendanceScreen() : const OnboardingScreen(),
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
  DateTime _dateTime = DateTime.now();
  String _dateFormat = 'dd MMM yyyy, h:mm a';
  String _sortList = "recent";
  bool _atEndOfList = false;

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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        // user has reached the end of the list
        setState(() {
          _atEndOfList = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addRecord(String name, DateTime dateTime) {
    setState(() {
      _attendanceRecords.insert(
        0,
        AttendanceRecord(user: _nameController.text, checkIn: _dateTime),
      );
      _filteredRecords = _attendanceRecords;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Record added successfully!'),
      ),
    );
  }

  void _sortRecordsByTime() {
    _sortList == "recent"
        ? _filteredRecords.sort((a, b) => b.checkIn!.compareTo(a.checkIn!))
        : _filteredRecords.sort((a, b) => a.checkIn!.compareTo(b.checkIn!));
  }

  void _changeDateFormat() {
    setState(() {
      _dateFormat = _dateFormat == 'dd MMM yyyy, h:mm a'
          ? 'time ago'
          : 'dd MMM yyyy, h:mm a';
    });
  }

  void _showDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    ).then((value) {
      setState(() {
        _dateTime = value!;
      });
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
          AnimatedOpacity(
            opacity: _atEndOfList ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              height: 50.0,
              alignment: Alignment.center,
              child: const Text(
                "You have reached the end of the list",
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _filteredRecords.length,
              itemBuilder: (context, index) {
                AttendanceRecord record = _filteredRecords[index];
                return ListTile(
                    title: Text(record.user.toString()),
                    subtitle: Row(
                      children: [
                        _dateFormat == "time ago"
                            ? Text(timeago.format(record.checkIn!))
                            : Text(DateFormat(_dateFormat)
                                .format(record.checkIn!)),
                        TextButton(
                          child: const Text("Share contact info"),
                          onPressed: () {
                            Share.share(
                              record.phone.toString(),
                              subject: record.phone.toString(),
                            );
                          },
                        ),
                      ],
                    ));
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
              setState(() {
                _sortList = _sortList == "recent" ? "oldest" : "recent";
              });
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
                      onPressed: _showDatePicker,
                      child: const Text('ADD DATE'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _nameController.clear();
                      },
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () {
                        _addRecord(_nameController.text, _dateTime);
                        Navigator.pop(context);
                        _nameController.clear();
                      },
                      child: const Text('ADD'),
                    ),
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
