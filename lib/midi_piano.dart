import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_midi/flutter_midi.dart';
import 'package:tonic/tonic.dart';
import 'package:flutter/services.dart';

class MidiPiano extends StatefulWidget {
  const MidiPiano({super.key});

  @override
  State<MidiPiano> createState() => _MidiPianoState();
}

class _MidiPianoState extends State<MidiPiano>
    with SingleTickerProviderStateMixin {
  final _flutterMidi = FlutterMidi();
  @override
  initState() {
    _scrollController = ScrollController();
    // _scrollController.addListener(() async {
    //   setState(() {
    //     _offset = roundUp(_scrollController.offset);
    //   });

    //   if (kDebugMode) {
    //     print('Scroll Position $_offset');
    //   }
    //   await Future.delayed(
    //     const Duration(seconds: 10),
    //     () {
    //       if (kDebugMode) {
    //         print("Saved to firestore");
    //       }
    //       FirebaseFirestore.instance.runTransaction(((transaction) async =>
    //           transaction.update(documentReference, {
    //             'offset': offset.toString(),
    //             'single_control': singleControl
    //           })));
    //     },
    //   );
    // });
    _flutterMidi.unmute();
    rootBundle.load("assets/sounds/Piano.sf2").then((sf2) {
      _flutterMidi.prepare(sf2: sf2, name: "Piano.sf2");
    });

    _controller =
        AnimationController(duration: const Duration(seconds: 1), vsync: this);
    _animationBlack = ColorTween(begin: Colors.black, end: Colors.deepOrange)
        .animate(_controller)
      ..addListener(() {
        setState(() {
          // The state that has changed here is the animation object’s value.
        });
      });
    _animationWhite = ColorTween(begin: Colors.white, end: Colors.cyanAccent)
        .animate(_controller)
      ..addListener(() {
        setState(() {
          // The state that has changed here is the animation object’s value.
        });
      });
    super.initState();
  }

  int singleControl = 1;
  double get keyWidth => 80 + (80 * _widthRatio);
  double _widthRatio = 0.0;
  bool _showLabels = true;
  bool _keys = false;
  int _note = 0;
  double _offset = 0;
  late ScrollController _scrollController;

  late Animation<Color?> _animationBlack;
  late Animation<Color?> _animationWhite;
  late AnimationController _controller;
  late FirebaseFirestore db;
  late DocumentReference<Object?> documentReference;
  late TargetPlatform platform;

  void animateColor(bool toggle) {
    if (toggle) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  Color? changeColor(bool accidental) =>
      accidental ? _animationBlack.value : _animationWhite.value;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Piano',
      theme: ThemeData.dark(),
      home: body(),
    );
  }

  StreamBuilder<QuerySnapshot<Object?>> body() {
    db = FirebaseFirestore.instance;
    return StreamBuilder<QuerySnapshot>(
        stream: db.collection("midi_settings").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else {
            platform = Theme.of(context).platform;
            var midi = snapshot.data!.docChanges.asMap()[0]!.doc.data()
                as Map<String, dynamic>;
            _showLabels = midi['allow_note'];
            _widthRatio = double.parse(midi['width']);
            _keys = midi['change_theme'];
            _note = midi['note'];
            _offset = double.parse(midi['offset']);
            singleControl = midi['single_control'];

            if (singleControl == 0) {
              _flutterMidi.playMidiNote(midi: _note);
              singleControl = 1;
            }

            if (_keys) {
              animateColor(_keys);
            } else {
              animateColor(_keys);
            }

            if (_scrollController.hasClients) {
              _scrollController.animateTo(_offset,
                  duration: const Duration(seconds: 3),
                  curve: Curves.easeInOut);
              // _scrollController.jumpTo(double.parse(midi['offset']));
            }

            documentReference =
                snapshot.requireData.docChanges.asMap()[0]!.doc.reference;

            return Scaffold(
                appBar: AppBar(
                    backgroundColor: changeColor(true),
                    title:
                        Text("Key ${Pitch.fromMidiNumber(_note).toString()}")),
                drawer: Drawer(
                    child: SafeArea(
                        child: ListView(children: [
                  Container(height: 10.0),
                  const ListTile(title: Text("Change Width")),
                  Slider(
                      activeColor: Colors.redAccent,
                      inactiveColor: Colors.white,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      value: _widthRatio,
                      onChanged: (double value) {
                        singleControl = 1;
                        db.runTransaction((transaction) async => transaction
                                .update(documentReference, {
                              'width': value.toString(),
                              'single_control': singleControl
                            }));
                      }),
                  const Divider(),
                  ListTile(
                      title: const Text("Show Labels"),
                      trailing: Switch(
                          value: _showLabels,
                          onChanged: (bool value) {
                            singleControl = 1;
                            db.runTransaction(
                              (transaction) async {
                                return transaction.update(documentReference, {
                                  'allow_note': value,
                                  'single_control': singleControl
                                });
                              },
                            );
                          })),
                  const Divider(),
                  ListTile(
                      title: const Text("Change Key Colors"),
                      trailing: Switch(
                          value: _keys,
                          onChanged: (bool value) {
                            db.runTransaction((transaction) async {
                              singleControl = 1;
                              transaction.update(documentReference, {
                                'change_theme': value,
                                'single_control': singleControl
                              });
                            });
                          })),
                  const Divider(),
                  // const ListTile(title: Text("Change Keyboard Position")),
                  // Slider(
                  //   activeColor: Colors.yellowAccent,
                  //   inactiveColor: Colors.white,
                  //   min: 0.0,
                  //   max: 3372.0,
                  //   divisions: 100,
                  //   value: _offset,
                  //   onChanged: (value) {},
                  //   onChangeEnd: (value) {
                  //     singleControl = 1;
                  //     db.runTransaction((transaction) async => transaction
                  //             .update(documentReference, {
                  //           'offset': roundUp(value).toString(),
                  //           'single_control': singleControl
                  //         }));
                  //   },
                  // ),
                ]))),
                body: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollEndNotification) {
                        double value = roundUp(notification.metrics.pixels);
                        // if (value > 3372) {
                        //   value = 3372.0;
                        // } else if (value < 0) {
                        //   value = 0.0;
                        // }
                        // if (kDebugMode) {
                        //   print('Scroll Ended $value');
                        // }
                        singleControl = 1;
                        db.runTransaction((transaction) async => transaction
                                .update(documentReference, {
                              'offset': value.toString(),
                              'single_control': singleControl
                            }));
                      }
                      return true;
                    },
                    child: platform == TargetPlatform.iOS
                        ? MediaQuery.removePadding(
                            context: context,
                            removeLeft:
                                platform == TargetPlatform.iOS ? true : false,
                            removeRight:
                                platform == TargetPlatform.iOS ? true : false,
                            child: listViewWidget(),
                          )
                        : listViewWidget()));
          }
        });
  }

  ListView listViewWidget() {
    return ListView.builder(
      itemCount: 7,
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      itemBuilder: (BuildContext context, int index) {
        final int i = index * 12;
        return SafeArea(
          child: Stack(children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              _buildKey(24 + i, false),
              _buildKey(26 + i, false),
              _buildKey(28 + i, false),
              _buildKey(29 + i, false),
              _buildKey(31 + i, false),
              _buildKey(33 + i, false),
              _buildKey(35 + i, false),
            ]),
            Positioned(
                left: 0.0,
                right: 0.0,
                bottom: 100,
                top: 0.0,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: keyWidth * .5),
                      _buildKey(25 + i, true),
                      _buildKey(27 + i, true),
                      Container(width: keyWidth),
                      _buildKey(30 + i, true),
                      _buildKey(32 + i, true),
                      _buildKey(34 + i, true),
                      Container(width: keyWidth * .5),
                    ])),
          ]),
        );
      },
    );
  }

  Widget _buildKey(int midi, bool accidental) {
    singleControl = 1;
    final pitchName = Pitch.fromMidiNumber(midi).toString();
    final pianoKey = Stack(
      children: [
        Semantics(
            button: true,
            hint: pitchName,
            child: Material(
                borderRadius: borderRadius,
                color: changeColor(accidental),
                child: InkWell(
                  key: key(accidental.toString()),
                  splashColor: Colors.deepPurple,
                  borderRadius: borderRadius,
                  highlightColor: Colors.grey,
                  onTap: () {},
                  onTapDown: (_) => db.runTransaction((transaction) async {
                    singleControl = 0;
                    if (kDebugMode) {
                      print(key(accidental.toString()));
                    }
                    return transaction.update(documentReference,
                        {'note': midi, 'single_control': singleControl});
                  }),
                ))),
        Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 20.0,
            child: _showLabels
                ? Text(pitchName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: !accidental ? Colors.black : Colors.white))
                : Container()),
      ],
    );
    if (accidental) {
      return Container(
          width: keyWidth,
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          padding: EdgeInsets.symmetric(horizontal: keyWidth * .1),
          child: Material(
              elevation: 6.0,
              borderRadius: borderRadius,
              shadowColor: const Color(0x802196F3),
              child: pianoKey));
    }
    return Container(
        width: keyWidth,
        margin: const EdgeInsets.symmetric(horizontal: 2.0),
        child: pianoKey);
  }
}

double roundUp(double value) {
  return (value * 1).ceil() / 1;
}

ValueKey key(String keyName) {
  return ValueKey(keyName);
}

const BorderRadius borderRadius = BorderRadius.only(
    bottomLeft: Radius.circular(10.0), bottomRight: Radius.circular(10.0));
