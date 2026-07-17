import 'package:flutter_test/flutter_test.dart';
import 'package:zadart_flutter/bloc/bloc_utils.dart';

void main() {
  group('defaultStateHasChanged', () {
    test('reports inequality by ==', () {
      final changed = defaultStateHasChanged<int>();
      expect(changed(1, 1), isFalse);
      expect(changed(1, 2), isTrue);
    });
  });

  group('stateHasChanged', () {
    test('uses == when no predicate is given', () {
      final changed = stateHasChanged<int>();
      expect(changed(1, 1), isFalse);
      expect(changed(1, 2), isTrue);
    });

    test('uses a custom predicate when provided', () {
      // "Changed" means the parity flipped.
      final changed =
          stateHasChanged<int>(stateHasChanged: (a, b) => a.isEven != b.isEven);
      expect(changed(2, 4), isFalse); // both even
      expect(changed(2, 3), isTrue);
    });
  });

  group('selectedStateHasChanged', () {
    test('only reports changes to the selected slice', () {
      final changed = selectedStateHasChanged<(int, String), int>((s) => s.$1);
      expect(changed((1, 'a'), (1, 'b')), isFalse); // selected int unchanged
      expect(changed((1, 'a'), (2, 'a')), isTrue);
    });

    test('honors a custom comparator on the selected value', () {
      final changed = selectedStateHasChanged<(int, String), int>(
        (s) => s.$1,
        stateHasChanged: (a, b) => a.isEven != b.isEven,
      );
      expect(changed((2, 'a'), (4, 'a')), isFalse);
      expect(changed((2, 'a'), (3, 'a')), isTrue);
    });
  });
}
