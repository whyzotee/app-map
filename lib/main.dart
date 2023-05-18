import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'markmap.dart';
import 'providers/map-provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MapProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: 'Kanit'),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController subDistrictInput = TextEditingController();
  TextEditingController districtInput = TextEditingController();
  TextEditingController countyInput = TextEditingController();
  TextEditingController zipCodeInput = TextEditingController();

  String latLngfromAPI = '';

  Future fetchLatLngFromOSM() async {
    final String subDistrict = 'city=${subDistrictInput.text}';
    final String district = 'county=${districtInput.text}';
    final String county = 'state=${countyInput.text}';
    final String zipCode = 'postalcode=${zipCodeInput.text}';

    const String osmURL = 'https://nominatim.openstreetmap.org/?';

    final response = await http.get(
      Uri.parse(
        '$osmURL&country=ประเทศไทย&$zipCode&format=json&limit=1',
      ),
    );

    if (response.statusCode == 200) {
      print(response.body.toString());
      setState(() {
        latLngfromAPI = response.body.toString();
      });
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(latLngfromAPI),
            TextField(
              controller: subDistrictInput,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'ตำบล',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: districtInput,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'อำเภอ',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: countyInput,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'จังหวัด',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: zipCodeInput,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'รหัสไปรษณีย์',
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: fetchLatLngFromOSM,
                  child: const Text('get LatLng'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MarkMapPage(),
                      ),
                    );
                  },
                  child: const Text('mark Map'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
