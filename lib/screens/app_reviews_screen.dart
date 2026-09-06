import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/localization.dart';
import '../config/api_config.dart';
import '../utils/date_utils.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';
import '../widgets/glass_container.dart';

class AppReviewsScreen extends StatefulWidget {
  final ApiService apiService;
  const AppReviewsScreen({super.key, required this.apiService});

  @override
  State<AppReviewsScreen> createState() => _AppReviewsScreenState();
}

class _AppReviewsScreenState extends State<AppReviewsScreen> {
  List<dynamic> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final reviews = await widget.apiService.getAppReviews();
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showAddReviewDialog() async {
    int rating = 5;
    final commentController = TextEditingController();
    final mode = ThemeService().currentMode;
    final palette = AppTheme.getPalette(mode);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: palette.card,
          surfaceTintColor: palette.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(
            AppStrings.isRu ? 'Оставить отзыв' : 'Fikr bildirish', 
            style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold)
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setDialogState(() => rating = index + 1),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 4,
                onChanged: (val) => setDialogState(() {}),
                style: TextStyle(color: palette.textPrimary),
                decoration: InputDecoration(
                  hintText: AppStrings.isRu ? 'Ваш комментарий...' : 'Sizning fikringiz...',
                  hintStyle: TextStyle(color: palette.textHint),
                  filled: true,
                  fillColor: palette.bg.withOpacity(0.5),
                  counterStyle: TextStyle(color: palette.textHint),
                  counterText: '${commentController.text.length}/5',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16), 
                    borderSide: BorderSide(color: palette.cardBorder)
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (commentController.text.isNotEmpty && commentController.text.length < 5)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    AppStrings.isRu ? 'Минимум 5 символов' : 'Kamida 5 ta belgi',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppStrings.isRu ? 'Отмена' : 'Bekor', style: TextStyle(color: palette.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: commentController.text.length >= 5 
                ? () => Navigator.pop(ctx, true) 
                : null,
              child: Text(AppStrings.isRu ? 'Отправить' : 'Yuborish', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && commentController.text.length >= 5) {
      if (mounted) setState(() => _isLoading = true);
      try {
        await widget.apiService.createAppReview(rating, commentController.text);
        _fetchReviews();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          // Show more detailed error if possible
          String errorMsg = e.toString().replaceAll('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppStrings.isRu ? 'Ошибка: $errorMsg' : 'Xatolik: $errorMsg'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeService().themeNotifier,
      builder: (context, mode, child) {
        final palette = AppTheme.getPalette(mode);
        
        return Container(
          decoration: BoxDecoration(gradient: palette.bgGradient),
          child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              AppStrings.isRu ? 'Отзывы о приложении' : 'Ilova haqida fikrlar',
              style: TextStyle(
                color: palette.textPrimary, 
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: palette.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
              child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: palette.primary))
                : RefreshIndicator(
                    onRefresh: _fetchReviews,
                    color: palette.primary,
                    child: _reviews.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.rate_review_outlined, size: 80, color: palette.textSecondary.withOpacity(0.2)),
                              const SizedBox(height: 24),
                              Text(
                                AppStrings.isRu ? 'Пока нет отзывов' : 'Hozircha fikrlar yo\'q',
                                style: TextStyle(color: palette.textSecondary, fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            final user = review['user'];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: GlassContainer(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: palette.primary.withOpacity(0.1),
                                          backgroundImage: user['avatar'] != null 
                                            ? NetworkImage('${ApiConfig.baseUrl}${user['avatar']}')
                                            : null,
                                          child: user['avatar'] == null 
                                            ? Text(
                                                (user['name'] ?? 'U')[0].toUpperCase(), 
                                                style: TextStyle(color: palette.primary, fontWeight: FontWeight.bold, fontSize: 18),
                                              )
                                            : null,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user['name'] ?? 'User', 
                                                style: TextStyle(
                                                  color: palette.textPrimary, 
                                                  fontWeight: FontWeight.bold, 
                                                  fontSize: 17
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: List.generate(5, (star) => Icon(
                                                  Icons.star_rounded,
                                                  size: 16,
                                                  color: star < review['rating'] ? Colors.amber : palette.textSecondary.withOpacity(0.2),
                                                )),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          _formatDate(review['created_at']),
                                          style: TextStyle(color: palette.textSecondary.withOpacity(0.6), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      review['comment'] ?? '',
                                      style: TextStyle(
                                        color: palette.textPrimary.withOpacity(0.9), 
                                        fontSize: 15, 
                                        height: 1.5
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ),
            ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: palette.primary,
            foregroundColor: Colors.white,
            onPressed: _showAddReviewDialog,
            elevation: 4,
            icon: const Icon(Icons.add_comment_rounded),
            label: Text(
              AppStrings.isRu ? 'Написать' : 'Yozish',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        );
      },
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return "";
    try {
      final date = DateTimeUtils.parseUtc(isoString);
      return DateTimeUtils.formatDate(date);
    } catch (_) {
      return "";
    }
  }
}
