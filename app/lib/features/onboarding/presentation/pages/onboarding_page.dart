import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/animations/app_motion.dart';
import '../../../../design_system/components/buttons/app_primary_button.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../authentication/application/auth_controller.dart';

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.asset,
    required this.semanticsLabel,
    required this.title,
    required this.description,
  });

  final String asset;
  final String semanticsLabel;
  final String title;
  final String description;
}

const _slides = [
  _OnboardingSlide(
    asset: 'assets/borah/ui/expressions/symbol_celebrating.svg',
    semanticsLabel: 'Símbolo do BORAH comemorando',
    title: 'Avalie cada restaurante que você visitar',
    description:
        'Dê notas pra comida, atendimento, ambiente e custo-benefício, e '
        'guarde fotos de cada rolê.',
  ),
  _OnboardingSlide(
    asset: 'assets/borah/ui/expressions/symbol_winking.svg',
    semanticsLabel: 'Símbolo do BORAH piscando',
    title: 'Organize rolês com seus grupos',
    description:
        'Crie grupos, marque o próximo encontro e confirme presença - tudo '
        'em um só lugar.',
  ),
  _OnboardingSlide(
    asset: 'assets/borah/ui/expressions/symbol_smiling.svg',
    semanticsLabel: 'Símbolo do BORAH sorrindo',
    title: 'Mostre o seu perfil',
    description:
        'Veja quantos restaurantes você já avaliou, suas fotos e como você '
        'se compara no ranking.',
  ),
];

/// Tutorial de boas-vindas (rodada "visual mais moderno/tutorial") -
/// mostrado exatamente uma vez, logo após o cadastro (ver
/// `AuthController.justSignedUp`/`app_router.dart`), antes da Home.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    // Marca o tutorial como exibido assim que a tela aparece (não só
    // quando termina/pula) - garante exatamente 1 exibição por cadastro,
    // qualquer que seja o botão que o usuário aperte depois.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).acknowledgeOnboardingShown();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() => context.go('/home');

  void _next() {
    final isLast = _page == _slides.length - 1;
    if (isLast) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: AppMotion.scaled(context, AppMotion.slow),
      curve: AppMotion.emphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                child: AppTextButton(label: 'Pular', onPressed: _finish),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) =>
                    _OnboardingSlideView(slide: _slides[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.lg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => _PageDot(isActive: index == _page),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: AppPrimaryButton(
                label: isLast ? 'Começar' : 'Próximo',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: AppMotion.scaled(context, AppMotion.base),
      curve: AppMotion.standard,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? color : color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(slide.asset),
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.scaled(context, AppMotion.slow),
            curve: AppMotion.emphasized,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.scale(scale: 0.85 + (0.15 * value), child: child),
            ),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer,
              ),
              child: Center(
                child: SvgPicture.asset(
                  slide.asset,
                  width: 96,
                  height: 96,
                  semanticsLabel: slide.semanticsLabel,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
