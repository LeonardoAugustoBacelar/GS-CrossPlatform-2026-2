import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/territory_config.dart';
import '../../../core/domain/sector.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../alerts/application/alerts_providers.dart';
import '../../alerts/domain/territory_alert.dart';
import '../../alerts/presentation/widgets/alert_widgets.dart';

/// Mapa dos setores com a severidade dos alertas. Abaixo do mapa, a mesma
/// informação em lista, para quem usa leitor de tela.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertReportProvider).value?.alerts ?? const [];
    List<TerritoryAlert> alertsOf(Sector sector) =>
        alerts.where((a) => a.sectorIds.contains(sector.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa do território')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: ExcludeSemantics(
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(
                    TerritoryConfig.latitude,
                    TerritoryConfig.longitude,
                  ),
                  initialZoom: 12.4,
                  minZoom: 10,
                  maxZoom: 17,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'br.fiap.gs.mirante',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final sector in TerritoryConfig.sectors)
                        Marker(
                          point: LatLng(sector.latitude, sector.longitude),
                          width: 52,
                          height: 52,
                          child: _SectorMarker(
                            alerts: alertsOf(sector),
                            onTap: () =>
                                _showSector(context, sector, alertsOf(sector)),
                          ),
                        ),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('Colaboradores do OpenStreetMap'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: ListView(
              padding: AppSpacing.screen,
              children: [
                for (final sector in TerritoryConfig.sectors)
                  _SectorTile(
                    sector: sector,
                    alerts: alertsOf(sector),
                    onTap: () => _showSector(context, sector, alertsOf(sector)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _showSector(
    BuildContext context,
    Sector sector,
    List<TerritoryAlert> alerts,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, controller) => Consumer(
          builder: (context, ref, _) => ListView(
            controller: controller,
            padding: AppSpacing.screen,
            children: [
              Text(sector.name, style: Theme.of(context).textTheme.titleLarge),
              Text(
                '${Fmt.compact(sector.population)} moradores · '
                '${sector.description}',
              ),
              const SizedBox(height: AppSpacing.md),
              if (alerts.isEmpty)
                const Text('Nenhum alerta ativo neste setor.')
              else
                for (final alert in alerts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AlertTile(
                      alert: alert,
                      today: ref.watch(clockProvider)(),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

AlertSeverity? _worst(List<TerritoryAlert> alerts) => alerts.isEmpty
    ? null
    : alerts
          .map((a) => a.severity)
          .reduce((a, b) => a.index >= b.index ? a : b);

class _SectorMarker extends StatelessWidget {
  const _SectorMarker({required this.alerts, required this.onTap});

  final List<TerritoryAlert> alerts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final worst = _worst(alerts);
    final color = worst?.color(context) ?? scheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.surface, width: 3),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
        ),
        alignment: Alignment.center,
        child: worst == null
            ? Icon(Icons.check, color: scheme.surface)
            : Text(
                '${alerts.length}',
                style: TextStyle(
                  color: scheme.surface,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }
}

class _SectorTile extends StatelessWidget {
  const _SectorTile({
    required this.sector,
    required this.alerts,
    required this.onTap,
  });

  final Sector sector;
  final List<TerritoryAlert> alerts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final worst = _worst(alerts);
    return Card(
      child: ListTile(
        leading: Icon(
          worst?.icon ?? Icons.check_circle_outline,
          color: worst?.color(context) ?? Theme.of(context).colorScheme.primary,
        ),
        title: Text(sector.name),
        subtitle: Text(
          '${Fmt.compact(sector.population)} moradores · '
          '${alerts.isEmpty ? 'sem alertas' : '${alerts.length} ${alerts.length == 1 ? 'alerta' : 'alertas'}, o mais grave: ${worst!.label.toLowerCase()}'}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
