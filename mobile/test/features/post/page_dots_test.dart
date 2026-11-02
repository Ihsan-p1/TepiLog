import 'package:flutter_test/flutter_test.dart';
import 'package:tepilog/features/post/presentation/widgets/photo_pager.dart';

void main() {
  test('every dot shows when there are seven or fewer photos', () {
    expect(dotWindowStart(0, 4, 5), 0);
  });

  test('the window stays put while the open dot moves inside it', () {
    // 20 photos, window 0..6: moving from 2 to 3 to 4 keeps the window.
    expect(dotWindowStart(0, 3, 20), 0);
    expect(dotWindowStart(0, 5, 20), 0);
  });

  test('the window slides only when the open dot reaches its edge', () {
    expect(dotWindowStart(0, 6, 20), 1);
    expect(dotWindowStart(5, 5, 20), 4);
    expect(dotWindowStart(0, 19, 20), 13);
    expect(dotWindowStart(13, 0, 20), 0);
  });
}
