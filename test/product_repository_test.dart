import 'package:flutter_test/flutter_test.dart';
import 'package:uzaapp/data/local/uza_database.dart';

void main() {
  test('ShopType wholesale is defined for B2B filtering', () {
    expect(ShopType.wholesale, ShopType.values.lastWhere((t) => t.name == 'wholesale'));
  });
}
