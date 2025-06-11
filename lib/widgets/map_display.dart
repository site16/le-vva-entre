import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:location/location.dart';
import 'dart:math' as math;

class MapDisplay extends StatefulWidget {
  final CameraPosition? initialCameraPosition;
  final Set<Marker>? markers;
  final Set<Polygon>? polygons;
  final Set<Polyline>? polylines;
  final void Function(GoogleMapController controller)? onMapCreated;
  final MapType mapType;
  final bool enableCurrentLocation;

  const MapDisplay({
    Key? key,
    this.initialCameraPosition,
    this.markers,
    this.polygons,
    this.polylines,
    this.onMapCreated,
    this.mapType = MapType.normal,
    this.enableCurrentLocation = true,
  }) : super(key: key);

  @override
  State<MapDisplay> createState() => _MapDisplayState();
}

class _MapDisplayState extends State<MapDisplay> with SingleTickerProviderStateMixin {
  GoogleMapController? _controller;
  String? _mapStyle;
  LocationData? _currentLocation;
  LocationData? _lastLocation;
  final Location _locationService = Location();
  BitmapDescriptor? _customLocationIcon;

  AnimationController? _animationController;

  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _loadCustomLocationIcon();
    if (widget.enableCurrentLocation) {
      _getCurrentLocation();
      _listenLocationChanges();
    }
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _loadMapStyle() async {
    final style = await rootBundle.loadString('assets/map_style/map_style_dark.json');
    setState(() {
      _mapStyle = style;
    });
    if (_controller != null && _mapStyle != null) {
      _controller!.setMapStyle(_mapStyle);
    }
  }

  Future<void> _loadCustomLocationIcon() async {
    final BitmapDescriptor bitmap = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(60, 60)),
      'assets/images/deliveryman.png',
    );
    setState(() {
      _customLocationIcon = bitmap;
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    final location = await _locationService.getLocation();
    setState(() {
      _currentLocation = location;
      _lastLocation = location;
    });

    if (_controller != null && widget.initialCameraPosition == null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(location.latitude ?? 0, location.longitude ?? 0),
        ),
      );
    }
  }

  void _listenLocationChanges() {
    _locationService.onLocationChanged.listen((LocationData locationData) {
      // Detecta movimento
      bool moving = false;
      if (_lastLocation != null) {
        final double distance = _calculateDistance(
          _lastLocation!.latitude ?? 0,
          _lastLocation!.longitude ?? 0,
          locationData.latitude ?? 0,
          locationData.longitude ?? 0,
        );
        moving = distance > 1.0; // metros (ajuste o limiar se quiser)
      }

      setState(() {
        _currentLocation = locationData;
        _isMoving = moving;
        _lastLocation = locationData;
      });

      if (_controller != null) {
        _controller!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(locationData.latitude ?? 0, locationData.longitude ?? 0),
          ),
        );
      }

      if (moving) {
        _animationController?.repeat();
      } else {
        _animationController?.stop();
        _animationController?.reset();
      }
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // metros
    final double dLat = _deg2rad(lat2 - lat1);
    final double dLon = _deg2rad(lon2 - lon1);
    final double a = 
        math.sin(dLat/2) * math.sin(dLat/2) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
        math.sin(dLon/2) * math.sin(dLon/2); 
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a)); 
    final double distance = earthRadius * c;
    return distance;
  }

  double _deg2rad(double deg) {
    return deg * (math.pi/180);
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    if (_mapStyle != null) {
      _controller!.setMapStyle(_mapStyle);
    }
    if (widget.initialCameraPosition == null && _currentLocation != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentLocation!.latitude ?? 0, _currentLocation!.longitude ?? 0),
        ),
      );
    }
    if (widget.onMapCreated != null) {
      widget.onMapCreated!(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    CameraPosition initialPosition = widget.initialCameraPosition ??
        (_currentLocation != null
            ? CameraPosition(
                target: LatLng(_currentLocation!.latitude ?? 0, _currentLocation!.longitude ?? 0),
                zoom: 15,
              )
            : const CameraPosition(target: LatLng(0, 0), zoom: 2));

    // Markers do usuário
    final Set<Marker> customMarkers = Set.of(widget.markers ?? {});
    if (_currentLocation != null && _customLocationIcon != null && widget.enableCurrentLocation) {
      customMarkers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentLocation!.latitude ?? 0, _currentLocation!.longitude ?? 0),
          icon: _customLocationIcon!,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: initialPosition,
          markers: customMarkers,
          polygons: widget.polygons ?? <Polygon>{},
          polylines: widget.polylines ?? <Polyline>{},
          mapType: widget.mapType,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
        ),
        // Animação de "voltas" ao redor do entregador
        if (_currentLocation != null && _isMoving)
          AnimatedBuilder(
            animation: _animationController!,
            builder: (context, child) {
              // Pega a posição na tela do marker
              return IgnorePointer(
                child: CustomPaint(
                  painter: _PulsatingCirclePainter(
                    animationValue: _animationController!.value,
                  ),
                  child: Container(),
                ),
              );
            },
          ),
      ],
    );
  }
}

// Desenha círculos animados ao redor do entregador
class _PulsatingCirclePainter extends CustomPainter {
  final double animationValue;

  _PulsatingCirclePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Centralizar círculo (tela toda, mas normalmente o marker está no centro)
    final center = Offset(size.width / 2, size.height / 2);

    // Raio cresce e diminui conforme animação
    final double maxRadius = 60.0;
    final double minRadius = 40.0;
    final double radius = minRadius + (maxRadius - minRadius) * animationValue;

    final paint = Paint()
      ..color = const Color(0xFF009688).withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_PulsatingCirclePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}