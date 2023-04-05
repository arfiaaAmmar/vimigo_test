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
