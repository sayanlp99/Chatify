import 'dart:async';
import 'dart:io';
import 'package:ChatApp/Screens/Welcome/welcome_screen.dart';
import 'package:ChatApp/Widgets/ProgressWidget.dart';
import 'package:ChatApp/constants.dart';
import 'package:ChatApp/resources/user_state_methods.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ChatApp/main.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // iconTheme: IconThemeData(
        //   color: Colors.white,
        // ),
        title: Text("Account Settings"),
        backgroundColor: kPrimaryColor,
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.signOutAlt),
            onPressed: () => UserStateMethods().logoutuser(context),
          )
        ],
        // title: Text(
        //   "Account Settings",
        //   style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        // ),
        centerTitle: true,
      ),
      body: SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  State createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  SharedPreferences preferences;
  TextEditingController nameTextEditingController;
  TextEditingController emailTextEditingController;

  String id = "";
  String name = "";
  String email = "";
  String photoUrl = "";
  String defaultPhotoUrl =
      "https://thumbs.dreamstime.com/b/default-avatar-profile-vector-user-profile-default-avatar-profile-vector-user-profile-profile-179376714.jpg";
  File imageFileAvatar;
  final picker = ImagePicker();
  bool isLoading = false;
  final FocusNode nameFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  bool _status = true;
  final FocusNode myFocusNode = FocusNode();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readDataFromLocal();
  }

  void readDataFromLocal() async {
    preferences = await SharedPreferences.getInstance();
    id = preferences.getString("uid");
    name = preferences.getString("name");
    photoUrl = preferences.getString("photo");
    email = preferences.getString("email");
    nameTextEditingController = TextEditingController(text: name);
    emailTextEditingController = TextEditingController(text: email);

    setState(() {});
  }

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        imageFileAvatar = File(pickedFile.path);
        isLoading = true;
      }
    });

    if (pickedFile != null) {
      // upload image to firebase storage
      uploadImageToFirestoreAndStorage();
    }
  }

  Future uploadImageToFirestoreAndStorage() async {
    String mFileName = id;
    StorageReference storageReference =
        FirebaseStorage.instance.ref().child(mFileName);
    StorageUploadTask storageUploadTask =
        storageReference.putFile(imageFileAvatar);
    StorageTaskSnapshot storageTaskSnapshot;
    storageUploadTask.onComplete.then((value) {
      if (value.error == null) {
        storageTaskSnapshot = value;
        storageTaskSnapshot.ref.getDownloadURL().then((newImageDownloadUrl) {
          photoUrl = newImageDownloadUrl;
          Firestore.instance.collection("Users").document(id).updateData(
              {"photoUrl": photoUrl, "name": name}).then((data) async {
            await preferences.setString("photo", photoUrl);

            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(msg: "Updated Successfully.");
          });
        }, onError: (errorMsg) {
          setState(() {
            isLoading = false;
          });
          Fluttertoast.showToast(
              msg: "Error occured in getting Download Url !");
        });
      }
    }, onError: (errorMsg) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: errorMsg.toString());
    });
  }

  void updateData() {
    nameFocusNode.unfocus();
    emailFocusNode.unfocus();
    setState(() {
      isLoading = false;
    });

    Firestore.instance
        .collection("Users")
        .document(id)
        .updateData({"name": name}).then((data) async {
      await preferences.setString("photo", photoUrl);
      await preferences.setString("name", name);

      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "Updated Successfully.");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          child: Column(
            children: <Widget>[
              //Profile Image - Avatar
              Container(
                child: Center(
                  child: Stack(
                    children: <Widget>[
                      (imageFileAvatar == null)
                          ? (photoUrl != "")
                              ? Container(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Material(
                                          // display already existing image
                                          child: CachedNetworkImage(
                                            placeholder: (context, url) =>
                                                Container(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.0,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        Colors.lightBlueAccent),
                                              ),
                                              width: 200.0,
                                              height: 200.0,
                                              padding: EdgeInsets.all(20.0),
                                            ),
                                            imageUrl:
                                                photoUrl ?? defaultPhotoUrl,
                                            width: 200.0,
                                            height: 200.0,
                                            fit: BoxFit.cover,
                                          ),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(125.0)),
                                          clipBehavior: Clip.hardEdge),
                                    ],
                                  ),
                                )
                              : Icon(
                                  Icons.account_circle,
                                  size: 90.0,
                                  color: Colors.grey,
                                )
                          : Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Material(
                                      // display new updated image
                                      child: Image.file(
                                        imageFileAvatar,
                                        width: 200.0,
                                        height: 200.0,
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(125.0)),
                                      clipBehavior: Clip.hardEdge),
                                ],
                              ),
                            ),
                      // IconButton(
                      //   icon: Icon(
                      //     Icons.camera_alt,
                      //     size: 100.0,
                      //     color: Colors.white54.withOpacity(0.3),
                      //   ),
                      //   onPressed: getImage,
                      //   padding: EdgeInsets.all(0.0),
                      //   splashColor: Colors.transparent,
                      //   highlightColor: Colors.grey,
                      //   iconSize: 200.0,
                      // )
                      GestureDetector(
                        onTap: getImage,
                        child: Padding(
                            padding: EdgeInsets.only(top: 150.0, right: 120.0),
                            child: new Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                new CircleAvatar(
                                  backgroundColor: Colors.red,
                                  radius: 25.0,
                                  child: new Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  ),
                                )
                              ],
                            )),
                      )
                    ],
                  ),
                ),
                width: double.infinity,
                margin: EdgeInsets.all(20.0),
              ),

              Column(children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(1.0),
                  child: isLoading ? oldcircularprogress() : Container(),
                ),
              ]),

              new Container(
                color: Color(0xFFFFFFFF),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 25.0),
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(
                              left: 25.0, right: 25.0, top: 25.0),
                          child: new Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              new Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  new Text(
                                    'Personal Information',
                                    style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              new Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  _status ? _getEditIcon() : new Container(),
                                ],
                              )
                            ],
                          )),
                      Padding(
                          padding: EdgeInsets.only(
                              left: 25.0, right: 25.0, top: 25.0),
                          child: new Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              new Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  new Text(
                                    'Name',
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          )),
                      Padding(
                          padding: EdgeInsets.only(
                              left: 25.0, right: 25.0, top: 2.0),
                          child: new Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              new Flexible(
                                child: new TextField(
                                  decoration: const InputDecoration(
                                    hintText: "Enter Your Name",
                                  ),
                                  controller: nameTextEditingController,
                                  enabled: !_status,
                                  autofocus: !_status,
                                  onChanged: (value) {
                                    name = value;
                                  },
                                  focusNode: nameFocusNode,
                                ),
                              ),
                            ],
                          )),
                      Padding(
                          padding: EdgeInsets.only(
                              left: 25.0, right: 25.0, top: 25.0),
                          child: new Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              new Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  new Text(
                                    'Email ID',
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          )),
                      Padding(
                          padding: EdgeInsets.only(
                              left: 25.0, right: 25.0, top: 2.0),
                          child: new Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              new Flexible(
                                child: new TextField(
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                      hintText: "Enter Email ID"),
                                  enabled: !_status,
                                  controller: emailTextEditingController,
                                  focusNode: emailFocusNode,
                                ),
                              ),
                            ],
                          )),
                      !_status ? _getActionButtons() : new Container(),
                    ],
                  ),
                ),
              )

              // Column(
              //   children: <Widget>[
              //     Padding(
              //       padding: EdgeInsets.all(1.0),
              //       child: isLoading ? oldcircularprogress() : Container(),
              //     ),

              //     // Username

              //     Container(
              //       child: Text("Profile Name: ",
              //           style: TextStyle(
              //               fontStyle: FontStyle.italic,
              //               fontWeight: FontWeight.bold,
              //               color: Colors.lightBlueAccent)),
              //       margin: EdgeInsets.only(left: 10.0, bottom: 5.0, top: 10.0),
              //     ),

              //     Container(
              //         child: Theme(
              //           data: Theme.of(context)
              //               .copyWith(primaryColor: Colors.lightBlueAccent),
              //           child: TextField(
              //             decoration: InputDecoration(
              //                 hintText: "Your Name",
              //                 contentPadding: EdgeInsets.all(5.0),
              //                 hintStyle: TextStyle(color: Colors.grey)),
              //             controller: nameTextEditingController,
              //             onChanged: (value) {
              //               name = value;
              //             },
              //             focusNode: nameFocusNode,
              //           ),
              //         ),
              //         margin: EdgeInsets.only(left: 30.0, right: 30.0)),

              //     Container(
              //       child: Text("Email: ",
              //           style: TextStyle(
              //               fontStyle: FontStyle.italic,
              //               fontWeight: FontWeight.bold,
              //               color: Colors.lightBlueAccent)),
              //       margin: EdgeInsets.only(left: 10.0, bottom: 5.0, top: 10.0),
              //     ),

              //     Container(
              //         child: Theme(
              //           data: Theme.of(context)
              //               .copyWith(primaryColor: Colors.lightBlueAccent),
              //           child: TextField(
              //             readOnly: true,
              //             decoration: InputDecoration(
              //                 hintText: "Email",
              //                 contentPadding: EdgeInsets.all(5.0),
              //                 hintStyle: TextStyle(color: Colors.grey)),
              //             controller: emailTextEditingController,
              //             focusNode: emailFocusNode,
              //           ),
              //         ),
              //         margin: EdgeInsets.only(left: 30.0, right: 30.0))
              //   ],
              //   crossAxisAlignment: CrossAxisAlignment.start,
              // ),

              // Container(
              //   child: FlatButton(
              //     onPressed: updateData,
              //     child: Text(
              //       "Update",
              //       style: TextStyle(fontSize: 16.0),
              //     ),
              //     color: Colors.lightBlueAccent,
              //     highlightColor: Colors.grey,
              //     splashColor: Colors.transparent,
              //     textColor: Colors.white,
              //     padding: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
              //   ),
              //   margin: EdgeInsets.only(top: 50.0, bottom: 1.0),
              // ),

              // Padding(
              //   padding: EdgeInsets.only(left: 50.0, right: 50.0),
              //   child: RaisedButton(
              //     color: Colors.red,
              //     onPressed: logoutuser,
              //     child: Text(
              //       "Logout",
              //       style: TextStyle(color: Colors.white, fontSize: 14.0),
              //     ),
              //   ),
              // )
            ],
          ),
          padding: EdgeInsets.only(left: 15.0, right: 15.0),
        )
      ],
    );
  }

  @override
  Widget test(BuildContext context) {
    return new Scaffold(
        body: new Container(
      color: Colors.white,
      child: new ListView(
        children: <Widget>[
          Column(
            children: <Widget>[],
          ),
        ],
      ),
    ));
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    myFocusNode.dispose();
    super.dispose();
  }

  Widget _getActionButtons() {
    return Padding(
      padding: EdgeInsets.only(left: 25.0, right: 25.0, top: 45.0),
      child: new Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 10.0),
              child: Container(
                  child: new RaisedButton(
                child: new Text("Update"),
                textColor: Colors.white,
                color: Colors.green,
                onPressed: () {
                  setState(() {
                    _status = true;
                    FocusScope.of(context).requestFocus(new FocusNode());
                  });
                  updateData();
                },
                shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(20.0)),
              )),
            ),
            flex: 2,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Container(
                  child: new RaisedButton(
                child: new Text("Cancel"),
                textColor: Colors.white,
                color: Colors.red,
                onPressed: () {
                  setState(() {
                    _status = true;
                    FocusScope.of(context).requestFocus(new FocusNode());
                  });
                  // logoutuser();
                },
                shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(20.0)),
              )),
            ),
            flex: 2,
          ),
        ],
      ),
    );
  }

  Widget _getEditIcon() {
    return new GestureDetector(
      child: new CircleAvatar(
        backgroundColor: Colors.red,
        radius: 14.0,
        child: new Icon(
          Icons.edit,
          color: Colors.white,
          size: 16.0,
        ),
      ),
      onTap: () {
        setState(() {
          _status = false;
        });
      },
    );
  }
}
