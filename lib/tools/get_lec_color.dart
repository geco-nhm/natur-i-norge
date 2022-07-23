import 'package:flutter/material.dart';
import 'package:naturinorge_guide/db/nin_db.dart';

Color? getLecColor(NinMajorTypeLECData majorTypeLec) {
  switch (majorTypeLec.lecTypeId) {
    case 'dLEC':
      return Colors.red[700];
    case 'mLEC':
      return Colors.deepOrange[50];
    case 'iLEC':
      return Colors.orange[50];
    case 'uLEC':
      return Colors.grey[400];
    default:
      throw Exception('Unknown LEC type');
  }
}
