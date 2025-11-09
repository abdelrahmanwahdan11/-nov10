import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/onboarding_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_currentIndex < 2) {
        _controller.nextPage(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      } else {
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final pages = [
      OnboardingCard(
        title: locale.translate('onboarding_title_1'),
        description: locale.translate('onboarding_body_1'),
        imageUrl: 'https://picsum.photos/seed/onboarding1/800/1200',
      ),
      OnboardingCard(
        title: locale.translate('onboarding_title_2'),
        description: locale.translate('onboarding_body_2'),
        imageUrl: 'https://picsum.photos/seed/onboarding2/800/1200',
      ),
      OnboardingCard(
        title: locale.translate('onboarding_title_3'),
        description: locale.translate('onboarding_body_3'),
        imageUrl: 'https://picsum.photos/seed/onboarding3/800/1200',
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: pages.length,
            itemBuilder: (context, index) => pages[index],
          ),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      height: 10,
                      width: _currentIndex == index ? 32 : 12,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: widget.onCompleted,
                      child: Text(locale.translate('skip')),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (_currentIndex == pages.length - 1) {
                          widget.onCompleted();
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(locale.translate('get_started')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
