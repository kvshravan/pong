import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pingpong/exit-popup.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController textFieldController = TextEditingController();

  bool isLoading = true;
  List userDataList = [];
  bool foundMatch = false;
  bool searching = false;
  String opponentId = '';
  var gameListener;
  var requestListener;
  var activeUserListener;

  final textStyle = GoogleFonts.openSans(
    color: Colors.black,
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );
  final boldtextStyle = GoogleFonts.openSans(
    color: Colors.black,
    fontWeight: FontWeight.normal,
    fontSize: 18,
  );
  final whiteboldtextStyle = GoogleFonts.openSans(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      getUserData(uid);
      detectPresence(uid);
    }
  }

  void detectPresence(String uid) async {
    final connectedRef = FirebaseDatabase.instance.ref('.info/connected');
    final userstatusRef =
        FirebaseDatabase.instance.ref('users').child(uid).child('status');
    connectedRef.onValue.listen((event) {
      print(" In detect presence");
      if (event.snapshot.value == true) {
        setStatusOnline(uid);
        userstatusRef.onDisconnect().set(false);
      }
    });
  }

  void setStatusOnline(String uid) async {
    if (uid != null) {
      await FirebaseDatabase.instance
          .ref('activeUsers/notPlaying')
          .update({uid: true});
      await FirebaseDatabase.instance
          .ref('users')
          .child(uid)
          .update({'status': true});
    }
  }

  void setStatusSearching() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseDatabase.instance
          .ref('activeUsers/searching')
          .update({uid: userDataList[1]});
    }
  }

  void signOut() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseDatabase.instance
          .ref('activeUsers/notPlaying')
          .child(uid)
          .remove();
      await FirebaseDatabase.instance
          .ref('activeUsers/isPlaying')
          .child(uid)
          .remove();
    }
    await FirebaseAuth.instance.signOut();
  }

  void getUserData(String uid) async {
    final ref = FirebaseDatabase.instance.ref();
    List lst = [];
    if (uid != null) {
      final snapshot = await ref.child('users').child(uid).get();
      if (snapshot.exists) {
        userDataList.add(snapshot.child('name').value);
        userDataList.add(snapshot.child('level').value);
        userDataList.add(snapshot.child('rank').value);
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void listenForRequests(String uid) async {
    final matchRequestref =
        FirebaseDatabase.instance.ref('users').child(uid).child('match');
    requestListener = matchRequestref.onValue.listen((event) {
      final playerId = event.snapshot.value;
      if (playerId != null && playerId != uid) {
        foundMatch = true;
        gameListener.cancel();
        requestListener.cancel();
      }
    });
  }

  Future<bool> findaPlayer(String uid) async {
    var minDistanceuid = "";
    var minDistance = -1;
    final activeRef = FirebaseDatabase.instance.ref('activeUsers/searching');
    final levelSnapshot = await FirebaseDatabase.instance
        .ref('users')
        .child(uid)
        .child('level')
        .get();
    int userLevel = int.parse(levelSnapshot.value.toString());
    activeUserListener = activeRef.onValue.listen((event) async {
      if (!searching) {
        searching = true;
        if (event.snapshot.exists) {
          for (var opp in event.snapshot.children) {
            if (opp.key != uid && opp.value != null) {
              int oppLevel = int.parse(opp.value.toString());
              int diff = (oppLevel - userLevel).abs();
              if (diff <= 2) {
                await setOpponent(uid, opp.key);
                releaseLock();
                activeUserListener.cancel();
                break;
              }
              if (minDistance == -1) {
                minDistance = diff;
                minDistanceuid = opp.key!;
              } else if (diff < minDistance) {
                minDistance = diff;
                minDistanceuid = opp.key!;
              }
            }
          }
          if (minDistance != -1) {
            await setOpponent(uid, minDistanceuid);
            releaseLock();
            activeUserListener.cancel();
          }
        } else {
          print('No match found');
        }
        searching = false;
      }
    });
    return false;
  }

  Future<bool> setOpponent(uid, oppuid) async {
    await FirebaseDatabase.instance
        .ref('users')
        .child(oppuid)
        .child('match')
        .set(uid);
    await FirebaseDatabase.instance
        .ref('users')
        .child(uid)
        .child('match')
        .set(oppuid);
    return true;
  }

  void releaseLock() async {
    await FirebaseDatabase.instance.ref('lock').set('available');
  }

  void removeRequestspath(String uid) async {
    await FirebaseDatabase.instance
        .ref('users')
        .child(uid)
        .child('match')
        .remove();
  }

  Future<bool> searchForGame() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      foundMatch = false;
      removeRequestspath(uid);
      listenForRequests(uid);
      setStatusSearching();
      // get the lock
      final lockRef = FirebaseDatabase.instance.ref('lock');
      gameListener = lockRef.onValue.listen((event) async {
        final lockStatus = event.snapshot.value;
        if (lockStatus != null && !foundMatch) {
          if (lockStatus == "available") {
            setLock(uid);
          } else if (lockStatus == uid) {
            lockRef.onDisconnect().set("available");
            await findaPlayer(uid);
          }
        }
      });
    }
    return false;
  }

  void setLock(String uid) async {
    await FirebaseDatabase.instance.ref('lock').set(uid);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => showExitPopup(context),
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () {
                signOut();
              },
              color: Colors.black,
              focusColor: Colors.blue,
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Logout',
            )
          ],
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.white,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20))),
          elevation: 2.0,
          backgroundColor: Colors.grey[300],
        ),
        backgroundColor: Colors.grey[300],
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Container(
                padding: EdgeInsets.all(10),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                          width: 0.9 * MediaQuery.of(context).size.width,
                          height: 150,
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 8,
                            shadowColor: Colors.black,
                            child: Container(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Name:',
                                          style: textStyle,
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          userDataList[0].toString(),
                                          style: boldtextStyle,
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Level:',
                                          style: textStyle,
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          userDataList[1].toString(),
                                          style: boldtextStyle,
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Rank:',
                                          style: textStyle,
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          userDataList[2].toString(),
                                          style: boldtextStyle,
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Status:',
                                          style: textStyle,
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          'Online',
                                          style: boldtextStyle,
                                        ),
                                      ],
                                    ),
                                  ]),
                            ),
                          )),
                      SizedBox(
                        height: 10,
                      ),
                      MaterialButton(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          color: Colors.green,
                          minWidth: 0.9 * MediaQuery.of(context).size.width,
                          height: 60,
                          onPressed: () async {
                            await searchForGame();
                            print(opponentId);
                          },
                          child: Text(
                            'Search for a game',
                            style: whiteboldtextStyle,
                          )),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
