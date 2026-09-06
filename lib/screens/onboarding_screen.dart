import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/localization.dart';
import '../services/theme_service.dart';
import '../widgets/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.getPalette(ThemeService().themeNotifier.value);
    
    final titles = [
      AppStrings.onboarding1Title,
      AppStrings.onboarding2Title,
      AppStrings.onboarding3Title,
    ];
    final descs = [
      AppStrings.onboarding1Desc,
      AppStrings.onboarding2Desc,
      AppStrings.onboarding3Desc,
    ];
    final icons = [
      Icons.search_rounded,
      Icons.filter_alt_rounded,
      Icons.person_add_rounded,
    ];
    final colors = [
      palette.primary,
      AppColors.blue,
      AppColors.green,
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.currentGradient(context)),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                  child: Text(
                    AppStrings.skip,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: colors[index].withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Icon(
                              icons[index],
                              size: 70,
                              color: colors[index],
                            ),
                          ),
                          const SizedBox(height: 48),
                          Text(
                            titles[index],
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            descs[index],
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? palette.primary
                          : palette.textHint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),

              // Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: GradientButton(
                  text: _currentPage == 2
                      ? AppStrings.getStarted
                      : AppStrings.next,
                  icon: _currentPage == 2
                      ? Icons.rocket_launch_rounded
                      : Icons.arrow_forward_rounded,
                  onPressed: () {
                    if (_currentPage == 2) {
                      Navigator.pushReplacementNamed(context, '/register');
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
