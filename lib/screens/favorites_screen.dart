import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/localization.dart';
import '../models/master.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';
import '../widgets/master_card.dart';
import 'master_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final ApiService apiService;
  const FavoritesScreen({super.key, required this.apiService});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<MasterModel> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favs = await widget.apiService.getFavorites();
      if (mounted) setState(() { _favorites = favs; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.currentGradient(context)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Text(
                  AppStrings.favorites,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                    : _favorites.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.favorite_border_rounded, size: 80, color: theme.textTheme.bodySmall?.color?.withOpacity(0.2)),
                                const SizedBox(height: 16),
                                Text(AppStrings.noFavorites, style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
                                const SizedBox(height: 8),
                                Text(
                                  AppStrings.isRu ? 'Добавляйте мастеров в избранное' : 'Ustalarni sevimlilaringizga qo\'shing',
                                  style: theme.textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadFavorites,
                            color: theme.primaryColor,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _favorites.length,
                              itemBuilder: (context, index) {
                                return MasterCard(
                                  master: _favorites[index],
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MasterDetailScreen(
                                          apiService: widget.apiService,
                                          masterId: _favorites[index].id,
                                        ),
                                      ),
                                    );
                                    _loadFavorites();
                                  },
                                );
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
