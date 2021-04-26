import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inventory_app/main.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import '../shared/shared.dart';
import '../services/services.dart';

// Global variable that holds the image path from the camera screen
String cameraImagePath;

class EquipmentScreen extends StatelessWidget {

  // initialize Auth service
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
        title: Text('Equipment'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        // Button to logout dialog
        leading: FlatButton(
            child: Icon(FontAwesomeIcons.userEdit),
            color: Colors.red,
            onPressed: () {
              showDialog(context: context, builder: (BuildContext context) => ConfirmAlertDialog(
                title: "User: " + (user.displayName ?? "Guest"),
                content: "uid: " + user.uid,
                first: "Back",
                second: "Logout",
                secondColor: Colors.redAccent,
                firstOnPressed: () {
                  Navigator.of(context).pop();
                },
                secondOnPressed: () async {
                  await auth.signOut();
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                },
              ));
            }
          ),

        actions: [
          FloatingActionButton(
            backgroundColor: activeColor,
            child: Icon(Icons.add, color: Colors.white, size: 35,),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddEquipmentForm())
              );
            }
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(),
        // Here we build a stream that provides us with the whole equipment list
        // We use a stream so that we have real time changes. This is needed
        // because when we delete/add an item we dont have to refresh a new query
        body: StreamBuilder(
        stream: equipmentDocRef.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if(snapshot.hasData && snapshot.data.data != null) {
            print(snapshot.data.data); // debug data
            final equipmentList = [];

            // Equipment data model:
            //
            //  name of equipment                     name reference of a student
            //   ⬇                                                 ⬇
            // 'String': {'returnDate': Timestamp, 'borrowedBy': String, 'photo': bool, 'category': String}

            snapshot.data.data.forEach((key, value) {
              print("key: $key value: $value"); // debug data
              final equipment = Equipment.fromMap(value as Map<dynamic, dynamic>, key);
              equipmentList.add(equipment);
            });

            return ListView(
              children: equipmentList.map((equipment) =>Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Using the GestureDetector widget, we created a tappable field,
                  // where if tapped twice it will ask if you want to delete the item
                  Padding(padding: EdgeInsets.all(20), child: GestureDetector(
                    onDoubleTap: () {
                      print('tap'); // debug data
                      showDialog(context: context, builder: (BuildContext context) => ConfirmAlertDialog(
                        title: "Delete equipment item: " + (equipment.name ?? "unknown"),
                        content: "Are you sure you want to delete item: " + (equipment.name ?? "unknown"),
                        first: "Cancel",
                        second: "Delete",
                        firstOnPressed: () {
                          Navigator.of(context).pop();
                        },
                        secondOnPressed: () async {
                          await equipmentDocRef.updateData({
                            equipment.name: FieldValue.delete()
                          });
                          Navigator.of(context).pop();
                        },
                      ));
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width-50,
                      height: 200,
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.all(Radius.circular(20))
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // if a photo of the item exists, display it
                          if(equipment.photo) Padding(padding: EdgeInsets.only(left: 20), child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage('http://localhost:5337/uploads/' +
                                    user.uid + '_' + equipment.name + '.jpg'),
                                fit: BoxFit.fill
                              )
                            ),
                          )),
                          // using Flexible() in a way that text does not overflow
                          // but gets sent to a new line instead
                          Flexible(child: Padding(padding: EdgeInsets.only(left: 20, right: 2), child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Name: " + equipment.name,),
                              Text("Category: " + equipment.category,),
                              if(equipment.serial.isNotEmpty) Text("Serial: " + equipment.serial,),
                              Text(
                                  (() {
                                    if(equipment.borrowedBy != null) {
                                      return "Borrowed: Yes";
                                    } else {
                                      return "Borrowed: No";
                                    }
                                  })(),
                              ),
                            ],
                          )))
                        ],
                      ),
                    )
                  ))
                ]
              )).toList() + [Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Padding(padding: EdgeInsets.only(top: 30, bottom: 30), child: Text(
                  "Tap twice on a item to delete it",
                  style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                ))],
              )],
            );
          } else {
            // In the case that the stream is empty of data, we return this text
            return Center(
                child: Text(
                    'Tap the plus button to add an Equipment item',
                    style: TextStyle(fontSize: 16))
            );
          }
        },
      )
    );
  }
}

