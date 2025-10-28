import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

class PokemonService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2';
  static const int _batchSize = 50; // Tamaño del lote más pequeño
  
  List<Map<String, dynamic>>? _pokemonListCache;
  Map<String, Pokemon> _pokemonDetailsCache = {};
  int _totalPokemon = 0;
  Future<List<Pokemon>> getPokemonList({int limit = 20, int offset = 0}) async {
    try {
      // Si no tenemos el caché inicial, obtenemos el total de Pokémon primero
      if (_pokemonListCache == null) {
        final countResponse = await http.get(
          Uri.parse('$_baseUrl/pokemon?limit=1'),
        );
        
        if (countResponse.statusCode == 200) {
          final data = jsonDecode(countResponse.body);
          _totalPokemon = data['count'] as int;
        }

        // Inicializamos la lista caché
        _pokemonListCache = [];
      }

      // Verificamos si necesitamos cargar más Pokémon
      if (_pokemonListCache!.length < offset + limit) {
        // Calculamos el siguiente lote a cargar
        final nextBatchOffset = _pokemonListCache!.length;
        final response = await http.get(
          Uri.parse('$_baseUrl/pokemon?limit=$_batchSize&offset=$nextBatchOffset'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final newResults = List<Map<String, dynamic>>.from(data['results']);
          _pokemonListCache!.addAll(newResults);
        }
      }

      // Obtenemos el subconjunto solicitado
      final requestedPokemon = _pokemonListCache!
          .skip(offset)
          .take(limit)
          .toList();

      final List<Pokemon> pokemons = [];
      for (var result in requestedPokemon) {
        final url = result['url'] as String;

        // Verificamos el caché primero
        if (_pokemonDetailsCache.containsKey(url)) {
          pokemons.add(_pokemonDetailsCache[url]!);
          continue;
        }

        try {
          await Future.delayed(const Duration(milliseconds: 250));
          final detailResponse = await http.get(Uri.parse(url));
          
          if (detailResponse.statusCode == 200) {
            final pokemon = Pokemon.fromJson(jsonDecode(detailResponse.body));
            _pokemonDetailsCache[url] = pokemon;
            pokemons.add(pokemon);
          }
        } catch (e) {
          print('Error loading pokemon details: $e');
        }
      }

      return pokemons;
    } catch (e) {
      print('Error loading pokemon list: $e');
      return [];
    }
  }

  Future<List<Pokemon>> searchPokemon(String query) async {
    if (query.isEmpty) return [];

    try {
      // Load and cache the full list only once
      if (_pokemonListCache == null) {
        final response = await http.get(
          Uri.parse('$_baseUrl/pokemon?limit=1000'),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _pokemonListCache = List<Map<String, dynamic>>.from(data['results']);
        }
      }

      if (_pokemonListCache != null) {
        final filteredResults = _pokemonListCache!
            .where((pokemon) => pokemon['name'].toString().toLowerCase().contains(query.toLowerCase()))
            .take(5)
            .toList();

        final List<Pokemon> pokemons = [];
        for (var result in filteredResults) {
          final url = result['url'] as String;
          
          // Check cache first
          if (_pokemonDetailsCache.containsKey(url)) {
            pokemons.add(_pokemonDetailsCache[url]!);
            continue;
          }

          try {
            // Add a small delay between requests to avoid rate limiting
            await Future.delayed(const Duration(milliseconds: 250));
            
            final detailResponse = await http.get(Uri.parse(url));
            if (detailResponse.statusCode == 200) {
              final pokemon = Pokemon.fromJson(jsonDecode(detailResponse.body));
              _pokemonDetailsCache[url] = pokemon; // Cache the result
              pokemons.add(pokemon);
            }
          } catch (e) {
            print('Error loading pokemon details: $e');
          }
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