class AppConstants {
  static const String defaultLocalhost = '127.0.0.1:8080';
  static const String defaultAndroidEmulator = '10.0.2.2:8080';
  static const String defaultLanIP = '192.168.1.100:8080';

  static const List<DemoGift> availableGifts = [
    DemoGift(id: 'rose', name: 'Rose', icon: '🌹', coins: 10, points: 10),
    DemoGift(id: 'heart', name: 'Heart', icon: '💖', coins: 50, points: 50),
    DemoGift(id: 'diamond', name: 'Diamond', icon: '💎', coins: 100, points: 100),
    DemoGift(id: 'sports_car', name: 'Supercar', icon: '🏎️', coins: 500, points: 500),
    DemoGift(id: 'rocket', name: 'Rocket', icon: '🚀', coins: 1000, points: 1000),
  ];
}

class DemoGift {
  final String id;
  final String name;
  final String icon;
  final int coins;
  final int points;

  const DemoGift({
    required this.id,
    required this.name,
    required this.icon,
    required this.coins,
    required this.points,
  });
}
