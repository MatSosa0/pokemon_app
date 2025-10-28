import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'services/pokemon_service.dart';
import 'services/favorites_service.dart';
import 'models/pokemon.dart';
import 'screens/pokemon_detail_screen.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final favoritesService = FavoritesService(prefs);
  final themeProvider = ThemeProvider(prefs);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeProvider),
        Provider<FavoritesService>.value(value: favoritesService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: "Pokemon App",
      theme: themeProvider.currentTheme.copyWith(
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.pressStart2p(),
          bodyMedium: GoogleFonts.pressStart2p(),
          titleLarge: GoogleFonts.pressStart2p(),
        ),
      ),
      home: const PokemonListScreen(),
    );
  }
}

class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});

  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  final PokemonService _pokemonService = PokemonService();
  final List<Pokemon> _pokemons = [];
  bool _isLoading = false;
  int _offset = 0;
  static const int _limit = 20;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Pokemon> _searchResults = [];
  Map<int, bool> _favoriteStatus = {};

  @override
  void initState() {
    super.initState();
    _loadPokemons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          _searchResults = [];
        });
        return;
      }

      try {
        final results = await _pokemonService.searchPokemon(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _searchResults = [];
          });
        }
      }
    });
  }

  Widget _buildPokemonCard(Pokemon pokemon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PokemonDetailScreen(pokemon: pokemon),
            ),
          );
        },
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  Hero(
                    tag: "pokemon-${pokemon.id}",
                    child: CachedNetworkImage(
                      imageUrl: pokemon.imageUrl,
                      fit: BoxFit.contain,
                      memCacheHeight: 200,
                      maxWidthDiskCache: 500,
                      fadeOutDuration: const Duration(milliseconds: 300),
                      fadeInDuration: const Duration(milliseconds: 300),
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.catching_pokemon,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FutureBuilder<bool>(
                      future: context.read<FavoritesService>().isFavorite(pokemon.id),
                      builder: (context, snapshot) {
                        final isFavorite = snapshot.data ?? false;
                        return IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            await context.read<FavoritesService>().toggleFavorite(pokemon.id);
                            setState(() {
                              _favoriteStatus[pokemon.id] = !isFavorite;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    pokemon.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: pokemon.types
                            .map((type) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: Chip(
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    padding: EdgeInsets.zero,
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                    label: Text(
                                      type,
                                      style: const TextStyle(fontSize: 8),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadPokemons() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final newPokemons = await _pokemonService.getPokemonList(
        limit: _limit,
        offset: _offset,
      );
      setState(() {
        _pokemons.addAll(newPokemons);
        _offset += _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading Pokemon: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pokemon List"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Tooltip(
            message: context.watch<ThemeProvider>().isDarkMode
                ? "Cambiar a modo claro"
                : "Cambiar a modo oscuro",
            child: IconButton(
              icon: Icon(
                context.watch<ThemeProvider>().isDarkMode
                    ? Icons.light_mode
                    : Icons.dark_mode,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                context.read<ThemeProvider>().toggleTheme();
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search Pokemon by name...",
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged("");
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    fillColor: Theme.of(context).colorScheme.surface,
                    filled: true,
                  ),
                ),
              ),
              Expanded(
                child: _searchResults.isNotEmpty
                    ? GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          return _buildPokemonCard(_searchResults[index]);
                        },
                      )
                    : _searchController.text.isNotEmpty
                        ? const Center(
                            child: Text(
                              "No se encontraron resultados",
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (!_isLoading &&
                                  scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                                _loadPokemons();
                              }
                              return true;
                            },
                            child: GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: _pokemons.length + (_isLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _pokemons.length) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                return _buildPokemonCard(_pokemons[index]);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
