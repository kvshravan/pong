import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pingpong/pages/home.dart';

class GamePage extends StatefulWidget {
  final String userid;
  final String opponentid;
  final String matchid;
  const GamePage(
      {Key? key,
      required this.userid,
      required this.opponentid,
      required this.matchid})
      : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  List userDataList = [];
  List oppDataList = [];
  String? winnerId;
  var isLoading = true;
  var matchListener;
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
    startMatchListener();
    getUserData(widget.userid);
    getOppData(widget.opponentid);
  }

  void getOppData(String uid) async {
    final ref = FirebaseDatabase.instance.ref();
    if (uid != null) {
      final snapshot = await ref.child('users').child(uid).get();
      if (snapshot.exists) {
        oppDataList.add(snapshot.child('name').value);
        oppDataList.add(snapshot.child('level').value);
        oppDataList.add(snapshot.child('rank').value);
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void getUserData(String uid) async {
    final ref = FirebaseDatabase.instance.ref();
    if (uid != null) {
      final snapshot = await ref.child('users').child(uid).get();
      if (snapshot.exists) {
        userDataList.add(snapshot.child('name').value);
        userDataList.add(snapshot.child('level').value);
        userDataList.add(snapshot.child('rank').value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () {},
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
                        height: 100,
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
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        userDataList[0].toString(),
                                        style: textStyle,
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                        ' vs ',
                                        style: textStyle,
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                        oppDataList[0].toString(),
                                        style: textStyle,
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Level ' + userDataList[1].toString(),
                                        style: textStyle,
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                        ' vs ',
                                        style: textStyle,
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                        'Level ' + oppDataList[1].toString(),
                                        style: textStyle,
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                ]),
                          ),
                        )),
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
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 8,
                      shadowColor: Colors.black,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                  child: Text(
                                'Who won the match?',
                                style: GoogleFonts.openSans(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: .2,
                                ),
                              )),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: RadioListTile(
                                  title: Text(
                                    userDataList[0].toString(),
                                    style: GoogleFonts.openSans(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      letterSpacing: .2,
                                    ),
                                  ),
                                  value: widget.userid,
                                  groupValue: winnerId,
                                  onChanged: (value) {
                                    setState(() {
                                      winnerId = value.toString();
                                    });
                                  }),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: RadioListTile(
                                  title: Text(
                                    oppDataList[0].toString(),
                                    style: GoogleFonts.openSans(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      letterSpacing: .2,
                                    ),
                                  ),
                                  value: widget.opponentid,
                                  groupValue: winnerId,
                                  onChanged: (value) {
                                    setState(() {
                                      winnerId = value.toString();
                                    });
                                  }),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: MaterialButton(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  color: Colors.green,
                                  minWidth:
                                      0.5 * MediaQuery.of(context).size.width,
                                  height: 50,
                                  onPressed: () async {
                                    bool winexists = await getMatchStatus();
                                    if (!winexists) {
                                      double newUserLevel, newOppLevel;
                                      int ulevel =
                                          int.parse(userDataList[1].toString());
                                      int olevel =
                                          int.parse(oppDataList[1].toString());
                                      if (winnerId == widget.userid) {
                                        newUserLevel =
                                            ulevel + (olevel / ulevel) * 0.5;
                                        newOppLevel = max(1,
                                            olevel - (olevel / ulevel) * 0.5);
                                      } else {
                                        newOppLevel =
                                            olevel + (ulevel / olevel) * 0.5;
                                        newUserLevel = max(1,
                                            ulevel - (ulevel / olevel) * 0.5);
                                      }
                                      await setNewUserLevels(
                                          newUserLevel.ceil(),
                                          newOppLevel.ceil());
                                    }
                                    await setWinner();
                                  },
                                  child: Text(
                                    'Submit',
                                    style: whiteboldtextStyle,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Future<bool> getMatchStatus() async {
    final snapshot = await FirebaseDatabase.instance
        .ref('matches')
        .child(widget.matchid)
        .child('winner')
        .get();
    if (snapshot.exists) {
      print('Winner already exists');
      return true;
    }
    return false;
  }

  setNewUserLevels(nulevel, nolevel) async {
    final ref = FirebaseDatabase.instance.ref('users');
    await ref.child(widget.userid).child('level').set(nulevel);
    await ref.child(widget.opponentid).child('level').set(nolevel);
  }

  startMatchListener() async {
    final matchStatusref = FirebaseDatabase.instance
        .ref('matches')
        .child(widget.matchid)
        .child('winner');
    print('In listener');
    matchListener = matchStatusref.onValue.listen((event) async {
      if (event.snapshot.exists) {
        print('In listener');
        print(widget.matchid);
        final userLevelSnapshot = await FirebaseDatabase.instance
            .ref('users')
            .child(widget.userid)
            .child('level')
            .get();
        print('hello');
        if (event.snapshot.value == widget.userid) {
          openDialog('You won :)', userLevelSnapshot.value);
        } else {
          openDialog('You lost :(', userLevelSnapshot.value);
        }
        matchListener.cancel();
      }
    });
  }

  openDialog(result, status) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              content: Text(
                'You are now in level ' + status.toString(),
                style: GoogleFonts.openSans(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: .2,
                ),
              ),
              title: Text(
                result,
                style: GoogleFonts.openSans(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: .2,
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => HomePage()));
                    },
                    child: Text('OK'))
              ],
            )).whenComplete(() => Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => HomePage())));
  }

  setWinner() async {
    await FirebaseDatabase.instance
        .ref('matches')
        .child(widget.matchid)
        .child('winner')
        .set(winnerId!.trim().toString());
  }
}
