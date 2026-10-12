import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../models/nin_database.dart';
import '../models/variable_steps.dart';
import '../providers/database_provider.dart';
import '../navigation/app_routes.dart';
import '../widgets/expandable_markdown.dart';

class VariableDetailScreen extends ConsumerWidget {
  final String variableId;

  const VariableDetailScreen({super.key, required this.variableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variableAsync = ref.watch(variableProvider(variableId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return variableAsync.when(
      data: (varData) {
        if (varData == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ikke funnet')),
            body: const Center(child: Text('Variable not found.')),
          );
        }

        final subVariablesAsync = ref.watch(subVariablesProvider(varData.id));

        return Scaffold(
          appBar: AppBar(
            title: Text(varData.navn, maxLines: null),
            actions: [
              if (varData.langkode != null)
                IconButton(
                  icon: const Icon(Icons.open_in_browser),
                  tooltip: 'View on Artsdatabanken',
                  onPressed: () => launchUrl(
                    Uri.parse('https://artsdatabanken.no/naturtyper/natur-i-norge/${varData.langkode}'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, varData),
                if (varData.parentId != null && varData.parentId!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildParentLink(context, ref, varData.parentId!),
                ],
                const SizedBox(height: 24),
                _buildSectionTitle(context, "Beskrivelse"),
                const SizedBox(height: 8),
                ExpandableMarkdown(
                  data: varData.description ?? "Ingen beskrivelse tilgjengelig.",
                ),
                subVariablesAsync.when(
                  data: (subs) => subs.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            _buildSectionTitle(context, "Underordnete variabler"),
                            const SizedBox(height: 8),
                            ...subs.map((s) => _buildSubVariableTile(context, s)),
                          ],
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text("Feil ved lasting av undervariabler: $e"),
                ),
                if (varData.stepsJson != null) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, "Trinn"),
                  const SizedBox(height: 8),
                  _buildStepsList(context, varData.stepsJson!),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text("Feil: $e", style: TextStyle(color: colorScheme.error)))),
    );
  }

  Widget _buildParentLink(BuildContext context, WidgetRef ref, String parentId) {
    final parentAsync = ref.watch(variableProvider(parentId));
    return parentAsync.when(
      data: (parent) => parent == null 
        ? const SizedBox.shrink() 
        : InkWell(
            onTap: () => Navigator.of(context).pushReplacement(
              AppRoutes.variableDetail(parent.id),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_upward, size: 16, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text("Overordnet: ", style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary)),
                  Text(parent.navn, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                ],
              ),
            ),
          ),
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildSubVariableTile(BuildContext context, NinVariable variable) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(variable.navn, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(variable.id, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => Navigator.of(context).push(
        AppRoutes.variableDetail(variable.id),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, NinVariable variable) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(variable.id, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(variable.navn, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (variable.kategori.isNotEmpty) _buildChip(context, variable.kategori),
              if (variable.ecosystnivaaNavn != null) _buildChip(context, variable.ecosystnivaaNavn!),
              if (variable.variabelkategoriNavn != null) _buildChip(context, variable.variabelkategoriNavn!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10)),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
    );
  }

  Widget _buildStepsList(BuildContext context, String stepsJson) {
    final colorScheme = Theme.of(context).colorScheme;
    try {
      final scales = parseVariableSteps(json.decode(stepsJson));
      if (scales.isEmpty) {
        return Text(
          'Ingen trinn tilgjengelig.',
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
        );
      }

      final showScaleHeaders = scales.length > 1 ||
          (scales.first.maaleskalaNavn != null &&
              scales.first.maaleskalaNavn!.isNotEmpty);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < scales.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            if (showScaleHeaders) ...[
              Text(
                scales[i].displayTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
              if (scales[i].displaySubtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  scales[i].displaySubtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
            ...scales[i].trinn.map((s) => _buildStepTile(context, s)),
          ],
        ],
      );
    } catch (e) {
      return Text("Kunne ikke laste trinn.", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)));
    }
  }

  Widget _buildStepTile(BuildContext context, VariableStep step) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              step.verdi ?? '?',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.navn ?? 'Ukjent trinn',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (step.kode != null)
                  Text(
                    step.kode!,
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
