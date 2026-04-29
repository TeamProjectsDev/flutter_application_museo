import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'onboarding_title_1',
      'description': 'onboarding_desc_1',
      'icon': 'museum',
    },
    {
      'title': 'onboarding_title_2',
      'description': 'onboarding_desc_2',
      'icon': 'view_in_ar',
    },
    {
      'title': 'onboarding_title_3',
      'description': 'onboarding_desc_3',
      'icon': 'military_tech',
    },
  ];

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'museum':
        return Icons.museum_rounded;
      case 'view_in_ar':
        return Icons.view_in_ar_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getIconData(_onboardingData[index]['icon']!),
                      size: 120,
                      color: isDark ? Colors.amber.shade200 : Colors.deepPurple,
                    ),
                    const SizedBox(height: 60),
                    Text(
                      _onboardingData[index]['title']!.tr(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _onboardingData[index]['description']!.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),

          // Skip Button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _completeOnboarding,
              child: Text(
                'common_skip'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Indicators and Next/Start Button
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    _onboardingData.length,
                    (index) => buildDot(index, context, isDark),
                  ),
                ),
                FloatingActionButton(
                  onPressed: () {
                    if (_currentPage == _onboardingData.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  backgroundColor: isDark
                      ? Colors.amber.shade600
                      : Colors.deepPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  child: Icon(
                    _currentPage == _onboardingData.length - 1
                        ? Icons.check
                        : Icons.arrow_forward_ios,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index, BuildContext context, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? (isDark ? Colors.amber.shade400 : Colors.deepPurple)
            : Colors.grey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
