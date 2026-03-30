import 'package:flutter/material.dart';

class Journey {
  final String type;
  final IconData icon;
  final String departure;
  final String arrival;
  final String duration;
  final String price;
  final int transfers;
  final bool isOptimal;
  final String operator;
  final String line;

  Journey({
    required this.type,
    required this.icon,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.price,
    required this.transfers,
    required this.isOptimal,
    required this.operator,
    required this.line,
  });
}
