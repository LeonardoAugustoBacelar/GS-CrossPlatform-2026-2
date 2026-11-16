import '../domain/sector.dart';

/// Território analisado: Subprefeitura de M'Boi Mirim, Zona Sul de São Paulo.
///
/// Escolhido por reunir os três temas do desafio: calor e chuva forte em
/// áreas de encosta, abastecimento de água às margens da Represa Guarapiranga
/// e alta demanda por serviços públicos em uma região de alta vulnerabilidade.
abstract final class TerritoryConfig {
  static const String name = "M'Boi Mirim";
  static const String region = 'Zona Sul de São Paulo, SP';
  static const String description =
      'Subprefeitura formada pelos distritos de Jardim Ângela e Jardim São '
      'Luís, na margem oeste da Represa Guarapiranga.';

  /// Ponto usado para consultar clima e qualidade do ar.
  static const double latitude = -23.695;
  static const double longitude = -46.758;

  static const List<Sector> sectors = [
    Sector(
      id: 'ja-norte',
      name: 'Jardim Ângela Norte',
      description: 'Área mais adensada do distrito, com encostas ocupadas.',
      population: 160000,
      latitude: -23.692,
      longitude: -46.762,
      healthDailyCapacity: 420,
    ),
    Sector(
      id: 'ja-sul',
      name: 'Jardim Ângela Sul',
      description: 'Área próxima à Represa Guarapiranga e a mananciais.',
      population: 140000,
      latitude: -23.735,
      longitude: -46.780,
      healthDailyCapacity: 360,
    ),
    Sector(
      id: 'jsl-oeste',
      name: 'Jardim São Luís Oeste',
      description: 'Bairros residenciais ao longo da Estrada do M’Boi Mirim.',
      population: 130000,
      latitude: -23.668,
      longitude: -46.758,
      healthDailyCapacity: 340,
    ),
    Sector(
      id: 'jsl-leste',
      name: 'Jardim São Luís Leste',
      description: 'Área de comércio e corredores de ônibus.',
      population: 140000,
      latitude: -23.660,
      longitude: -46.728,
      healthDailyCapacity: 380,
    ),
  ];

  static int get totalPopulation =>
      sectors.fold(0, (sum, sector) => sum + sector.population);

  static int get totalHealthCapacity =>
      sectors.fold(0, (sum, sector) => sum + sector.healthDailyCapacity);

  static Sector sectorById(String id) =>
      sectors.firstWhere((sector) => sector.id == id);
}
