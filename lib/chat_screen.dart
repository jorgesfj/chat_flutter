import 'dart:io';

import 'package:chat/chat_messager.dart';
import 'package:chat/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final GlobalKey<ScaffoldState> _scaffolKey = GlobalKey<ScaffoldState>();

  final GoogleSignIn googleSignIn = GoogleSignIn();

  var _currentUser;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.userChanges().listen(
      (user) {
        setState(() {
          _currentUser = user;
        });
      }
    );
  }

  Future _getUsers() async {
    if(_currentUser != null) return _currentUser;

    try{
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

      final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken
      );

      final authResult = await FirebaseAuth.instance.signInWithCredential(credential);

      final user = authResult.user;

      return user;
    }catch(e) {
      return null;
    }
  }

  void _sendMessage({String? text, XFile? imgFile}) async {

    // final user = await _getUsers();

    // if( user == null ){
    //   _scaffolKey.currentState!.showSnackBar(
    //     SnackBar(content: Text("Não foi possível realizar o login"), backgroundColor: Colors.red,)
    //   );
    // }



    // Map<String, dynamic> data = {
    //   "uid": FirebaseAuth.instance.currentUser!.uid,
    //   "senderName": FirebaseAuth.instance.currentUser!.displayName,
    //   "senderPhotoUrl": FirebaseAuth.instance.currentUser!.photoURL,
    //   "time": Timestamp.now()
    // };

    Map<String, dynamic> data = {
      "time": Timestamp.now()
    };

    if(imgFile != null) {
      firebase_storage.UploadTask task = firebase_storage.FirebaseStorage.instance.ref().child(
          DateTime.now().millisecondsSinceEpoch.toString()
      ).putFile(File(imgFile.path));

      setState(() {
        _isLoading = true;
      });

      firebase_storage.TaskSnapshot taskSnapshot;
      taskSnapshot = await task.whenComplete(() => {});
      String url = await taskSnapshot.ref.getDownloadURL();
      data['imgUrl'] = url;

      setState(() {
        _isLoading = false;
      });
    }

    if(text!=null) data['text'] = text;

    FirebaseFirestore.instance.collection("messages").doc().set(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUser != null ? "Olá, ${_currentUser.displayName}": "Chat App" ),
        centerTitle: true,
        elevation: 0,
        actions: [IconButton(onPressed: () {
          FirebaseAuth.instance.signOut();
          googleSignIn.signOut();
          _scaffolKey.currentState!.showSnackBar(
            SnackBar(content: Text('Você saiu'))
          );
        }, icon: Icon(Icons.exit_to_app))],
      ),
      body: Column(
        children: <Widget>[
          Expanded(child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('messages').orderBy('time').snapshots(),
            builder: (context, snapshots) {
              switch(snapshots.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                return Center(
                  child: CircularProgressIndicator(),
                );
                default:
                  List<DocumentSnapshot> documents = snapshots.data!.docs.reversed.toList();
                  return ListView.builder(
                    itemCount: documents.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      return ChatMessage(documents[index].data() as dynamic, true);
                    },
                  );
              }
            },
            ),
          ),
          _isLoading ? LinearProgressIndicator() : Container(),
          TextComposer( 
            _sendMessage
          ) 
        ],
      ),
    );
  }
}
