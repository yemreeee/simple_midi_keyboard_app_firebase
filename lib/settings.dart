import 'package:cloud_firestore/cloud_firestore.dart';

class MidiSettings {
  String width;
  bool allowNote;
  DocumentReference? reference;

  MidiSettings.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['width'] != null),
        assert(map['allow_note'] != null),
        width = map['width'],
        allowNote = map['allow_note'];

  MidiSettings.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data()! as Map<String, dynamic>,
            reference: snapshot.reference);
}
