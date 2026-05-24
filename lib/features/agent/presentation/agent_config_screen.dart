import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../decks/deck_repository.dart';
import '../data/agent_repository.dart';
import '../data/agent_templates.dart';
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
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(deckStreamProvider(widget.deckId));

    return Scaffold(
      appBar: AppBar(title: const Text(AgentText.configTitle)),
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
                  padding: Responsive.contentPadding(context),
                  children: [
                    Text(
                      AgentText.configTitle,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppDimensions.xxl),

                    // Agent Name
                    TextFormField(
                      controller: _nameController,
                      maxLength: AppConstants.kMaxDeckTitle,
                      decoration: const InputDecoration(
                        labelText: AgentText.agentNameLabel,
                        hintText: AgentText.agentNameHint,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome do agente.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.xl),

                    // Template
                    DropdownButtonFormField<AgentTemplate>(
                      initialValue: _selectedTemplate,
                      decoration: const InputDecoration(
                        labelText: AgentText.templateLabel,
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
                    const SizedBox(height: AppDimensions.xl),

                    // Language
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLanguage,
                      decoration: const InputDecoration(
                        labelText: AgentText.languageLabel,
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
                    const SizedBox(height: AppDimensions.xl),

                    // Level
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLevel,
                      decoration: const InputDecoration(
                        labelText: AgentText.levelLabel,
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
                    const SizedBox(height: AppDimensions.xl),

                    // Custom Prompt (only visible when template == custom)
                    if (_selectedTemplate == AgentTemplate.custom) ...[
                      TextFormField(
                        controller: _promptController,
                        minLines: 4,
                        maxLines: 10,
                        maxLength: AppConstants.kMaxTextInput,
                        decoration: const InputDecoration(
                          labelText: AgentText.customPromptLabel,
                          hintText: AgentText.customPromptHint,
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xl),
                    ],

                    // Save
                    AppButton(
                      label: _isSaving ? AgentText.saving : AgentText.save,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : () => _save(deck),
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

  Future<void> _save(dynamic deck) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(agentRepositoryProvider).updateAgentConfig(
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
          const SnackBar(content: Text(AgentText.saveSuccess)),
        );
        Navigator.of(context).maybePop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AgentText.saveError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
