class Station {
  Station({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.lat,
    required this.lng,
    required this.brand,
    required this.rating,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String city;
  final String address;
  final double lat;
  final double lng;
  final String brand;
  final double rating;
  bool isFavorite;
}

final mockStations = <Station>[
  Station(
    id: '1',
    name: 'PoCho City Station',
    city: 'Tashkent',
    address: 'Mustaqillik ko‘chasi, 10',
    lat: 41.3111,
    lng: 69.2797,
    brand: 'PoCho',
    rating: 4.8,
  ),
  Station(
    id: '2',
    name: 'Highway Fuel',
    city: 'Samarkand',
    address: 'Registon yo‘li, 25',
    lat: 39.6542,
    lng: 66.9597,
    brand: 'PoCho',
    rating: 4.6,
  ),
  Station(
    id: '3',
    name: 'Ring Road Gas',
    city: 'Tashkent',
    address: 'Halqa yo‘li, 55',
    lat: 41.3275,
    lng: 69.2817,
    brand: 'PoCho',
    rating: 4.4,
  ),
];












