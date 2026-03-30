import 'package:flutter/material.dart';
import '../models/journey_model.dart';

/// Mock data for development and testing
class MockData {
  // Recent search places
  static const List<Map<String, String>> recentSearches = [
    {
      'route': 'Tunis Centre → Hammamet',
      'time': 'Hier à 14:30',
    },
    {
      'route': 'Sfax → Sousse',
      'time': 'Il y a 2 jours',
    },
    {
      'route': 'Kairouan → Monastir',
      'time': 'Il y a 5 jours',
    },
  ];

  // Mock journey results
  static final List<Journey> mockJourneys = [
    Journey(
      type: 'Bus',
      icon: Icons.directions_bus,
      departure: '14:30',
      arrival: '16:45',
      duration: '2h 15m',
      price: '4.500',
      transfers: 1,
      isOptimal: true,
      operator: 'SNTRI',
      line: 'Ligne 7',
    ),
    Journey(
      type: 'Métro',
      icon: Icons.directions_subway,
      departure: '14:50',
      arrival: '17:20',
      duration: '2h 30m',
      price: '3.750',
      transfers: 2,
      isOptimal: false,
      operator: 'SMTC',
      line: 'M1 → M4',
    ),
    Journey(
      type: 'Louage',
      icon: Icons.local_taxi,
      departure: '14:35',
      arrival: '15:50',
      duration: '1h 15m',
      price: '15.000',
      transfers: 0,
      isOptimal: false,
      operator: 'Uber',
      line: 'Direct',
    ),
    Journey(
      type: 'Combiné',
      icon: Icons.train,
      departure: '15:00',
      arrival: '16:30',
      duration: '1h 30m',
      price: '6.250',
      transfers: 1,
      isOptimal: false,
      operator: 'SNTRI + SMTC',
      line: 'Bus L5 → TGM',
    ),
  ];
}
