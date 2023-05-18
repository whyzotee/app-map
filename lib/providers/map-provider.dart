import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapProvider extends ChangeNotifier {
  LatLng? centerMap;
  LatLng? selfPosition;

  void updateMarkerPosition(LatLng value) {
    centerMap = value;
    notifyListeners();
  }

  void updateSelfPosition(LatLng value) {
    selfPosition = value;
    notifyListeners();
  }
}
