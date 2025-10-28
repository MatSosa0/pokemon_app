import 'dart:convert';
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
      final List<Pokemon> pokemons = [];

      for (var result in results) {
        try {
          // Add a delay between requests to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 500));
          
          final detailUrl = result['url'] as String;
          final detailResponse = await http.get(Uri.parse(detailUrl));
          
          if (detailResponse.statusCode == 200) {
            final pokemonData = jsonDecode(detailResponse.body);
            pokemons.add(Pokemon.fromJson(pokemonData));
          }
        } catch (e) {
          print('Error loading pokemon details: $e');
        }
      }

      return pokemons;
    } else {
      throw Exception('Failed to load pokemon list');
    }
  }

  Future<List<Pokemon>> searchPokemon(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pokemon?limit=1000'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['results'];
        
        final filteredResults = results
            .where((pokemon) => pokemon['name'].toString().toLowerCase().contains(query.toLowerCase()))
            .take(5)
            .toList();

        final List<Pokemon> pokemons = [];
        for (var result in filteredResults) {
          try {
            final detailResponse = await http.get(Uri.parse(result['url']));
            if (detailResponse.statusCode == 200) {
              pokemons.add(Pokemon.fromJson(jsonDecode(detailResponse.body)));
            }
          } catch (e) {
            print('Error loading pokemon details: $e');
          }
          // Add a delay between requests to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 500));
        }
        return pokemons;
      }
    } catch (e) {
      print('Error searching pokemon: $e');
    }
    return [];
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