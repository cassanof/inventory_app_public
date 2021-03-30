import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/services.dart';
import '../shared/shared.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StudentsScreen extends StatelessWidget {

  // initialize Auth service
  final AuthService auth = AuthService();

  @override
  Widget build(BuildContext context) {

    // provide user stream
    var user = Provider.of<FirebaseUser>(context);

    // reference document for easy accessibility
    DocumentReference studentsDocRef = db.collection('students').document(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: Text('Students'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        actions: [
          // Button that if pressed redirects to AddStudentForm
          FloatingActionButton(
            backgroundColor: activeColor,
            child: Icon(Icons.add, color: Colors.white, size: 35,),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddStudentForm())
              );
            },
          ),
        ],
      ),
      // Here we build a stream that provides us with the whole student list
      // We use a stream so that we have real time changes. This is needed
      // because when we delete/add a student we dont have to refresh a new query
      body: StreamBuilder(
        stream: studentsDocRef.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if(snapshot.hasData && snapshot.data.data != null) {
            print(snapshot.data.data); // debug data
            final studentsList = [];

            // Student data model:
            //
            //  name of student
            //   ⬇
            // 'String': {'grade': int, 'course': String}

            snapshot.data.data.forEach((key, value) {
              print("key: $key value: $value"); // debug data
              final student = Student.fromMap(value as Map<dynamic, dynamic>, key);
              studentsList.add(student);
            });

            return ListView(
              children: [Row( // Row header
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(padding: EdgeInsets.all(12), child: Text(
                    "Name",
                    style: TextStyle(fontSize: 20),
                  )),
                  Spacer(),
                  Padding(padding: EdgeInsets.all(12), child: Text(
                    "Course",
                    style: TextStyle(fontSize: 20),
                  )),
                  Spacer(),
                  Padding(padding: EdgeInsets.all(12), child: Text(
                    "Grade",
                    style: TextStyle(fontSize: 20),
                  )),
                ],
                // Every single student gets his own row
              )] + studentsList.map((student) =>Row(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Using the GestureDetector widget, we created a tappable field,
                  // where if tapped twice it will ask if you want to delete the student
                  Padding(padding: EdgeInsets.all(12), child: GestureDetector(
                    onDoubleTap: () {
                    showDialog(context: context, builder: (BuildContext context) => ConfirmAlertDialog(
                      title: "Delete student: " + (student.name ?? "unknown"),
                      content: "Are you sure you want to delete student: " +
                          (student.name ?? "unknown") + " ?",
                      first: "Cancel",
                      second: "Delete",
                      firstOnPressed: () {
                        Navigator.of(context).pop();
                      },
                      secondOnPressed: () async {
                        await studentsDocRef.updateData({
                          student.name: FieldValue.delete()
                        });
                        Navigator.of(context).pop();
                      },
                    ));
                  },
                  child: Text(
                    student.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ))
                  ),
                  Spacer(),
                  Padding(padding: EdgeInsets.all(12), child: Text(
                    student.course,
                    style: TextStyle(fontSize: 16),
                  )),
                  Spacer(flex: (student.name.length~/3)),
                  Padding(padding: EdgeInsets.all(12), child: Text(
                    student.grade.toString(),
                    style: TextStyle(fontSize: 16),
                  )),
                ]
              )).toList() + [Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Padding(padding: EdgeInsets.only(top: 30, bottom: 30), child: Text(
                  "Tap twice on a student name to delete it",
                  style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                ))],
              )],
            );
          } else {
            // In the case that the stream is empty of data, we return this text
            return Center(
              child: Text(
                'Tap the plus button to add students',
                style: TextStyle(fontSize: 20))
            );
          }
        },
      )
    );
  }
}

// Stateful Widget for AddStudentForm
class AddStudentForm extends StatefulWidget {
  @override
  AddStudentFormState createState() {
    return AddStudentFormState();
  }
}

