import 'package:cloud_firestore/cloud_firestore.dart';

// Creating a Student db model for ease of use and stability

class Student {
  int grade;
  String name;
  String course;

  Student(this.grade,this.course,this.name);

  // a factory that returns the student data by giving the name
  factory Student.fromMap(Map<dynamic, dynamic> map, String name) {
    final grade = map["grade"] as int;
    final course = map["course"] as String;
    return Student(grade, course, name);
  }
}

// Creating a Equipment db model for ease of use and stability
class Equipment {
  String name;
  String category;
  String borrowedBy;
  Timestamp returnDate;
  bool photo;


  Equipment(this.photo, this.returnDate, this.borrowedBy, this.category,this.name);

  // a factory that returns the equipment data by giving the name
  factory Equipment.fromMap(Map<dynamic, dynamic> map, String name) {
    final photo = map["photo"] as bool;
    final returnDate = map["returnDate"] as Timestamp;
    final borrowedBy = map["borrowedBy"] as String;
    final category = map["category"] as String;
    return Equipment(photo, returnDate, borrowedBy, category, name);
  }
}
