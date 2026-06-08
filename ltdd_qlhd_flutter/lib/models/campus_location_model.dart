import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class CampusLocationModel {
  final String id;
  final String name;
  final String area;
  final String building;
  final String floor;
  final String description;
  final String note;
  final LatLng position;
  final IconData icon;

  CampusLocationModel({
    required this.id,
    required this.name,
    required this.area,
    required this.building,
    required this.floor,
    required this.description,
    required this.note,
    required this.position,
    required this.icon,
  });
}
