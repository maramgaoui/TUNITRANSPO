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
      iconKey: 'bus',
      departure: '14:30',
      arrival: '16:45',
      departureStation: 'Tunis Centre',
      arrivalStation: 'Hammamet',
      transferStation: 'Nabeul',
      transferTime: '15:45',
      duration: '2h 15m',
      price: '4.500',
      transfers: 1,
      isOptimal: true,
      operator: 'SNTRI',
      line: 'Ligne 7',
    ),
    Journey(
      type: 'Métro',
      iconKey: 'metro',
      departure: '14:50',
      arrival: '17:20',
      departureStation: 'Bab Alioua',
      arrivalStation: 'La Marsa',
      transferStation: 'Tunis Marine',
      transferTime: '15:40',
      duration: '2h 30m',
      price: '3.750',
      transfers: 2,
      isOptimal: false,
      operator: 'SMTC',
      line: 'M1 → M4',
    ),
    Journey(
      type: 'Louage',
      iconKey: 'taxi',
      departure: '14:35',
      arrival: '15:50',
      departureStation: 'Tunis Centre',
      arrivalStation: 'Sousse',
      duration: '1h 15m',
      price: '15.000',
      transfers: 0,
      isOptimal: false,
      operator: 'Uber',
      line: 'Direct',
    ),
    Journey(
      type: 'Combiné',
      iconKey: 'train',
      departure: '15:00',
      arrival: '16:30',
      departureStation: 'Tunis Ville',
      arrivalStation: 'La Goulette',
      transferStation: 'Tunis Marine',
      transferTime: '15:40',
      duration: '1h 30m',
      price: '6.250',
      transfers: 1,
      isOptimal: false,
      operator: 'SNTRI + SMTC',
      line: 'Bus L5 → TGM',
    ),
  ];
}
