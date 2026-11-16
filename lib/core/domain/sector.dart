/// Setor de análise dentro do território.
///
/// Os setores são uma divisão feita pelo grupo para análise (não são divisões
/// oficiais). População e capacidade das UBS são estimativas arredondadas.
class Sector {
  const Sector({
    required this.id,
    required this.name,
    required this.description,
    required this.population,
    required this.latitude,
    required this.longitude,
    required this.healthDailyCapacity,
  });

  final String id;
  final String name;
  final String description;
  final int population;
  final double latitude;
  final double longitude;

  /// Atendimentos por dia que as UBS do setor conseguem absorver.
  final int healthDailyCapacity;
}
