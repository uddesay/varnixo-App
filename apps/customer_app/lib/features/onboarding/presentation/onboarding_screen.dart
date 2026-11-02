import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/widgets/primary_button.dart';

class _OnboardingPage {
  const _OnboardingPage({required this.icon, required this.title, required this.description});
  final IconData icon;
  final String title;
  final String description;
}

const List<_OnboardingPage> _pages = [
  _OnboardingPage(
    icon: Icons.storefront_rounded,
    title: 'Shop from thousands of sellers',
    description: 'Discover premium products across fashion, electronics, home and more — all in one place.',
  ),
  _OnboardingPage(
    icon: Icons.local_shipping_outlined,
    title: 'Fast, trackable delivery',
    description: 'Real-time order tracking from checkout to your doorstep, with easy returns if plans change.',
  ),
  _OnboardingPage(
    icon: Icons.verified_user_outlined,
    title: 'Secure payments, your way',
    description: 'Cards, UPI, wallet or cash on delivery — checkout is fast, encrypted and always your choice.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  void _next() {
    if (_index == _pages.length - 1) {
      context.go(RoutePaths.login);
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go(RoutePaths.login),
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, size: 64, color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SmoothPageIndicator(
              controller: _controller,
              count: _pages.length,
              effect: ExpandingDotsEffect(
                activeDotColor: Theme.of(context).colorScheme.primary,
                dotColor: Theme.of(context).colorScheme.outline,
                dotHeight: 8,
                dotWidth: 8,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(
                label: _index == _pages.length - 1 ? 'Get started' : 'Next',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
