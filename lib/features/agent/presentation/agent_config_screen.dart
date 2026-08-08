import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/agent_templates.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../decks/deck_repository.dart';
import '../data/agent_repository.dart';
import '../data/agent_text.dart';

class AgentConfigScreen extends ConsumerStatefulWidget {
  const AgentConfigScreen({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<AgentConfigScreen> createState() => _AgentConfigScreenState();
}

class _AgentConfigScreenState extends ConsumerState<AgentConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _promptController = TextEditingController();

  late AgentTemplate _selectedTemplate;
  late String _selectedLanguage;
  late String _selectedLevel;

  var _isSaving = false;
  var _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Add real-time preview controller listener
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deckAsync = ref.watch(deckStreamProvider(widget.deckId));

    // Custom slate shades
    const slate300 = Color(0xFFCBD5E1);
    const slate400 = Color(0xFF94A3B8);
    const slate600 = Color(0xFF475569);
    const slate800 = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          AgentText.configTitle,
          style: AppTypography.headingMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      body: SafeArea(
        child: Responsive.constrainedContent(
          child: deckAsync.when(
            loading: () => const LoadingState(),
            error: (_, __) =>
                const ErrorState(message: AgentText.configLoadError),
            data: (deck) {
              if (deck == null) {
                return const ErrorState(message: AgentText.deckNotFound);
              }

              if (!_isInitialized) {
                _nameController.text = deck.agentName;
                _promptController.text = deck.agentPrompt ?? '';
                _selectedTemplate = AgentTemplate.fromId(deck.agentTemplate);
                _selectedLanguage = kAgentLanguages.contains(deck.agentLanguage)
                    ? deck.agentLanguage
                    : kAgentLanguages.first;
                _selectedLevel = kAgentLevels.contains(deck.agentLevel)
                    ? deck.agentLevel
                    : kAgentLevels[1]; // intermediário
                _isInitialized = true;
              }

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppDimensions.xl),
                  children: [
                    // Dynamic Live Agent Preview Card
                    _AgentPreviewCard(
                      isDark: isDark,
                      name: _nameController.text,
                      template: _selectedTemplate,
                      level: _selectedLevel,
                      language: _selectedLanguage,
                    ),
                    const SizedBox(height: AppDimensions.xl),

                    // Card SECTION 1: Identity settings
                    _FormSectionCard(
                      isDark: isDark,
                      title: 'Identidade do Agente',
                      icon: Icons.person_outline,
                      children: [
                        Text(
                          AgentText.agentNameLabel,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? slate400 : slate600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        TextFormField(
                          controller: _nameController,
                          maxLength: AppConstants.kMaxDeckTitle,
                          style: AppTypography.bodyLarge.copyWith(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: AgentText.agentNameHint,
                            hintStyle: AppTypography.bodyLarge.copyWith(
                              color: isDark ? slate600 : slate400,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF1A2230)
                                : AppColors.primary.withValues(alpha: 0.01),
                            prefixIcon: Icon(
                              Icons.smart_toy_outlined,
                              color: isDark ? slate400 : slate600,
                              size: 20,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? slate800
                                    : Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.md,
                              vertical: 14,
                            ),
                            counterText: '', // Hide default count to stay clean
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o nome do agente.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Card SECTION 2: General settings
                    _FormSectionCard(
                      isDark: isDark,
                      title: 'Configurações de Conversa',
                      icon: Icons.tune_outlined,
                      children: [
                        // Template Selection
                        Text(
                          AgentText.templateLabel,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? slate400 : slate600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        DropdownButtonFormField<AgentTemplate>(
                          initialValue: _selectedTemplate,
                          dropdownColor: isDark
                              ? const Color(0xFF1A2230)
                              : Colors.white,
                          style: AppTypography.bodyLarge.copyWith(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          decoration: _inputDecoration(
                            isDark,
                            slate800,
                            slate400,
                            slate600,
                          ),
                          items: AgentTemplate.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedTemplate = value);
                            }
                          },
                        ),
                        const SizedBox(height: AppDimensions.lg),

                        // Language Selection
                        Text(
                          AgentText.languageLabel,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? slate400 : slate600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLanguage,
                          dropdownColor: isDark
                              ? const Color(0xFF1A2230)
                              : Colors.white,
                          style: AppTypography.bodyLarge.copyWith(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          decoration: _inputDecoration(
                            isDark,
                            slate800,
                            slate400,
                            slate600,
                          ),
                          items: kAgentLanguages
                              .map(
                                (lang) => DropdownMenuItem(
                                  value: lang,
                                  child: Text(
                                    lang[0].toUpperCase() + lang.substring(1),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedLanguage = value);
                            }
                          },
                        ),
                        const SizedBox(height: AppDimensions.lg),

                        // Level Selection
                        Text(
                          AgentText.levelLabel,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? slate400 : slate600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLevel,
                          dropdownColor: isDark
                              ? const Color(0xFF1A2230)
                              : Colors.white,
                          style: AppTypography.bodyLarge.copyWith(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          decoration: _inputDecoration(
                            isDark,
                            slate800,
                            slate400,
                            slate600,
                          ),
                          items: kAgentLevels
                              .map(
                                (lvl) => DropdownMenuItem(
                                  value: lvl,
                                  child: Text(
                                    lvl[0].toUpperCase() + lvl.substring(1),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedLevel = value);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Custom Prompt Card (Only visible when template == custom)
                    if (_selectedTemplate == AgentTemplate.custom) ...[
                      _FormSectionCard(
                        isDark: isDark,
                        title: 'Diretrizes de IA Customizadas',
                        icon: Icons.code_outlined,
                        children: [
                          Text(
                            AgentText.customPromptLabel,
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark ? slate400 : slate600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.sm),
                          TextFormField(
                            controller: _promptController,
                            minLines: 4,
                            maxLines: 8,
                            maxLength: AppConstants.kMaxTextInput,
                            style: AppTypography.bodyLarge.copyWith(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: AgentText.customPromptHint,
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: isDark ? slate600 : slate400,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1A2230)
                                  : AppColors.primary.withValues(alpha: 0.01),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? slate800
                                      : Colors.black.withValues(alpha: 0.06),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(
                                AppDimensions.md,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.md),

                          // Dynamic helpful guides box
                          Container(
                            padding: const EdgeInsets.all(AppDimensions.md),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Variáveis Disponíveis:',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Use estes marcadores no texto para que a IA os substitua dinamicamente:\n'
                                  '• {name} - Nome do agente\n'
                                  '• {deck_title} - Título do Deck\n'
                                  '• {language} - Idioma escolhido\n'
                                  '• {level} - Nível selecionado',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark ? slate300 : slate600,
                                    height: 1.4,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.xl),
                    ],

                    // Elevated save button with glow
                    _isSaving
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : AppButton(
                            label: AgentText.save,
                            icon: Icons.check_circle_outline,
                            onPressed: () => _save(deck),
                          ),
                    const SizedBox(height: AppDimensions.xxl),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    bool isDark,
    Color slate800,
    Color slate400,
    Color slate600,
  ) {
    return InputDecoration(
      filled: true,
      fillColor: isDark
          ? const Color(0xFF1A2230)
          : AppColors.primary.withValues(alpha: 0.01),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? slate800 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: 12,
      ),
    );
  }

  Future<void> _save(dynamic deck) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(agentRepositoryProvider)
          .updateAgentConfig(
            deck: deck,
            agentName: _nameController.text,
            agentTemplate: _selectedTemplate.id,
            agentPrompt: _selectedTemplate == AgentTemplate.custom
                ? _promptController.text
                : null,
            agentLanguage: _selectedLanguage,
            agentLevel: _selectedLevel,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(AgentText.saveSuccess),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
        );
        Navigator.of(context).maybePop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(AgentText.saveError),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

// ==========================================
// COMPONENT: FORM SECTION FROSTED CARD
// ==========================================
class _FormSectionCard extends StatelessWidget {
  const _FormSectionCard({
    required this.isDark,
    required this.title,
    required this.icon,
    required this.children,
  });

  final bool isDark;
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTypography.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: AppDimensions.xl),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ==========================================
// COMPONENT: DYNAMIC AGENT PREVIEW HERO
// ==========================================
class _AgentPreviewCard extends StatelessWidget {
  const _AgentPreviewCard({
    required this.isDark,
    required this.name,
    required this.template,
    required this.level,
    required this.language,
  });

  final bool isDark;
  final String name;
  final AgentTemplate template;
  final String level;
  final String language;

  @override
  Widget build(BuildContext context) {
    final finalName = name.trim().isNotEmpty ? name.trim() : 'Novo Tutor';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2640), const Color(0xFF131A26)]
              : [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.02),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radius2Xl),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Row(
          children: [
            // Gorgeous glowing avatar preview
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: AppDimensions.lg),

            // Preview labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'PREVIEW DO AGENTE',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 8,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    finalName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headingLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${template.displayName} • Nível ${level[0].toUpperCase()}${level.substring(1)} (${language[0].toUpperCase()}${language.substring(1)})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF475569),
                      fontSize: 11,
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
}
