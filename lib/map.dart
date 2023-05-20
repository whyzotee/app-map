import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
  final String address = 'ต.สุเทพ อำเภอเมืองเชียงใหม่ จังหวัดเชียงใหม่ 50200';

  final _mapController = MapController();
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
      mapProvider.updateSelfPosition(LatLng(value.latitude, value.longitude));
      mapProvider.updateMarkerPosition(LatLng(value.latitude, value.longitude));
    });
  }

  @override
  Widget build(BuildContext context) {
    var mapProvider = context.read<MapProvider>();
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: const Text(
            'ยืนยันตำแหน่งที่อยู่',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                mapProvider.centerMap = null;
                Navigator.of(context).pop();
              },
              child: const Text(
                'เอาไว้ก่อน',
                style: TextStyle(color: Color(0xFFFF4201), fontSize: 16),
              ),
            )
          ],
          centerTitle: false,
        ),
        body: SafeArea(
          child: Column(
            children: [Expanded(child: expandedMap()), bottomWidget()],
          ),
        ),
      ),
    );
  }

  Widget expandedMap() {
    var mapProvider = context.read<MapProvider>();
    return Consumer(
        builder: (BuildContext context, MapProvider value, Widget? child) {
      if (value.selfPosition == null) return Container();
      return Stack(
        children: [
          mapWidget(),
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: () {
                _mapController.move(mapProvider.selfPosition!, 18);
              },
              child: Container(
                padding: const EdgeInsets.all(5),
                margin: const EdgeInsets.only(bottom: 10, right: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.grey),
                ),
                child: const Icon(Icons.add_location_alt_outlined),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 20),
            alignment: Alignment.topCenter,
            child: Text(
              'Latitude: ${value.centerMap!.latitude}\nLongitude: ${value.centerMap!.longitude}',
            ),
          )
        ],
      );
    });
  }

  Widget mapWidget() {
    var mapProvider = context.read<MapProvider>();
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        center: mapProvider.selfPosition,
        zoom: 18,
        minZoom: 15,
        maxZoom: 18,
        onPointerDown: (event, point) {
          if (FocusScope.of(context).hasFocus) {
            FocusScope.of(context).unfocus();
          }
        },
        onPositionChanged: (position, hasGesture) {
          mapProvider.updateMarkerPosition(position.center!);
          if (FocusScope.of(context).hasFocus) {
            FocusScope.of(context).unfocus();
          }
        },
      ),
      children: [
        TileLayer(
          minZoom: 15,
          maxZoom: 18,
          minNativeZoom: 15,
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
                // ตัวเช็คตรงกลางของ Lat Lng
                //  if (value.selfPosition != null)
                //   Marker(
                //     point: value.selfPosition!,
                //     builder: ((context) {
                //       return Icon(
                //         Icons.circle,
                //         size: 5,
                //       );
                //     }),
                //   ),
                if (value.selfPosition != null)
                  Marker(
                    point: value.selfPosition!,
                    builder: ((context) {
                      return Stack(
                        alignment: AlignmentDirectional.center,
                        children: [
                          FractionalTranslation(
                            translation: const Offset(-2, -2),
                            child: Icon(
                              Icons.circle,
                              color: Colors.blue.withOpacity(0.2),
                              size: 150,
                            ),
                          ),
                          const Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 30,
                          ),
                          const Icon(
                            Icons.circle,
                            color: Colors.lightBlue,
                            size: 20,
                          ),
                        ],
                      );
                    }),
                  ),
                if (value.selfPosition != null)
                  Marker(
                    point: value.centerMap!,
                    anchorPos: AnchorPos.align(AnchorAlign.top),
                    builder: ((context) {
                      return SvgPicture.asset(
                        'assets/images/marker.svg',
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
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

  Widget bottomWidget() {
    var mapProvider = context.read<MapProvider>();
    return Container(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 40,
                width: double.infinity,
                child: TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.only(bottom: 0),
                    fillColor: Colors.grey[200],
                    filled: true,
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFFFF4201),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
              ),
              child: const Text(
                'ค้นหา',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          ]),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 5),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: Colors.grey[300]),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFFF4201),
                ),
              ),
              Expanded(
                child: Text(
                  address,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  mapProvider.centerMap = null;
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'ย้อนกลับ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  mapProvider.centerMap = null;
                  final LatLng center = _mapController.center;
                  Navigator.pop(context, center);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4201),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 25,
                  ),
                  child: Text('บันทึก'),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
