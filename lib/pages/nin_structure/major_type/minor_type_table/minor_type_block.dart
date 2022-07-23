import 'package:naturinorge_guide/db/db_adapters.dart';

class MinorTypeBlock {
  final String key;
  final int width;
  final int height;
  final MinorTypeScaledAdapter? minorTypeScaled;

  MinorTypeBlock(this.width, this.height, this.minorTypeScaled, this.key);
}
