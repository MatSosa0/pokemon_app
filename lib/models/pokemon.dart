class Pokemon {
  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;
  final int height;
  final int weight;
  final Map<String, int> stats;

  Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
    this.height = 0,
    this.weight = 0,
    this.stats = const {},
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('url')) {
      // This is from the list endpoint
      final id = int.parse(json['url'].split('/')[6]);
      return Pokemon(
        id: id,
        name: json['name'],
        imageUrl: 'https://pokeapi.co/media/sprites/pokemon/other/official-artwork/$id.png',
        types: const [], // Types will be filled when getting detailed info
      );
    } else {
      // This is from the detail endpoint
      final Map<String, int> stats = {};
      for (var stat in json['stats'] as List) {
        stats[stat['stat']['name']] = stat['base_stat'] as int;
      }
      
      return Pokemon(
        id: json['id'],
        name: json['name'],
        imageUrl: json['sprites']['other']['official-artwork']['front_default'] ?? 
                  'https://pokeapi.co/media/sprites/pokemon/other/official-artwork/${json['id']}.png',
        types: (json['types'] as List)
            .map((type) => type['type']['name'] as String)
            .toList(),
        height: json['height'],
        weight: json['weight'],
        stats: stats,
      );
    }
  }
}