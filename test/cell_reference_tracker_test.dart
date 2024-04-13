import 'package:a1/a1.dart';
import 'package:test/test.dart';
import 'package:visicalc_engine/visicalc_engine.dart';

void main() {
  group('Cell Reference Tracker - base operations', () {
    CellReferenceTracker tracker = CellReferenceTracker();
    final testSet = {'ZZ1'.a1, 'XY23'.a1};
    setUp(() {
      tracker = CellReferenceTracker();
      tracker.addReferenceToCell('Z26'.a1, testSet.first);
      tracker.addReferenceToCell('Z26'.a1, testSet.last);
    });
    test(' add dependants', () async {
      tracker.addReferenceToCell('A1'.a1, testSet.first);
      tracker.addReferenceToCell('A1'.a1, testSet.last);
      expect(tracker['A1'.a1], containsAll(testSet));
    });
    test(' remove dependants', () async {
      tracker.removeReferenceToCell('Z26'.a1, 'XY23'.a1);
      expect(tracker['Z26'.a1], containsAll({'ZZ1'.a1}));

      tracker.removeReferenceToCell('Z26'.a1, 'ZZ1'.a1);
      expect(tracker.length, isZero);
    });
    test(' move dependants', () async {
      tracker.moveReferencesForCell('Z26'.a1, 'TT10'.a1);
      expect(tracker['TT10'.a1], containsAll(testSet));
      expect(tracker['Z26'.a1], isNull);
    });
    test(' move empty dependants', () async {
      tracker.moveReferencesForCell('A1'.a1, 'B1'.a1);
      expect(tracker['A1'.a1], isNull);
      expect(tracker['B1'.a1], isNull);
    });
    test(' keys', () async {
      expect(tracker.keys, containsAll({'Z26'}.a1));
    });

    test(' clear dependants', () async {
      tracker.clear();
      expect(tracker.length, isZero);
    });
    test(' clear dependants', () async {
      tracker.clear();
      expect(tracker.length, isZero);
    });
  });
}
