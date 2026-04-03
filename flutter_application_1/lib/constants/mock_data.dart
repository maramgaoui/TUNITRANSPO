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
      id: 'journey-1',
      departureStation: 'Tunis Centre',
      arrivalStation: 'Hammamet',
      departureTime: '14:30',
      price: '4.500',
      type: 'Bus',
      iconKey: 'bus',
      arrivalTime: '16:45',
      transferStation: 'Nabeul',
      transferTime: '15:45',
      duration: '2h 15m',
      transfers: 1,
      isOptimal: true,
      operator: 'SNTRI',
      line: 'Ligne 7',
    ),
    Journey(
      id: 'journey-2',
      departureStation: 'Bab Alioua',
      arrivalStation: 'La Marsa',
      departureTime: '14:50',
      price: '3.750',
      type: 'Métro',
      iconKey: 'metro',
      arrivalTime: '17:20',
      transferStation: 'Tunis Marine',
      transferTime: '15:40',
      duration: '2h 30m',
      transfers: 2,
      isOptimal: false,
      operator: 'SMTC',
      line: 'M1 → M4',
    ),
    Journey(
      id: 'journey-3',
      departureStation: 'Tunis Centre',
      arrivalStation: 'Sousse',
      departureTime: '14:35',
      price: '15.000',
      type: 'Louage',
      iconKey: 'taxi',
      arrivalTime: '15:50',
      duration: '1h 15m',
      transfers: 0,
      isOptimal: false,
      operator: 'Uber',
      line: 'Direct',
    ),
    Journey(
      id: 'journey-4',
      departureStation: 'Tunis Ville',
      arrivalStation: 'La Goulette',
      departureTime: '15:00',
      price: '6.250',
      type: 'Combiné',
      iconKey: 'train',
      arrivalTime: '16:30',
      transferStation: 'Tunis Marine',
      transferTime: '15:40',
      duration: '1h 30m',
      transfers: 1,
      isOptimal: false,
      operator: 'SNTRI + SMTC',
      line: 'Bus L5 → TGM',
    ),
  ];
}