// Stateful widget for TakePictureScreen
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

// TakePictureScreen corresponding State class.
// This class holds data related to the form.
class TakePictureScreenState extends State<TakePictureScreen> {
  // Add two variables to the state class to store the CameraController and
  // the Future.
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fill this out in the next steps.
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Construct the path where the image should be saved using the
            // pattern package.
            final path = p.join(
              // Store the picture in the temp directory.
              // Find the temp directory using the `path_provider` plugin.
              (await getTemporaryDirectory()).path,
              '${DateTime.now()}.png',
            );

            // Attempt to take a picture and log where it's been saved.
            await _controller.takePicture(path);

            // If the picture was taken, save path
            cameraImagePath = path;
            print('camera path: $cameraImagePath'); // debug data

            // close window
            Navigator.of(context).pop();
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
    );
  }
}


// Stateful Widget for AddEquipmentForm
class AddEquipmentForm extends StatefulWidget {
  @override
  AddEquipmentFormState createState() {
    return AddEquipmentFormState();
  }
}

// AddEquipmentForm corresponding State class.
// This class holds data related to the form.
class AddEquipmentFormState extends State<AddEquipmentForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<AddStudentFormState>.
  final _formKey = GlobalKey<FormState>();

  var image;

  // Define controllers to access data in fields
  final nameFieldController = TextEditingController();
  final categoryFieldController = TextEditingController();
  final serialFieldController = TextEditingController();

  // Asynchronous function to upload the image to a server
  // this function takes an image, renames it and uploads it to a http POST server
  Future uploadImage(String filename, String url, String newName) async {
    String _dir = (await getApplicationDocumentsDirectory()).path;

    String _newPath = p.join(_dir, newName);

    File _image = await File(filename).copy(_newPath);

    print('new image path: $_image'); // debug data

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(await http.MultipartFile.fromPath('picture', _image.path));
    var res = await request.send();
    return res.reasonPhrase;
  }

  @override
  void dispose() {
    // Dispose all data in the fields when the Widget gets disposed
    nameFieldController.dispose();
    categoryFieldController.dispose();
    serialFieldController.dispose();

    // also resets the image
    image = null;
    // and resets the path of the camera image
    cameraImagePath = null;


    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<FirebaseUser>(context);

    // reference document for easy accessibility
    DocumentReference equipmentDocRef = db.collection('equipment').document(
        user.uid);


    // Return a whole scaffold with the form
    return Scaffold(
        appBar: AppBar(
          title: Text('Add an Equipment'),
          centerTitle: true,
          backgroundColor: Colors.blue,
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
                            icon: Icon(FontAwesomeIcons.video),
                            labelText: 'Name',
                            hintText: 'The name of the equipment',
                          ),
                          controller: nameFieldController,
                          validator: (String value) {
                            // if the text is less than 3 or more than 30 chars
                            // return an error
                            return (value.length < 3 || value.length > 30)
                                ?
                            'The name must be between 3 to 30 characters'
                                : null;
                          },
                        )),
                        Padding(padding: EdgeInsets.only(top: 20), child: TextFormField(
                          decoration: const InputDecoration(
                            icon: Icon(FontAwesomeIcons.thLarge),
                            labelText: 'Category',
                            hintText: 'The category of the equipment',
                          ),
                          controller: categoryFieldController,
                          validator: (String value) {
                            // if the text is less than 3 or more than 10 chars
                            // return an error
                            return (value.length < 3 || value.length > 10)
                                ?
                            'The name must be between 3 to 10 characters'
                                : null;
                          },
                        )),
                        Padding(padding: EdgeInsets.only(top: 20), child: TextFormField(
                          decoration: const InputDecoration(
                            icon: Icon(FontAwesomeIcons.barcode),
                            labelText: 'Serial',
                            hintText: 'A serial code (optional)',
                          ),
                          controller: serialFieldController,
                          validator: (String value) {
                            if (value.isNotEmpty) {
                              return (value.length < 1 || value.length > 30)
                                  ?
                              'The serial must be between 1 to 30 characters'
                                  : null;
                            } else {
                              return null;
                            }
                          },
                        )),
                        Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // QR-Code scan button
                              ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty
                                      .resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                      if (states.contains(MaterialState.pressed)) {
                                        return Colors.lightBlueAccent;
                                      }
                                      return Colors.blue;
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
                                  // Then, the FieldControllers for name and category will map to the json values
                                  //
                                  // if the json.decode fails due to bad formatting it will throw an error
                                  // the catch block will catch the error and return a snackbar
                                  try {
                                    Map valueMap = json.decode(qrCodeScan);
                                    print('qrcode json map: $valueMap'); // debug data

                                    nameFieldController.text = valueMap["name"];
                                    categoryFieldController.text = valueMap["category"];

                                    try {
                                      serialFieldController.text = valueMap["serial"];
                                    } catch (e) {
                                      print(e);
                                      serialFieldController.text = "";
                                    }

                                  } catch (e) {
                                    print(e); // print error to console
                                    var snackBar = SnackBar(
                                      backgroundColor: Colors.red,
                                        content: Text('Invalid QR-Code format, follow the documentation')
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                  }
                                },
                                child: Icon(FontAwesomeIcons.qrcode),
                              ),
                              // Camera photo picker button
                              ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty
                                      .resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                      if (states.contains(MaterialState.pressed)) {
                                        return Colors.lightBlueAccent;
                                      }
                                      return Colors.blue;
                                    },
                                  ),
                                ),
                                onPressed: () async {
                                  print("pressed"); // debug data
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TakePictureScreen(camera: firstCamera),
                                      )
                                  );
                                },
                                child: Icon(FontAwesomeIcons.camera),
                              ),
                            ]
                          )
                        ),
                        Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty
                                    .resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                    if (states.contains(MaterialState.pressed))
                                      return Colors.lightBlueAccent;
                                    return Colors.blue;
                                  },
                                ),
                              ),
                              onPressed: () async {
                                // Validate returns true if the form is valid, otherwise false.
                                if (_formKey.currentState.validate()) {
                                  bool hasImage = cameraImagePath != null;

                                  // Debug data for console
                                  print('valid form submitted!');
                                  print('name: ' + nameFieldController.text);
                                  print('category: ' + categoryFieldController.text);
                                  print('serial: ' + serialFieldController.text);
                                  print('photo: ' + hasImage.toString());

                                  // if the image is not null, upload it with identifier
                                  // the identifier for the image goes like this:
                                  // userid_nameofitem
                                  if (hasImage) {
                                    var res = await uploadImage(
                                        cameraImagePath,
                                        "http://localhost:5337/upload",
                                        user.uid + '_' +
                                            nameFieldController.text + '.jpg');

                                    setState(() {
                                      // setState to reload ui
                                      print('http response: $res'); // debug data
                                    });
                                  }


                                  // Database write, where the name of the name of the
                                  // item is the identifier
                                  equipmentDocRef.setData({
                                    nameFieldController.text: {
                                      'category': categoryFieldController.text,
                                      'serial': serialFieldController.text,
                                      'photo': hasImage,
                                      'borrowedBy': null,
                                      'returnDate': null,
                                    }
                                  }, merge: true);

                                  // Display snackbar text
                                  var snackBar = SnackBar(content: Text('Item created successfully'));
                                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                }
                              },
                              child: Text('Submit'),
                            )
                        ),
                      ],
                    )
                )
            )
        )
    );
  }
}
