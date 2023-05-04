import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapProvider extends ChangeNotifier {
  LatLng? centerMap;

  void updateMarkerPosition(MapPosition value) {
    centerMap = value.center;
    notifyListeners();
  }
}
