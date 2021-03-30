import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inventory_app/services/globals.dart';
import 'package:provider/provider.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import '../services/services.dart';
import '../shared/shared.dart';

class BorrowedScreen extends StatelessWidget {

  // initialized auth service
  final AuthService auth = AuthService();

  @override
  Widget build(BuildContext context) {

    // provide user stream
    var user = Provider.of<FirebaseUser>(context);

    // reference document for easy accessibility
    DocumentReference equipmentDocRef = db.collection('equipment').document(
        user.uid);

    return Scaffold(
      appBar: AppBar(
        title: Text('Borrowed'),
        centerTitle: true,
        backgroundColor: Colors.green,
        actions: [
          FloatingActionButton(
            backgroundColor: activeColor,
            child: Icon(Icons.add, color: Colors.white, size: 35,),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddBorrowedForm())
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        // Here we build a stream that provides us with the whole equipment list
        // We use a stream so that we have real time changes. This is needed
        // because when we delete/add an item we dont have to refresh a new query
      stream: equipmentDocRef.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if(snapshot.hasData && snapshot.data.data != null) {
            print(snapshot.data.data); // debug data

            // creating a list only for borrowed equipment
            final borrowedEquipmentList = [];

            snapshot.data.data.forEach((key, value) {
              print("key: $key value: $value"); // debug data
              final equipment = Equipment.fromMap(value as Map<dynamic, dynamic>, key);

              // filters in borrowed equipment into the list
              if(equipment.borrowedBy != null) {
                borrowedEquipmentList.add(equipment);
              }
            });

            // Sort list with return date in descending order
            borrowedEquipmentList.sort((a, b) => a.returnDate.compareTo(b.returnDate));

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
                    "Borrowed by",
                    style: TextStyle(fontSize: 20),
                  )),
                  Spacer(),
                  Padding(padding: EdgeInsets.all(12), child: Text(
                    "Return date",
                    style: TextStyle(fontSize: 20),
                  )),
                ],
                // Every single borrowed item gets his own row
              )] + borrowedEquipmentList.map((equipment) => Row(
                  children: [
                    // Using the GestureDetector widget, we created a tappable field,
                    // where if tapped twice it will ask if you want to return the equipment
                    Padding(padding: EdgeInsets.all(12), child: GestureDetector(
                        onDoubleTap: () {
                          showDialog(context: context, builder: (BuildContext context) => ConfirmAlertDialog(
                            title: "Return item: " + (equipment.name ?? "unknown"),
                            content: "Are you sure you want to return item: " + (equipment.name ?? "unknown"),
                            first: "Cancel",
                            second: "Delete",
                            firstOnPressed: () {
                              Navigator.of(context).pop();
                            },
                            secondOnPressed: () async {
                              // sets data fields to null instead of deleting them
                              await equipmentDocRef.setData({
                                equipment.name: {
                                  'borrowedBy': null,
                                  'returnDate': null
                                }
                              }, merge: true);
                              Navigator.of(context).pop();
                            },
                          ));
                        },
                        child: Text(
                          equipment.name,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ))
                    ),
                    Spacer(),
                    Padding(padding: EdgeInsets.all(12), child: Text(
                      equipment.borrowedBy,
                      style: TextStyle(fontSize: 12),
                    )),
                    Spacer(flex: (equipment.name.length~/3)),
                    Padding(
                      padding: EdgeInsets.all(12),
                      // Asynchronous instant function that returns a red text when
                      // the return date is less than the current date
                      child: (() {
                        Color _textColor;
                        Timestamp _returnDate = equipment.returnDate;
                        bool _isAfterToday = false;

                        if (DateTime.now().toUtc().isAfter(
                            DateTime.fromMillisecondsSinceEpoch(
                              _returnDate.millisecondsSinceEpoch,
                              isUtc: false,
                            ).toUtc())) _isAfterToday = true;

                        print('_isAfterToday: $_isAfterToday'); // debug data
                        _textColor = _isAfterToday ? Colors.red : Colors.white;
                        return Text(
                          '${(equipment.returnDate.toDate().month).toString()}/' +
                              '${(equipment.returnDate.toDate().day).toString()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _textColor
                          ),
                        );
                      })()
                    ),
                  ]
              )).toList() + [Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Padding(padding: EdgeInsets.only(top: 30, bottom: 30), child: Text(
                  (() {
                    if(borrowedEquipmentList.isEmpty) {
                      // if there is no borrowed equipment return this message
                      return "Tap on the plus button to mark\n an item as borrowed";
                    } else {
                      // if there are borrowed equipment return this message instead
                      return "Tap twice on an equipment name\nto mark it as returned";
                    }
                  })(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                ))],
              )],
            );
          } else {
            // In the case that the stream is empty of data, we return this text
            return Center(
                child: Text(
                    'No equipment found.\nAdd it in the equipment screen',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20))
            );
          }
        },
      )
    );
  }
}

