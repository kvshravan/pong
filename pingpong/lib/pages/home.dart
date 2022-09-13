import 'dart:async';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pingpong/exit-popup.dart';
import 'package:pingpong/pages/game_page.dart';

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
  bool hasLock = false;
  String opponentId = '';
  String matchId = '';
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
    final notPlayingref =
        FirebaseDatabase.instance.ref('activeUsers/notPlaying').child(uid);
    final isPlayingref =
        FirebaseDatabase.instance.ref('activeUsers/isPlaying').child(uid);
    final searchingref =
        FirebaseDatabase.instance.ref('activeUsers/searching').child(uid);
    connectedRef.onValue.listen((event) {
      print(" In detect presence");
      if (event.snapshot.value == true) {
        setStatusOnline(uid);
        userstatusRef.onDisconnect().set(false);
        searchingref.onDisconnect().remove();
        notPlayingref.onDisconnect().remove();
        isPlayingref.onDisconnect().remove();
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
      await FirebaseDatabase.instance
          .ref('activeUsers/searching')
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

  void _navigatetoGame(uid, oppid, snapMatchId) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => GamePage(
                  userid: uid,
                  opponentid: oppid.toString().trim(),
                  matchid: snapMatchId,
                )));
  }

  void listenForRequests(String uid) async {
    final matchRequestref =
        FirebaseDatabase.instance.ref('users').child(uid).child('match');
    requestListener = matchRequestref.onValue.listen((event) async {
      final playerId = event.snapshot.value;
      if (playerId != null && playerId != uid) {
        foundMatch = true;
        final snapMatchId = await FirebaseDatabase.instance
            .ref('users')
            .child(uid)
            .child('matchid')
            .get();
        setState(() {
          isLoading = false;
        });
        _navigatetoGame(uid, playerId, snapMatchId.value);
        gameListener.cancel();
        requestListener.cancel();
      }
    });
  }

  startMatch(uid, oppid) async {
    final matchref = FirebaseDatabase.instance.ref('matches').push();
    matchId = matchref.key!;
    print(matchId);
    await matchref.child('one').set(uid);
    await matchref.child('two').set(oppid);
    await matchref.child('time').set(DateTime.now().millisecondsSinceEpoch);
    await FirebaseDatabase.instance
        .ref('users')
        .child(uid)
        .child('matchid')
        .set(matchId);
    await FirebaseDatabase.instance
        .ref('users')
        .child(oppid)
        .child('matchid')
        .set(matchId);
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
    await startMatch(uid, oppuid);
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
    await removePlayerFromSearching(oppuid);
    await removePlayerFromSearching(uid);
    return true;
  }

  removePlayerFromSearching(uid) async {
    await FirebaseDatabase.instance
        .ref('activeUsers/searching')
        .child(uid)
        .remove();
  }

  Future<bool> releaseLock() async {
    await FirebaseDatabase.instance.ref('lock').set('available');
    hasLock = false;
    return true;
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
      hasLock = false;
      removeRequestspath(uid);
      listenForRequests(uid);
      setStatusSearching();
      // get the lock
      final lockRef = FirebaseDatabase.instance.ref('lock');
      var userListener;
      gameListener = lockRef.onValue.listen((event) async {
        final lockStatus = event.snapshot.value;
        if (lockStatus != null && !foundMatch) {
          if (userListener != null) {
            userListener.cancel();
          }
          if (lockStatus == "available") {
            setLock(uid);
          } else if (lockStatus == uid) {
            hasLock = true;
            lockRef.onDisconnect().set("available");
            await findaPlayer(uid);
            lockRef.onDisconnect().cancel();
          } else {
            userListener = FirebaseDatabase.instance
                .ref('users')
                .child(lockStatus.toString().trim())
                .child('status')
                .onValue
                .listen((event) async {
              if (event.snapshot.value == false) {
                await releaseLock();
                userListener.cancel();
              }
            });
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
      onWillPop: () => showExitPopup(context, hasLock),
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.black),
          actions: [
            IconButton(
              onPressed: () async {
                if (!isLoading) {
                  setState(() {
                    isLoading = true;
                  });
                  userDataList = [];
                  getUserData(FirebaseAuth.instance.currentUser!.uid);
                }
              },
              color: Colors.black,
              focusColor: Colors.blue,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
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
                            setState(() {
                              isLoading = true;
                            });
                            await searchForGame();
                            print(opponentId);
                          },
                          child: Text(
                            'Search for a game',
                            style: whiteboldtextStyle,
                          )),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                            child: Text(
                          'Recent Matches :',
                          style: GoogleFonts.openSans(
                            color: Colors.green,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: .2,
                          ),
                        )),
                      ),
                      Expanded(
                        child: FutureBuilder<List>(
                          future: _getRecentMatches(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      width: 40,
                                      child: Divider(
                                        thickness: 3.0,
                                        height: 20,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ListView.builder(
                                        itemCount: snapshot.data!.length,
                                        itemBuilder: (context, index) {
                                          return Card(
                                              color: Colors.white60,
                                              shadowColor: Colors.white,
                                              child: ListTile(
                                                onTap: () {},
                                                title: Text(
                                                  snapshot.data![index]
                                                      ['match'],
                                                  style: GoogleFonts.openSans(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15,
                                                    letterSpacing: .2,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  DateFormat('dd-MMM, hh:mm a')
                                                      .format(DateTime
                                                          .fromMillisecondsSinceEpoch(
                                                              snapshot.data![
                                                                      index]
                                                                  ['time'])),
                                                  style: GoogleFonts.openSans(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 15,
                                                    letterSpacing: .2,
                                                  ),
                                                ),
                                              ));
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Center(child: CircularProgressIndicator());
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<List> _getRecentMatches() async {
    List recentMatches = [];
    final query = FirebaseDatabase.instance
        .ref('matches')
        .orderByChild('time')
        .limitToLast(10);
    final snapshot = await query.get();
    if (snapshot.exists) {
      for (var match in snapshot.children) {
        final opponentSnapshot = await FirebaseDatabase.instance
            .ref('users')
            .child(match.child('two').value.toString())
            .child('name')
            .get();
        final userSnapshot = await FirebaseDatabase.instance
            .ref('users')
            .child(match.child('one').value.toString())
            .child('name')
            .get();
        final matchString = opponentSnapshot.value.toString() +
            ' vs ' +
            userSnapshot.value.toString();
        recentMatches.add({
          'match': matchString,
          'time': int.parse(match.child('time').value.toString())
        });
      }
    }
    return recentMatches.reversed.toList();
  }
}
