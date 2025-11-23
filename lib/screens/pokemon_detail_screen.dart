import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pokemon.dart';

class PokemonDetailScreen extends StatelessWidget {
  final Pokemon pokemon;

  const PokemonDetailScreen({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pokemon.name.toUpperCase()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.grey[200],
              child: Hero(
                tag: 'pokemon-${pokemon.id}',
                child: CachedNetworkImage(
                  imageUrl: pokemon.imageUrl,
                  height: 250,
                  fit: BoxFit.contain,
                  fadeInDuration: const Duration(milliseconds: 300),
                  fadeOutDuration: const Duration(milliseconds: 300),
                  memCacheHeight: 500,
                  maxWidthDiskCache: 1000,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.catching_pokemon,
                        size: 50,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error loading image',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      '#${pokemon.id.toString().padLeft(3, '0')}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: pokemon.types.map((type) {
                        return Chip(
                          label: Text(
                            type.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: _getTypeColor(type),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Physical characteristics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCharacteristic(
                        icon: Icons.height,
                        label: 'Height',
                        value: '${(pokemon.height * 0.1).toStringAsFixed(1)}m',
                      ),
                      _buildCharacteristic(
                        icon: Icons.monitor_weight,
                        label: 'Weight',
                        value: '${(pokemon.weight * 0.1).toStringAsFixed(1)}kg',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Stats',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Base Stats
                  ..._buildStatBars(pokemon.stats)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristic({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 65, 64, 64),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: Colors.grey[700]),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatBars(Map<String, int> stats) {
    final statNames = {
      'hp': 'HP',
      'attack': 'Attack',
      'defense': 'Defense',
      'special-attack': 'Sp. Atk',
      'special-defense': 'Sp. Def',
      'speed': 'Speed',
    };

    return stats.entries.map((stat) {
      final percentage = (stat.value / 255 * 100).clamp(0.0, 100.0);
      final color = _getStatColor(percentage);
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  statNames[stat.key] ?? stat.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  stat.value.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _getStatColor(double percentage) {
    if (percentage >= 70) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'grass':
        return Colors.green;
      case 'fire':
        return Colors.red;
      case 'water':
        return Colors.blue;
      case 'electric':
        return Colors.yellow[700]!;
      case 'psychic':
        return Colors.purple;
      case 'fighting':
        return Colors.orange[800]!;
      case 'rock':
        return Colors.brown;
      case 'ground':
        return Colors.brown[300]!;
      case 'flying':
        return Colors.indigo[200]!;
      case 'bug':
        return Colors.lightGreen;
      case 'poison':
        return Colors.deepPurple;
      case 'normal':
        return Colors.grey[400]!;
      case 'ghost':
        return Colors.deepPurple[300]!;
      case 'dragon':
        return Colors.indigo;
      case 'dark':
        return Colors.grey[800]!;
      case 'steel':
        return Colors.blueGrey;
      case 'fairy':
        return Colors.pink[200]!;
      case 'ice':
        return Colors.lightBlue[200]!;
      default:
        return Colors.grey;
    }
  }
}