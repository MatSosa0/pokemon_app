import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

class PokemonService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2';

  /// Get a list of pokemons. By default this returns lightweight objects
  /// (id, name, imageUrl) derived from the list endpoint to avoid making
  /// thousands of detail requests. Set [fetchDetails] to true to additionally
  /// fetch full detail for each pokemon (this will be done in batches).
  Future<List<Pokemon>> getPokemonList({int limit = 20, int offset = 0}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/pokemon?limit=$limit&offset=$offset'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'];
      List<Future<Pokemon>> pokemonFutures = results.map((result) async {
        final detailUrl = result['url'] as String;
        final detailResponse = await http.get(Uri.parse(detailUrl));
        
        if (detailResponse.statusCode == 200) {
          final pokemonData = jsonDecode(detailResponse.body);
          return Pokemon.fromJson(pokemonData);
        } else {
          throw Exception('Failed to load pokemon details');
        }
      }).toList();

      return await Future.wait(pokemonFutures);
    } else {
      throw Exception('Failed to load pokemon list');
    }
  }

  Future<Pokemon?> searchPokemon(String name) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pokemon/${name.toLowerCase()}'),
      );
      
      if (response.statusCode == 200) {
        final pokemonData = json.decode(response.body) as Map<String, dynamic>;
        return Pokemon.fromJson(pokemonData);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<Pokemon?> getPokemonById(int id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/pokemon/$id'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Pokemon.fromJson(data as Map<String, dynamic>);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}