import 'package:naturinorge_guide/db/db_adapters.dart';

class AxisBlock {
  final List<StandardSegmentAdapter> standardSegments;
  final MajorTypeLecAdapter lecAdapter;

  AxisBlock(this.standardSegments, this.lecAdapter);
}
