import 'package:flutter/Material.dart'  ;

extension SpaceExt on num {
  SizedBox get verticalSpace => SizedBox(height: toDouble());
  SizedBox get horizontalSpace => SizedBox(width: toDouble());
}