// AddStudentForm corresponding State class.
// This class holds data related to the form.
class AddStudentFormState extends State<AddStudentForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<AddStudentFormState>.
  final _formKey = GlobalKey<FormState>();

  // Define controllers to access data in fields
  final nameFieldController = TextEditingController();
  final courseFieldController = TextEditingController();
  final gradeFieldController = TextEditingController();

  @override
  void dispose() {
    // Dispose all data in the fields when the Widget gets disposed
    nameFieldController.dispose();
    courseFieldController.dispose();
    gradeFieldController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    var user = Provider.of<FirebaseUser>(context);

    // reference for document for easy accessibility
    DocumentReference studentsDocRef = db.collection('students').document(user.uid);


    // Return a whole scaffold with the form
    return Scaffold(
        appBar: AppBar(
          title: Text('Add a Student'),
          centerTitle: true,
          backgroundColor: Colors.orange,
        ),
        // Make the form scrollable for replication and safety
        body: SingleChildScrollView(
            // Give padding to all the children in Form
            child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              // Insert key to save state
              key: _formKey,
              // Using the validation mode that when a user interacts with a field
              // It automatically validates it
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                 children: <Widget>[
                   // These are the individual input fields
                   // each TextField has its own label, icon,
                   // controller and validator
                    Padding(padding: EdgeInsets.only(top: 20), child: TextFormField(
                      decoration: const InputDecoration(
                        icon: Icon(FontAwesomeIcons.userAlt),
                        labelText: 'Name',
                        hintText: 'The name of the student',
                      ),
                      controller: nameFieldController,
                      validator: (String value) {
                        // if the text is less than 3 or more than 20 chars
                        // return an error
                        return (value.length<3 || value.length>20) ?
                        'The name must be between 3 to 20 characters' : null;
                      },
                    )),
                    Padding(padding: EdgeInsets.only(top: 20), child: TextFormField(
                      decoration: const InputDecoration(
                        icon: Icon(FontAwesomeIcons.users),
                        labelText: 'Course',
                        hintText: 'The class that the student goes to',
                      ),
                      controller: courseFieldController,
                      validator: (String value) {
                        // if the text is less than 3 or more than 15 chars
                        // return an error
                        return (value.length<3 || value.length>15) ?
                        'The class must be between 3 to 15 characters' : null;
                      },
                    )),
                   Padding(padding: EdgeInsets.only(top: 20), child: TextFormField(
                     decoration: const InputDecoration(
                       icon: Icon(FontAwesomeIcons.graduationCap),
                       labelText: 'Grade',
                       hintText: 'The grade of the student',
                     ),
                     controller: gradeFieldController,
                     validator: (String value) {
                       // Because the validator only accepts strings as its input
                       // I adopted this method where in a try-catch block i parse
                       // the string value and convert it into an int, if there is
                       // an alphabetic character in the string, it will throw and error
                       // and the try-catch block will treat it and return an error
                       // to the UI
                       try {
                         var toInt = int.parse(value);

                         return (toInt<1 || toInt>12) ?
                         'Must be between 1 and 12' : null;
                       } catch(e) {
                         print(e);
                         return 'Not a number';
                       }
                     },
                     // Set the keyboard as numeric one
                     keyboardType: TextInputType.number,
                   )),
                   Padding(
                     padding: EdgeInsets.only(top:40),
                     child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                            if (states.contains(MaterialState.pressed))
                              return Colors.deepOrangeAccent;
                            return Colors.orange;
                          },
                        ),
                      ),
                      onPressed: () {
                        // Validate returns true if the form is valid, otherwise false.
                        if (_formKey.currentState.validate()) {
                          // Debug data for console
                          print('valid form submitted!');
                          print('name: ' + nameFieldController.text);
                          print('course: ' + courseFieldController.text);
                          print('grade: ' + gradeFieldController.text);

                          // Database write, where the name of the student is an
                          // individual map with class and grade
                          studentsDocRef.setData({
                            nameFieldController.text: {
                              'course': courseFieldController.text,
                              'grade': int.parse(gradeFieldController.text)
                            }
                          }, merge: true);

                          // Display snackbar text
                          var snackBar = SnackBar(content: Text('Student created successfully'));
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        }
                      },
                      child: Text('Submit'),
                    )
                   )
                 ],
              )
          )
        )
      )
    );
  }
}
