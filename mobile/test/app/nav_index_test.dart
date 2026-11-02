import 'package:flutter_test/flutter_test.dart';
import 'package:tepilog/app/router.dart';

void main() {
  // Bottom nav: map 0, trending 1, upload 2 (pushed, no branch), profile 3.
  // Shell branches: map 0, trending 1, profile 2.
  test('each branch lights its own nav item', () {
    expect(navIndexForBranch(0), 0);
    expect(navIndexForBranch(1), 1);
    expect(navIndexForBranch(2), 3);
  });

  test('nav items open the matching branch', () {
    expect(branchForNavIndex(0), 0);
    expect(branchForNavIndex(1), 1);
    expect(branchForNavIndex(3), 2);
  });
}
