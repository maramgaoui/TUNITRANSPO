import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/station_model.dart';

class RouteMapWidget extends StatefulWidget {
  /// List of stations to display on the map (should be in order along the route)
  final List<Station> stations;
  
  /// Optional title for the map
  final String? title;
  
  /// Optional callback when a station marker is tapped
  final Function(Station station)? onStationTapped;
  
  /// Initial zoom level
  final double initialZoom;

  const RouteMapWidget({
    super.key,
    required this.stations,
    this.title,
    this.onStationTapped,
    this.initialZoom = 12.0,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  late MapController _mapController;
  late LatLng _centerPoint;
  late List<LatLng> _routePoints;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _routePoints = widget.stations
        .map((station) => LatLng(station.latitude, station.longitude))
        .toList();
    _centerPoint = _calculateCenter(_routePoints);
  }

  /// Calculate the center point of all stations
  LatLng _calculateCenter(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLng(36.8, 10.2); // Default Tunisia center
    }
    double lat = 0, lng = 0;
    for (final point in points) {
      lat += point.latitude;
      lng += point.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  /// Build polyline for the route
  Polyline _buildRouteLine() {
    return Polyline(
      points: _routePoints,
      color: Colors.blue.shade600,
      strokeWidth: 3.0,
      isDotted: false,
    );
  }

  /// Build markers for all stations
  List<Marker> _buildStationMarkers() {
    return List.generate(widget.stations.length, (index) {
      final station = widget.stations[index];
      final isFirst = index == 0;
      final isLast = index == widget.stations.length - 1;
      
      // Different colors for start, end, and intermediate stations
      Color markerColor;
      IconData iconData;
      if (isFirst) {
        markerColor = Colors.green;
        iconData = Icons.location_on;
      } else if (isLast) {
        markerColor = Colors.red;
        iconData = Icons.location_on;
      } else {
        markerColor = Colors.blue;
        iconData = Icons.circle;
      }

      return Marker(
        point: LatLng(station.latitude, station.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            widget.onStationTapped?.call(station);
            _showStationInfo(station);
          },
          child: Container(
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              iconData,
              color: Colors.white,
              size: isFirst || isLast ? 24 : 12,
            ),
          ),
        ),
      );
    });
  }

  /// Show station information in a bottom sheet
  void _showStationInfo(Station station) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (station.nameAr != null)
                        Text(
                          station.nameAr!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (station.address != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.home, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        station.address!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${station.latitude.toStringAsFixed(4)}, ${station.longitude.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (station.transportTypes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  spacing: 8,
                  children: station.transportTypes
                      .map((type) => Chip(
                            label: Text(type),
                            backgroundColor: Colors.blue.shade100,
                            labelStyle: const TextStyle(fontSize: 12),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stations.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No stations available',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _centerPoint,
            initialZoom: widget.initialZoom,
            minZoom: 5,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tunitransport.app',
              maxNativeZoom: 19,
            ),
            PolylineLayer(
              polylines: [_buildRouteLine()],
            ),
            MarkerLayer(
              markers: _buildStationMarkers(),
            ),
          ],
        ),
        // Top info bar
        if (widget.title != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Zoom controls
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton(
                mini: true,
                heroTag: 'zoomIn',
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  );
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                heroTag: 'zoomOut',
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  );
                },
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                heroTag: 'centerMap',
                onPressed: () {
                  _mapController.move(_centerPoint, widget.initialZoom);
                },
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
