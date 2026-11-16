/// Território analisado pelo app.
///
/// O grupo ainda vai escolher o território. Quando decidir, troque o nome e as
/// coordenadas aqui: o resto do app (clima, mapa, textos) lê deste arquivo.
abstract final class TerritoryConfig {
  static const String name = 'Território a definir';
  static const String region = 'São Paulo, SP';
  static const double latitude = -23.5505;
  static const double longitude = -46.6333;
}
