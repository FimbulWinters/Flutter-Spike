import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Suitable for most situations
import 'package:flutter_map/plugin_api.dart'; // Only import if required functionality is not exposed by default
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:developer';
import 'package:open_route_service/open_route_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

Future<dynamic> fetchData() async {
  final response = await http.get(Uri.parse(
      'http://api.opentripmap.com/0.1/ru/places/bbox?lon_min=38.364285&lat_min=59.855685&lon_max=38.372809&lat_max=59.859052&kinds=churches&format=geojson&apikey=5ae2e3f221c38a28845f05b67151a6fbd4b50c63d0c9e3c163e67def'));

  return response.body;
}

Future<dynamic> fetchRoute() async {
  final OpenRouteService client = OpenRouteService(
      apiKey: '5b3ce3597851110001cf62489513c460675e42199a86c0f6d7133d72');

  double startLat = 37.4220698;
  double startLng = -122.0862784;
  double endLat = 37.4111466;
  double endLng = -122.0792365;

  final List<ORSCoordinate> routeCoordinates =
      await client.directionsRouteCoordsGet(
    startCoordinate: ORSCoordinate(latitude: startLat, longitude: startLng),
    endCoordinate: ORSCoordinate(latitude: endLat, longitude: endLng),
  );
  final List<LatLng> routePoints = routeCoordinates
      .map((coordinate) => LatLng(coordinate.latitude, coordinate.longitude))
      .toList();

  return routePoints;
}

class _MyHomePageState extends State<MyHomePage> {
  List<Marker> allMarkers = [];
  List<LatLng> linePoints = [];

  @override
  void initState() {
    super.initState();
    fetchData().then((value) {
      var parsed = json.decode(value);

      for (var i = 0; i < 60; i++) {
        allMarkers.add(Marker(
            point: LatLng(parsed["features"][i]["geometry"]["coordinates"][0],
                parsed["features"][i]["geometry"]["coordinates"][1]),
            builder: (context) => FlutterLogo()));
      }
    });
    fetchRoute().then((values) {
      print(values);
      linePoints.addAll(values);
    });
  }

  @override
  Widget build(BuildContext context) {
    // FutureBuilder<PointsOfInterest> (future: futureData , builder: ((context, snapshot) {

    // }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const <Widget>[
            DrawerHeader(
                decoration: BoxDecoration(color: Colors.orange),
                child: Text(
                  'Drawer Header',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ))
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text('This is a map that is showing (51.5, -0.9).'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  zoom: 3,
                ),
                nonRotatedChildren: [
                  AttributionWidget.defaultWidget(
                    source: 'OpenStreetMap contributors',
                    onSourceTapped: () {},
                  ),
                ],
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  ),
                  MarkerLayer(markers: allMarkers),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                          points: linePoints, color: Colors.red, strokeWidth: 5)
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
