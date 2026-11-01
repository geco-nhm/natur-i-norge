import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../providers/nin_search_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/database_provider.dart';
import '../models/nin_database.dart';
import '../models/user_database.dart';
import '../navigation/app_routes.dart';
import '../widgets/ecological_matrix.dart';
import '../widgets/gad_species_panel.dart';
import '../providers/gad_provider.dart';
import '../widgets/expandable_markdown.dart';
import '../widgets/local_image.dart';
import '../widgets/type_image_viewer.dart';
import '../nin_type_colors.dart';
import '../search/nin_type_navigation.dart';
import '../services/nin_api_source.dart';
import '../utils/artsdatabanken_urls.dart';
import '../widgets/matrix_health_sheet.dart';
import '../widgets/nin_search_sheet.dart';

class TypesScreen extends ConsumerStatefulWidget {
  final NinType? type;
  final ValueChanged<NinType>? onPick;
  final String? highlightQuery;

  const TypesScreen({
    super.key,
    this.type,
    this.onPick,
    this.highlightQuery,
  });

  @override
  ConsumerState<TypesScreen> createState() => _TypesScreenState();
}

class _TypesScreenState extends ConsumerState<TypesScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedScale = ref.watch(selectedScaleProvider);
    final showLkmNames = ref.watch(showLkmNamesProvider);
    final pendingHighlight = ref.watch(pendingSearchHighlightProvider);
    final effectiveHighlightQuery = widget.highlightQuery ??
        (pendingHighlight?.typeId == widget.type?.id ? pendingHighlight?.query : null);
    final hovedtypeId = widget.type?.id;
    final isGadCompatible = isGadCompatibleHovedtype(hovedtypeId);
    final gadOverlayVisible =
        isGadCompatible ? ref.watch(gadOverlayVisibleProvider) : false;
    final gadConstancy = isGadCompatible && gadOverlayVisible
        ? ref.watch(gadConstancyMapProvider).asData?.value
        : null;
    final parentId = widget.type?.id;
    final typesAsync = ref.watch(subTypesProvider(parentId ?? ''));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref),
          
          // Favorites Quick Access
          if (widget.type == null)
            Consumer(
              builder: (context, ref, child) {
                final favoritesAsync = ref.watch(favoritesProvider);
                return favoritesAsync.when(
                  data: (favIds) {
                    if (favIds.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                    final favTypesAsync = ref.watch(typesByIdsProvider(favIds));
                    return favTypesAsync.when(
                      data: (types) => SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: [
                                  Icon(Icons.star, size: 16, color: Colors.amber[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'FAVORITES',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber[700], letterSpacing: 1.2),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: types.length,
                                itemBuilder: (context, index) => SizedBox(
                                  width: 160,
                                  child: _TypeCard(
                                    type: types[index],
                                    showFavoriteStar: false,
                                    onTap: () => Navigator.push(
                                      context,
                                      AppRoutes.types(type: types[index], onPick: widget.onPick),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Divider(indent: 16, endIndent: 16, height: 32),
                          ],
                        ),
                      ),
                      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                );
              },
            ),
          
          // Search entry
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                readOnly: true,
                onTap: _openSearch,
                decoration: InputDecoration(
                  hintText: 'Search codes, names, descriptions…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: MediaQuery.sizeOf(context).width > 800
                      ? Icon(
                          Icons.keyboard_command_key,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          
          // Description Header
          if (widget.type != null && widget.type!.description != null)
            Consumer(
              builder: (context, ref, _) {
                final subtypesAsync = ref.watch(subTypesProvider(widget.type!.id));
                final hasSubtypes = subtypesAsync.maybeWhen(
                  data: (types) => types.isNotEmpty,
                  orElse: () => false,
                );

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Badge(label: widget.type!.kategori, color: ninTypeAccentColor(widget.type!)),
                            if (widget.type!.ecosystnivaaNavn != null) ...[
                              const SizedBox(width: 8),
                              _Badge(label: widget.type!.ecosystnivaaNavn!, color: Colors.blue),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Beskrivelse',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ExpandableMarkdown(
                          data: widget.type!.description!,
                          collapsible: hasSubtypes,
                          highlightQuery: effectiveHighlightQuery,
                        ),
                        const Divider(height: 32),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Sub-types Content
          typesAsync.when(
            data: (allTypes) {
              if (allTypes.isEmpty && widget.type != null) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              final isHovedtype = widget.type?.kategori == 'Hovedtype';
              
              // Filter types based on selection
              final types = allTypes.where((t) {
                if (!isHovedtype) return true;
                
                if (selectedScale == 'Biologisk') {
                  return t.kategori == 'Grunntype';
                } else {
                  return t.kategori == 'Kartleggingsenhet' && t.scale == selectedScale;
                }
              }).toList()..sort((a, b) => a.id.compareTo(b.id));

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (isHovedtype) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Text(
                          'VISNINGSMODUS',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2),
                        ),
                      ),
                      Center(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Biologisk', label: Text('Grunntyper'), icon: Icon(Icons.biotech)),
                            ButtonSegment(value: 'M005', label: Text('1:5 000')),
                            ButtonSegment(value: 'M020', label: Text('1:20 000')),
                            ButtonSegment(value: 'M050', label: Text('1:50 000')),
                          ],
                          selected: {selectedScale},
                          onSelectionChanged: (set) => ref.read(selectedScaleProvider.notifier).setScale(set.first),
                          style: SegmentedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                            selectedBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            selectedForegroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Show matrix for both biological and mapping scales
                      () {
                        final gtMap = {
                          for (final gt in allTypes.where((t) => t.kategori == 'Grunntype')) gt.id: gt,
                        };
                        final List<NinType> matrixTypes;
                        if (selectedScale == 'Biologisk') {
                          matrixTypes = allTypes.where((t) => t.kategori == 'Grunntype').toList()
                            ..sort((a, b) => a.id.compareTo(b.id));
                        } else {
                          matrixTypes = allTypes
                              .where((t) => t.kategori == 'Kartleggingsenhet' && t.scale == selectedScale)
                              .toList()
                            ..sort((a, b) => a.id.compareTo(b.id));
                        }

                        if (matrixTypes.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isGadCompatible) ...[
                              GadSpeciesPanel(hovedtypeId: hovedtypeId!),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                Text(
                                  'ECOLOGICAL MATRIX (${selectedScale == 'Biologisk' ? 'BIO' : selectedScale})',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.2),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  icon: Icon(
                                    Icons.monitor_heart_outlined,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.75),
                                  ),
                                  tooltip: 'Check matrix health',
                                  onPressed: () => showMatrixHealthSheet(
                                    context,
                                    matrixTypes: matrixTypes,
                                    grunntypeById: gtMap,
                                    parentTypeId: widget.type!.id,
                                    parentTypeName: widget.type!.navn,
                                    scale: selectedScale,
                                  ),
                                ),
                                PopupMenuButton<bool>(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(Icons.settings, size: 14, color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
                                  tooltip: 'Matrix settings',
                                  onSelected: (val) => ref.read(showLkmNamesProvider.notifier).setShowLkmNames(val),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: true, child: Text('Show step names')),
                                    const PopupMenuItem(value: false, child: Text('Show step codes')),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            EcologicalMatrix(
                              subTypes: matrixTypes,
                              grunntypeById: gtMap,
                              onPick: widget.onPick,
                              showStepNames: showLkmNames,
                              gadConstancy: gadConstancy,
                            ),
                            const Divider(height: 48),
                          ],
                        );
                      }(),
                      
                      Text(
                        selectedScale == 'Biologisk' ? 'GRUNNTYPER' : 'KARTLEGGINGSENHETER ($selectedScale)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    if (types.isEmpty && selectedScale == 'Biologisk' && !isHovedtype) ...[
                      // If we are at a Kartleggingsenhet, show what it contains
                      if (widget.type?.kategori == 'Kartleggingsenhet' && widget.type?.containsTypes != null) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'CONSTITUENT NATURE TYPES',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.2),
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, child) {
                            final List<String> ids = List<String>.from(json.decode(widget.type!.containsTypes!));
                            final constituentTypes = ref.watch(typesByIdsProvider(ids));
                            
                            return constituentTypes.when(
                              data: (cTypes) => GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 2.0,
                                ),
                                padding: const EdgeInsets.only(top: 12, bottom: 16),
                                itemCount: cTypes.length,
                                itemBuilder: (context, index) => _TypeCard(
                                  type: cTypes[index],
                                  onTap: () => Navigator.push(
                                    context,
                                    AppRoutes.types(type: cTypes[index], onPick: widget.onPick),
                                  ),
                                ),
                              ),
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, s) => Text('Error loading types: $e'),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                    
                    if (types.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                        ),
                        padding: const EdgeInsets.only(top: 12, bottom: 24),
                        itemCount: types.length,
                        itemBuilder: (context, index) => _TypeCard(
                          type: types[index],
                          onTap: () => Navigator.push(
                            context,
                            AppRoutes.types(type: types[index], onPick: widget.onPick),
                          ),
                        ),
                      ),
                  ]),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              )),
            ),
            error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(typesAsync),
    );
  }

  void _openSearch() {
    showNinSearchSheet(
      context,
      ref: ref,
      onSelectType: (type, query) => navigateToTypePath(
        context,
        ref,
        type,
        onPick: widget.onPick,
        highlightQuery: query,
      ),
    );
  }

  Widget? _buildFloatingActionButton(AsyncValue<List<NinType>> typesAsync) {
    if (widget.type == null) return null;

    return typesAsync.when(
      data: (subtypes) {
        final isLeaf = subtypes.isEmpty;
        final isMappingUnit = widget.type!.kategori == 'Kartleggingsenhet';
        final isGrunntype = widget.type!.kategori == 'Grunntype';

        if (widget.onPick != null) {
          if (isMappingUnit) {
            return FloatingActionButton.extended(
              onPressed: () => widget.onPick!(widget.type!),
              icon: const Icon(Icons.check_circle),
              label: const Text('Select this Mapping Unit'),
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            );
          }
          if (isGrunntype) {
            return FloatingActionButton.extended(
              onPressed: null,
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.white70),
              label: const Text('Please select a Mapping Unit level'),
              backgroundColor: Colors.orange[800]?.withOpacity(0.8),
            );
          }
          return null;
        }

        if (!isLeaf) return null;

        return FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).push(
              AppRoutes.camera(initialType: widget.type),
            );
          },
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Capture Observation'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        );
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final type = widget.type;
    final color = type != null ? ninTypeAccentColor(type) : Colors.blue;
    final disableImages = ref.watch(disableImagesProvider);
    final canViewImage = type != null &&
        !disableImages &&
        type.imageUrl != null &&
        type.imageUrl!.isNotEmpty;
    
    return SliverAppBar(
      expandedHeight: type == null ? 120 : 350,
      pinned: true,
      iconTheme: const IconThemeData(color: Colors.white, shadows: [Shadow(color: Colors.black45, blurRadius: 8)]),
      actions: [
        if (type != null)
          Consumer(
            builder: (context, ref, _) {
              final favorites = ref.watch(favoritesProvider).value ?? [];
              final isFavorite = favorites.contains(type.id);
              final artsdatabankenUrl = ArtsdatabankenUrls.typeUrl(type.langkode);
              final typeApiUrl = NinApiSourceService.typeApiUrl(type);

              return PopupMenuButton<_TypeDetailMenuAction>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                tooltip: 'More options',
                onSelected: (action) async {
                  switch (action) {
                    case _TypeDetailMenuAction.openArtsdatabanken:
                      if (artsdatabankenUrl == null) return;
                      await launchUrl(
                        artsdatabankenUrl,
                        mode: LaunchMode.externalApplication,
                      );
                    case _TypeDetailMenuAction.toggleFavorite:
                      final db = ref.read(userDatabaseProvider);
                      if (isFavorite) {
                        await (db.delete(db.favorites)..where((t) => t.typeId.equals(type.id))).go();
                      } else {
                        await db.into(db.favorites).insert(FavoritesCompanion.insert(typeId: type.id));
                      }
                    case _TypeDetailMenuAction.copyApiUrl:
                      final url = NinApiSourceService.typeApiUrl(type);
                      if (url == null) return;
                      await Clipboard.setData(ClipboardData(text: url));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('API URL copied to clipboard')),
                        );
                      }
                  }
                },
                itemBuilder: (context) => [
                  if (artsdatabankenUrl != null)
                    const PopupMenuItem(
                      value: _TypeDetailMenuAction.openArtsdatabanken,
                      child: Row(
                        children: [
                          Icon(Icons.open_in_browser),
                          SizedBox(width: 12),
                          Text('Open on Artsdatabanken'),
                        ],
                      ),
                    ),
                  if (typeApiUrl != null)
                    const PopupMenuItem(
                      value: _TypeDetailMenuAction.copyApiUrl,
                      child: Row(
                        children: [
                          Icon(Icons.link),
                          SizedBox(width: 12),
                          Text('Copy API URL'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: _TypeDetailMenuAction.toggleFavorite,
                    child: Row(
                      children: [
                        Icon(isFavorite ? Icons.star : Icons.star_border),
                        const SizedBox(width: 12),
                        Text(isFavorite ? 'Remove from favorites' : 'Add to favorites'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(
          left: 56,
          right: type == null ? 16 : 48,
          bottom: type == null ? 14 : 16,
        ),
        title: type == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NiN Explorer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                      shadows: [Shadow(color: Theme.of(context).colorScheme.surface.withOpacity(0.8), blurRadius: 12)],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse('https://artsdatabanken.no'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        'Data provided by Artsdatabanken.no',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          decoration: TextDecoration.underline,
                          decorationColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : _TypeDetailAppBarTitle(type: type, color: color),
        background: type == null ? null : Stack(
          fit: StackFit.expand,
          children: [
            MouseRegion(
              cursor: canViewImage ? SystemMouseCursors.click : MouseCursor.defer,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: canViewImage
                    ? () => showTypeImageViewer(
                          context,
                          imageUrl: type.imageUrl!,
                          title: type.navn,
                        )
                    : null,
                child: Hero(
                  tag: 'image_${type.id}',
                  child: disableImages
                      ? TypeImageAmbientBackground(accentColor: color)
                      : LocalTypeImage(
                          imageUrl: type.imageUrl,
                          fit: BoxFit.cover,
                          semanticLabel: canViewImage
                              ? 'Representative photo of ${type.navn}. Tap to view full size.'
                              : 'Representative photo of ${type.navn}',
                          accentColor: color,
                        ),
                ),
              ),
            ),
            // Legibility Gradient — ignore pointer so taps reach the image
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.4, 0.8],
                      colors: [
                        Theme.of(context).colorScheme.surface.withOpacity(0.7),
                        Theme.of(context).colorScheme.surface.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TypeDetailMenuAction { openArtsdatabanken, copyApiUrl, toggleFavorite }

class _TypeDetailAppBarTitle extends ConsumerWidget {
  final NinType type;
  final Color color;

  const _TypeDetailAppBarTitle({required this.type, required this.color});

  bool _isExpanded(FlexibleSpaceBarSettings? settings) {
    if (settings == null) return true;
    final range = settings.maxExtent - settings.minExtent;
    if (range <= 0) return true;
    final expandRatio = (settings.currentExtent - settings.minExtent) / range;
    return expandRatio > 0.65;
  }

  Widget _codeChipRow(Color chipColor, bool isFavorite) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
            ],
          ),
          child: Text(
            type.id,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: chipColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (isFavorite) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.star,
            size: 16,
            color: Colors.amber[700],
            shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final isExpanded = _isExpanded(settings);
    final isFavorite = (ref.watch(favoritesProvider).value ?? []).contains(type.id);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final nameShadow = Shadow(color: Theme.of(context).colorScheme.surface.withOpacity(0.8), blurRadius: 12);
    final nameStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: isExpanded ? 15 : 16,
      height: isExpanded ? 1.25 : 1.1,
      color: onSurface,
      shadows: [nameShadow],
    );

    if (isExpanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _codeChipRow(color, isFavorite),
          const SizedBox(height: 6),
          Text(
            type.navn,
            style: nameStyle,
            softWrap: true,
            maxLines: 6,
            overflow: TextOverflow.clip,
          ),
        ],
      );
    }

    return Transform.translate(
      offset: const Offset(0, -3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _codeChipRow(color, isFavorite),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              type.navn,
              style: nameStyle.copyWith(height: 1.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends ConsumerWidget {
  final NinType type;
  final VoidCallback onTap;
  final bool showFavoriteStar;

  const _TypeCard({
    required this.type,
    required this.onTap,
    this.showFavoriteStar = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disableImages = ref.watch(disableImagesProvider);
    final isFavorite = (ref.watch(favoritesProvider).value ?? []).contains(type.id);
    final color = ninTypeAccentColor(type);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: Hero(
                tag: 'image_${type.id}',
                child: disableImages
                    ? TypeImageAmbientBackground(accentColor: color)
                    : LocalTypeImage(
                        imageUrl: type.imageUrl,
                        fit: BoxFit.cover,
                        semanticLabel: 'Representative photo of ${type.navn}',
                        accentColor: color,
                      ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.3, 0.6],
                    colors: [
                      color.withOpacity(0.9),
                      color.withOpacity(0.4),
                      color.withOpacity(0.0),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTight = constraints.maxHeight < 80;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _TypeCardLabelPanel(
                          type: type,
                          accentColor: color,
                          isFavorite: isFavorite,
                          showFavoriteStar: showFavoriteStar,
                          isTight: isTight,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCardLabelPanel extends StatelessWidget {
  final NinType type;
  final Color accentColor;
  final bool isFavorite;
  final bool showFavoriteStar;
  final bool isTight;

  const _TypeCardLabelPanel({
    required this.type,
    required this.accentColor,
    required this.isFavorite,
    required this.showFavoriteStar,
    required this.isTight,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final panelColor = colorScheme.brightness == Brightness.dark ? Colors.white : colorScheme.surface;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTight ? 8 : 10, vertical: isTight ? 6 : 8),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                type.id,
                style: TextStyle(
                  fontSize: isTight ? 10 : 11,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  letterSpacing: 0.5,
                ),
              ),
              if (isFavorite && showFavoriteStar) ...[
                const SizedBox(width: 6),
                Icon(Icons.star, size: isTight ? 13 : 14, color: Colors.amber[700]),
              ],
            ],
          ),
          SizedBox(height: isTight ? 3 : 5),
          Text(
            type.navn,
            maxLines: isTight ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isTight ? 12 : 14,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: colorScheme.brightness == Brightness.dark ? Colors.black87 : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, this.color = Colors.green});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
