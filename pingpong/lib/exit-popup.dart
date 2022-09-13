import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

void removeFromActiveUsers(searching) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    if (searching) {
      await FirebaseDatabase.instance.ref('lock').set('available');
    }
    await FirebaseDatabase.instance
        .ref('activeUsers/notPlaying')
        .child(uid)
        .remove();
    await FirebaseDatabase.instance
        .ref('activeUsers/isPlaying')
        .child(uid)
        .remove();
    await FirebaseDatabase.instance
        .ref('activeUsers/searching')
        .child(uid)
        .remove();
    await FirebaseDatabase.instance
        .ref('users')
        .child(uid)
        .child('status')
        .set(false);
  }
}

Future<bool> showExitPopup(context, searching) async {
  return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            height: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Do you want to exit?"),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          removeFromActiveUsers(searching);
                          exit(0);
                        },
                        child: Text("Yes"),
                        style: ElevatedButton.styleFrom(
                            primary: Colors.red.shade800),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                        child: ElevatedButton(
                      onPressed: () {
                        print('no selected');
                        Navigator.of(context).pop();
                      },
                      child: Text("No", style: TextStyle(color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white,
                      ),
                    ))
                  ],
                )
              ],
            ),
          ),
        );
      });
}
