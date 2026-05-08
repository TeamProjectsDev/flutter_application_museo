class ArtifactDetail {
  final String title;
  final String subtitle;
  final String category;
  final String description;
  final String history;
  final String origin;
  final String material;
  final String dimensions;
  final String accessionNo;

  ArtifactDetail({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.description,
    required this.history,
    required this.origin,
    required this.material,
    required this.dimensions,
    required this.accessionNo,
  });
}

class MuseumArtifactManager {
  static ArtifactDetail getDetail(String fileName, String room) {
    final lower = fileName.toLowerCase();

    // 👨 Mandíbula Hombre
    if (lower.contains('mandibula_hombre')) {
      return ArtifactDetail(
        title: 'Mandíbula Humana (Masculina)',
        subtitle: 'Modelo Anatómico de Estudio',
        category: 'ANTROPOLOGÍA / ANATOMÍA',
        description: 'Estructura ósea inferior de un cráneo masculino. Se distingue por su robustez y una sínfisis mentoniana de forma cuadrangular.',
        history: 'Pieza utilizada históricamente para el estudio de la dimorfismo sexual en la osteología humana. Permite observar las inserciones de los músculos maseteros.',
        origin: 'Colección de Anatomía, IES Padre Suárez',
        material: 'Resina Sintética / Hueso Natural',
        dimensions: '12.5 × 10.2 cm',
        accessionNo: 'MS-ANT-H01',
      );
    }

    // 👩 Mandíbula Mujer
    if (lower.contains('mandibula_mujer')) {
      return ArtifactDetail(
        title: 'Mandíbula Humana (Femenina)',
        subtitle: 'Modelo Anatómico de Estudio',
        category: 'ANTROPOLOGÍA / ANATOMÍA',
        description: 'Estructura ósea inferior de un cráneo femenino. Presenta rasgos más gráciles, con un mentón redondeado y un ángulo mandibular más obtuso.',
        history: 'Ejemplar de referencia para el análisis comparativo de las estructuras craneofaciales entre sexos en el ámbito de la antropología física.',
        origin: 'Colección de Anatomía, IES Padre Suárez',
        material: 'Resina Sintética / Hueso Natural',
        dimensions: '11.2 × 9.5 cm',
        accessionNo: 'MS-ANT-M02',
      );
    }

    // Default Fallback (para entornos u otros archivos)
    return ArtifactDetail(
      title: fileName.replaceAll('.glb', '').replaceAll('_', ' ').toUpperCase(),
      subtitle: 'Pieza de la Colección',
      category: room.toUpperCase(),
      description: 'Esta pieza forma parte de la colección didáctica del Museo Padre Suárez.',
      history: 'Preservada para el estudio y divulgación científica en el gabinete de historia natural del instituto.',
      origin: 'IES Padre Suárez, Granada',
      material: 'Varios',
      dimensions: 'N/A',
      accessionNo: 'MS-GEN-${fileName.length}',
    );
  }
}
