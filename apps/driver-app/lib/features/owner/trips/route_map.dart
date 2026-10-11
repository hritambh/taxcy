import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme.dart';
import '../../../core/api/models.dart';

/// Whether to load OpenStreetMap tiles (off in widget tests, which have no network).
final mapTilesProvider = Provider<bool>((ref) => true);

/// A trip's GPS route on OpenStreetMap raster tiles (as in the admin web), with
/// pickup and drop pins when the trip has them.
class RouteMap extends ConsumerWidget {
  const RouteMap({required this.points, this.from, this.to, super.key});

  final List<(double, double)> points;
  final GeoPoint? from;
  final GeoPoint? to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final line = [for (final (lat, lng) in points) LatLng(lat, lng)];
    final pins = [
      if (from != null) (LatLng(from!.lat, from!.lng), Colors.green.shade700),
      if (to != null) (LatLng(to!.lat, to!.lng), Colors.red.shade700),
    ];
    final all = [...line, for (final (p, _) in pins) p];
    if (all.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 260,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: all.length == 1
                ? null
                : CameraFit.coordinates(
                    coordinates: all,
                    padding: const EdgeInsets.all(28),
                  ),
            initialCenter: all.first,
            initialZoom: 13,
          ),
          children: [
            if (ref.watch(mapTilesProvider))
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.taxcy.app',
              ),
            if (line.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: line,
                    strokeWidth: 4,
                    color: TaxcyColors.blue700,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final (point, color) in pins)
                  Marker(
                    point: point,
                    child: Icon(Icons.location_on, color: color, size: 30),
                  ),
              ],
            ),
            // OSM's tile policy asks for visible attribution.
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                color: Colors.white70,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: const Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
