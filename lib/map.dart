import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

import 'providers/map-provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _mapController = MapController();
  final centerMap = LatLng(18.75685320973088, 99.00227259388569);
  TextEditingController textController = TextEditingController();

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition();
  }

  Future createAlbum(String input) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.70:5555/main/api_get_address_choice/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'zip_code': input,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["error"] != '') return {"error": data["error"]};
      return {"data": data["data"]};
    } else {
      return {"error": response.statusCode};
    }
  }

  Future showDistrict(List data) {
    var screenSize = MediaQuery.of(context).size;
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text(
          'เลือกตำบลของคุณ',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          height: screenSize.height * 0.3,
          width: screenSize.width * 0.5,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: data.length,
            itemBuilder: (BuildContext context, int index) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context, index.toString());
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Text(
                      data[index]["name"],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'ยกเลิก'),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    var mapProvider = context.read<MapProvider>();
    _determinePosition().then((value) {
      mapProvider.selfPosition = LatLng(value.latitude, value.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    var mapProvider = context.read<MapProvider>();
    var screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Map'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          mapWidget(),
          Consumer(
            builder: (BuildContext context, MapProvider value, Widget? child) {
              return value.centerMap != null
                  ? Container(
                      margin: const EdgeInsets.only(top: 100, left: 100),
                      child: Text(
                        'Latitude: ${value.centerMap!.latitude}\nLongitude: ${value.centerMap!.longitude}',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Container();
            },
          ),
          Consumer(
            builder: (BuildContext context, MapProvider value, Widget? child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        color: Colors.white,
                        width: screenSize.width * 0.5,
                        child: TextField(
                          controller: textController,
                          onChanged: ((String value) async {}),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'รหัสไปรษณีย์',
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          String zipcode = textController.text;
                          if (zipcode.length != 5) return;
                          createAlbum(zipcode).then((value) {
                            if (value["data"] != null) {
                              showDistrict(value["data"]).then((index) {
                                int formatI = int.parse(index);
                                _mapController.move(
                                  LatLng(
                                    value["data"][formatI]["lat"],
                                    value["data"][formatI]["long"],
                                  ),
                                  18,
                                );
                              });
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(left: 20),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'ค้นหา',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(top: 50, bottom: 50),
                        child: ElevatedButton(
                          onPressed: () {
                            mapProvider.centerMap = null;
                            final LatLng center = _mapController.center;
                            Navigator.pop(context, center);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(20),
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(top: 50, bottom: 50),
                        child: ElevatedButton(
                          onPressed: () {
                            _mapController.move(
                              mapProvider.selfPosition!,
                              18,
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(20),
                            child: Icon(
                              Icons.person_pin_circle_rounded,
                              size: 30,
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              );
            },
          )
        ],
      ),
    );
  }

  Widget mapWidget() {
    var mapProvider = context.read<MapProvider>();
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        center: LatLng(18.75685320973088, 99.00227259388569),
        zoom: 18,
        minZoom: 18,
        maxZoom: 18,
        onPositionChanged: (position, hasGesture) {
          mapProvider.updateMarkerPosition(position.center!);
        },
      ),
      children: [
        TileLayer(
          minZoom: 18,
          maxZoom: 18,
          minNativeZoom: 18,
          maxNativeZoom: 18,
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.app',
        ),
        Consumer(
          builder: (BuildContext context, MapProvider value, Widget? child) {
            return MarkerLayer(
              rotate: true,
              markers: [
                if (value.selfPosition != null)
                  Marker(
                    point: value.selfPosition!,
                    builder: ((context) {
                      return const Icon(
                        Icons.account_circle_rounded,
                        color: Colors.lightBlue,
                        size: 40,
                      );
                    }),
                  ),
                Marker(
                  point: value.centerMap ?? centerMap,
                  anchorPos: AnchorPos.align(AnchorAlign.top),
                  builder: ((context) {
                    return const Icon(
                      Icons.location_on_sharp,
                      color: Colors.red,
                      size: 40,
                    );
                  }),
                ),
              ],
            );
          },
        )
      ],
    );
  }
}
