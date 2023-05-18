import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import 'map.dart';

class MarkMapPage extends StatefulWidget {
  const MarkMapPage({super.key});

  @override
  State<MarkMapPage> createState() => _MarkMapPageState();
}

class _MarkMapPageState extends State<MarkMapPage> {
  MapController mapController = MapController();
  LatLng? userMark;

  Future<void> pushToMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPage()),
    );

    if (!mounted || result == null) return;

    log(result.toString());
    if (userMark != null) {
      mapController.move(result!, 18);
    }

    setState(() {
      userMark = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (userMark != null) Text('Your Select Position\n$userMark'),
          if (userMark != null)
            Container(
              height: 400,
              width: 800,
              margin: const EdgeInsets.only(top: 50),
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  center: userMark,
                  zoom: 18,
                  interactiveFlags: InteractiveFlag.none,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.app',
                  ),
                  MarkerLayer(
                    rotate: true,
                    markers: [
                      Marker(
                        point: userMark!,
                        anchorPos: AnchorPos.align(AnchorAlign.top),
                        builder: ((context) {
                          return const Icon(
                            Icons.person_pin_circle_rounded,
                            color: Colors.orange,
                            size: 40,
                          );
                        }),
                      ),
                    ],
                  )
                ],
              ),
            ),
          Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.only(top: 50),
            child: ElevatedButton(
              onPressed: () => pushToMap(),
              child: const Text(
                'Mark จุด',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