// Stateful Widget for AddBorrowedForm
class AddBorrowedForm extends StatefulWidget {
  @override
  AddBorrowedFormState createState() {
    return AddBorrowedFormState();
  }
}

// AddBorrowedForm corresponding State class.
// This class holds data related to the form.
class AddBorrowedFormState extends State<AddBorrowedForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<AddStudentFormState>.
  final _formKey = GlobalKey<FormState>();

  // Define controllers to access data in fields
  String equipmentNameValue;
  String studentNameValue;
  final returnDateFieldController = TextEditingController();

  @override
  void dispose() {
    // Dispose all data in the fields when the Widget gets disposed
    equipmentNameValue = null;
    studentNameValue = null;
    returnDateFieldController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // provide user stream
    var user = Provider.of<FirebaseUser>(context);

    // reference for document for easy accessibility
    DocumentReference studentsDocRef = db.collection('students').document(user.uid);
    DocumentReference equipmentDocRef = db.collection('equipment').document(user.uid);


    // Return a whole scaffold with the form
    return Scaffold(
        appBar: AppBar(
          title: Text('Mark equipment as borrowed'),
          centerTitle: true,
          backgroundColor: Colors.green,
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
                        // Here we build a stream that provides us with the whole equipment list
                        // We use a stream so that we have real time changes. This is needed
                        // because when we delete/add an item we dont have to refresh a new query
                        StreamBuilder(
                          stream: equipmentDocRef.snapshots(),
                          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                            if(snapshot.hasData && snapshot.data.data != null) {
                              final List<String> equipmentNamesList = [];

                              snapshot.data.data.forEach((key, value) {
                                final equipment = Equipment.fromMap(value as Map<dynamic, dynamic>, key);

                                // Filter only equipment that has not been borrowed
                                equipment.borrowedBy == null ? equipmentNamesList.add(equipment.name) : null;
                              });

                              print('equipment names: $equipmentNamesList'); // debug data

                              // Dropdown list of non-borrowed equipment
                              return Padding(padding: EdgeInsets.only(top: 20), child: DropdownButtonFormField(
                                items: equipmentNamesList.map((String equipmentName) {
                                  return new DropdownMenuItem(
                                      value: equipmentName,
                                      child: Text(equipmentName)
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    print('selected equipment: $newValue'); // debug data
                                    equipmentNameValue = newValue;
                                  });
                                },
                                value: (() {
                                  // This is for when the qr code scans a tag that has an invalid
                                  // equipment name. It checks if the equipment name actually exists
                                  print('$equipmentNameValue is in list: ' + equipmentNamesList.contains(equipmentNameValue).toString()); // debug data
                                  if(equipmentNamesList.contains(equipmentNameValue)) {
                                    return equipmentNameValue;
                                  } else {
                                    print("equipment name not in list"); // debug data
                                  }
                                })(),
                                validator: (String value) {
                                  return value == null ? 'Select the equipment' : null;
                                },
                                decoration: InputDecoration(
                                  icon: Icon(FontAwesomeIcons.thList),
                                  hintText: 'Equipment',
                                ),
                              ));
                            } else {
                              return Text('Loading...');
                            }
                          },
                        ),
                        // Here we build a stream that provides us with the whole students list
                        // We use a stream so that we have real time changes. This is needed
                        // because when we delete/add a student we dont have to refresh a new query
                        StreamBuilder(
                          stream: studentsDocRef.snapshots(),
                          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                            if(snapshot.hasData && snapshot.data.data != null) {
                              final List<String> studentNamesList = [];

                              snapshot.data.data.forEach((key, value) {
                                final student = Student.fromMap(value as Map<dynamic, dynamic>, key);
                                studentNamesList.add(student.name);
                              });

                              print('students names: $studentNamesList'); // debug data

                              // Dropdown list of all students
                              return Padding(padding: EdgeInsets.only(top: 20), child: DropdownButtonFormField(
                                items: studentNamesList.map((String studentName) {
                                  return new DropdownMenuItem(
                                    value: studentName,
                                    child: Text(studentName)
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    print('selected student: $newValue'); // debug data
                                    studentNameValue = newValue;
                                  });
                                },
                                value: studentNameValue,
                                validator: (String value) {
                                  return value == null ? 'Select a student' : null;
                                },
                                decoration: InputDecoration(
                                  icon: Icon(FontAwesomeIcons.user),
                                  hintText: 'Student',
                                ),
                              ));
                            } else {
                              return Text('Loading...');
                            }
                          },
                        ),
                        // The return date picker field
                        Padding(padding: EdgeInsets.only(top: 20), child: TextFormField(
                          controller: returnDateFieldController,
                          decoration: InputDecoration(
                            icon: Icon(FontAwesomeIcons.calendarDay),
                            labelText: "Return Date",
                            hintText: "The date that you want the item to be returned",
                          ),
                          onTap: () async {
                            DateTime date;

                            FocusScope.of(context).requestFocus(new FocusNode());

                            // waits that the user selects the date from the datePicker widget
                            date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2050),
                            );

                            // transforms the date into a string that is digestible
                            // for both the controller and validator
                            returnDateFieldController.text = date.toString();
                          },
                          validator: (String value) {
                            return (value.isEmpty || value == null) ?
                                'Please select a return date' : null;
                          },
                        )),
                        Padding(padding: EdgeInsets.only(top: 40), child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty
                                .resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                if (states.contains(MaterialState.pressed)) {
                                  return Colors.lightGreenAccent;
                                }
                                return Colors.green;
                              },
                            ),
                          ),
                          onPressed: () async {
                            print("pressed"); // debug data

                            // Waits that the user scans a qrcode
                            String qrCodeScan = await scanner.scan();

                            // Tries to decode QRCODE into a json, the qrcode has to be
                            // a text type qrcode with content in this format:
                            // {"name" : "put name here", "category" : "put category here"}
                            //
                            // Then, equipmentNameValue will be mapped to the name json field
                            //
                            // if the json.decode fails due to bad formatting it will throw an error
                            // the catch block will catch the error and return a snackbar
                            try {
                              Map valueMap = json.decode(qrCodeScan);
                              print('qrcode json map: $valueMap'); // debug data

                              setState(() {
                                // uses setState to reload ui as we are not
                                // using a controller
                                equipmentNameValue = valueMap["name"];
                              });
                            } catch (e) {
                              print(e); // Print error to console
                              var snackBar = SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text('Invalid QR-Code format, follow the documentation')
                              );
                              ScaffoldMessenger.of(context).showSnackBar(snackBar);
                            }
                          },
                          child: Icon(FontAwesomeIcons.qrcode),
                        )),
                        Padding(
                            padding: EdgeInsets.only(top:40),
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                    if (states.contains(MaterialState.pressed))
                                      return Colors.lightGreenAccent;
                                    return Colors.green;
                                  },
                                ),
                              ),
                              onPressed: () {
                                // Validate returns true if the form is valid, otherwise false.
                                if (_formKey.currentState.validate()) {
                                  // Convert flutter's DateTime to firestore's Timestamp
                                  Timestamp returnDateValue = Timestamp.fromDate(
                                    DateTime.parse(returnDateFieldController.text)
                                  );

                                  // Debug data for console
                                  print('valid form submitted!');
                                  print('student: ' + studentNameValue);
                                  print('equipment: ' + equipmentNameValue);
                                  // return dates in different formats for debugging
                                  print('return date in DateTime: ' + returnDateFieldController.text);
                                  print('return date parsed: ' + DateTime.parse(returnDateFieldController.text).toString());
                                  print('return date in Timestamp: ' + returnDateValue.toString());
                                  print('return date Timestamp to Datetime: ' + (returnDateValue.toDate()).toString());

                                  // Sets the database fields borrowedBy and returnDate
                                  // of the selected equipment item to the local values
                                  equipmentDocRef.setData({
                                    equipmentNameValue: {
                                      'borrowedBy': studentNameValue,
                                      'returnDate': returnDateValue
                                    }
                                  }, merge: true);

                                  // Display snackbar text
                                  var snackBar = SnackBar(content: Text('Equipment marked as borrowed'));
                                  ScaffoldMessenger.of(context).showSnackBar(snackBar);

                                  // Close scaffold
                                  Navigator.of(context).pop();
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
