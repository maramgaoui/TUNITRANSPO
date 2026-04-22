import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/station_model.dart';

/// A compact map preview widget for displaying a journey route
class JourneyMapPreviewWidget extends StatefulWidget {
  /// Starting station
  final Station? fromStation;
  
  /// Ending station
  final Station? toStation;
  
  /// Optional intermediate stations
  final List<Station>? intermediateStations;
  
  /// Height of the map
  final double height;
  
  /// Callback when the map is tapped
  final VoidCallback? onMapTapped;

  const JourneyMapPreviewWidget({
    super.key,
    this.fromStation,
    this.toStation,
    this.intermediateStations,
    this.height = 200,
    this.onMapTapped,
  });

  @override
  State<JourneyMapPreviewWidget> createState() =>
      _JourneyMapPreviewWidgetState();
}

class _JourneyMapPreviewWidgetState extends State<JourneyMapPreviewWidget> {
  late MapController _mapController;
  late List<LatLng> _routePoints;
  late LatLng _centerPoint;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _buildRoutePoints();
  }

  void _buildRoutePoints() {
    _routePoints = [];
    
    // Add start point
    if (widget.fromStation != null) {
      _routePoints.add(
        LatLng(widget.fromStation!.latitude, widget.fromStation!.longitude),
      );
    }
    
    // Add intermediate points
    if (widget.intermediateStations != null) {
      for (final station in widget.intermediateStations!) {
        _routePoints.add(LatLng(station.latitude, station.longitude));
      }
    }
    
    // Add end point
    if (widget.toStation != null) {
      _routePoints.add(
        LatLng(widget.toStation!.latitude, widget.toStation!.longitude),
      );
    }

    // Calculate center
    if (_routePoints.isNotEmpty) {
      double lat = 0, lng = 0;
      for (final point in _routePoints) {
        lat += point.latitude;
        lng += point.longitude;
      }
      _centerPoint = LatLng(lat / _routePoints.length, lng / _routePoints.length);
    } else {
      _centerPoint = LatLng(36.8, 10.2); // Default Tunisia center
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onMapTapped,
      child: Container(
        height: widget.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _centerPoint,
                initialZoom: 12.0,
                minZoom: 5,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tunitransport.app',
                ),
                if (_routePoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: Colors.blue.shade600,
                        strokeWidth: 3.0,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    // Start marker
                    if (widget.fromStation != null)
                      Marker(
                        point: LatLng(
                          widget.fromStation!.latitude,
                          widget.fromStation!.longitude,
                        ),
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    // End marker
                    if (widget.toStation != null)
                      Marker(
                        point: LatLng(
                          widget.toStation!.latitude,
                          widget.toStation!.longitude,
                        ),
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    // Intermediate markers
                    if (widget.intermediateStations != null)
                      ...widget.intermediateStations!.map(
                        (station) => Marker(
                          point:
                              LatLng(station.latitude, station.longitude),
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Icon(
                              Icons.circle,
                              color: Colors.blue,
                              size: 8,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            // Tap to view overlay
            if (widget.onMapTapped != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fullscreen, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'View Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
