import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _key = 'favorite_pokemon';
  final SharedPreferences _prefs;
  
  FavoritesService(this._prefs);
  
  Future<List<int>> getFavorites() async {
    final String? favoritesString = _prefs.getString(_key);
    if (favoritesString == null || favoritesString.isEmpty) return [];
    return favoritesString.split(',').map((e) => int.parse(e)).toList();
  }
  
  Future<void> toggleFavorite(int pokemonId) async {
    final favorites = await getFavorites();
    if (favorites.contains(pokemonId)) {
      favorites.remove(pokemonId);
    } else {
      favorites.add(pokemonId);
    }
    await _prefs.setString(_key, favorites.join(','));
  }
  
  Future<bool> isFavorite(int pokemonId) async {
    final favorites = await getFavorites();
    return favorites.contains(pokemonId);
  }
}