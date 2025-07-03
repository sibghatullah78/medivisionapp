
class Medicine {
  final String name; // Maps to medicine_name
  final String? genericName; // Maps to generic_name
  final String? strength;
  final List<String>? uses;
  final Dosage? dosage;
  final SideEffects? sideEffects;
  final List<String>? precautions;
  final List<String>? interactions;
  final List<String>? warnings;
  // Keep existing fields for backward compatibility with MEDICINES_API
  final String? frequency;
  final String? type;
  final String? duration;
  final String? instructions;

  Medicine({
    required this.name,
    this.genericName,
    this.strength,
    this.uses,
    this.dosage,
    this.sideEffects,
    this.precautions,
    this.interactions,
    this.warnings,
    this.frequency,
    this.type,
    this.duration,
    this.instructions,
  });

  // Factory to create Medicine from JSON (backend response)
  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['medicine_name'] ?? '',
      genericName: json['generic_name'],
      strength: json['strength'],
      uses: json['uses'] != null ? List<String>.from(json['uses']) : null,
      dosage: json['dosage'] != null
          ? Dosage.fromJson(json['dosage'])
          : null,
      sideEffects: json['side_effects'] != null
          ? SideEffects.fromJson(json['side_effects'])
          : null,
      precautions: json['precautions'] != null
          ? List<String>.from(json['precautions'])
          : null,
      interactions: json['interactions'] != null
          ? List<String>.from(json['interactions'])
          : null,
      warnings: json['warnings'] != null
          ? List<String>.from(json['warnings'])
          : null,
      // Default to null for fields not provided by backend
      frequency: null,
      type: null,
      duration: null,
      instructions: null,
    );
  }

  // Factory to create Medicine from map (for scanData or existing data)
  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      name: map['name'] ?? '',
      genericName: map['generic_name'],
      strength: map['strength'],
      uses: map['uses'] != null ? List<String>.from(map['uses']) : null,
      dosage: map['dosage'] != null
          ? Dosage.fromJson(map['dosage'])
          : null,
      sideEffects: map['side_effects'] != null
          ? SideEffects.fromJson(map['side_effects'])
          : null,
      precautions: map['precautions'] != null
          ? List<String>.from(map['precautions'])
          : null,
      interactions: map['interactions'] != null
          ? List<String>.from(map['interactions'])
          : null,
      warnings: map['warnings'] != null
          ? List<String>.from(map['warnings'])
          : null,
      frequency: map['frequency'],
      type: map['type'],
      duration: map['duration'],
      instructions: map['instructions'],
    );
  }

  // Convert Medicine to JSON for backend or storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (genericName != null) 'generic_name': genericName,
      if (strength != null) 'strength': strength,
      if (uses != null) 'uses': uses,
      if (dosage != null) 'dosage': dosage!.toJson(),
      if (sideEffects != null) 'side_effects': sideEffects!.toJson(),
      if (precautions != null) 'precautions': precautions,
      if (interactions != null) 'interactions': interactions,
      if (warnings != null) 'warnings': warnings,
      if (frequency != null) 'frequency': frequency,
      if (type != null) 'type': type,
      if (duration != null) 'duration': duration,
      if (instructions != null) 'instructions': instructions,
    };
  }
}

class Dosage {
  final String? adults;
  final String? children;
  final String? maxDaily;

  Dosage({
    this.adults,
    this.children,
    this.maxDaily,
  });

  factory Dosage.fromJson(Map<String, dynamic> json) {
    return Dosage(
      adults: json['adults'],
      children: json['children'],
      maxDaily: json['max_daily'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (adults != null) 'adults': adults,
      if (children != null) 'children': children,
      if (maxDaily != null) 'max_daily': maxDaily,
    };
  }
}

class SideEffects {
  final List<String>? common;
  final List<String>? serious;

  SideEffects({
    this.common,
    this.serious,
  });

  factory SideEffects.fromJson(Map<String, dynamic> json) {
    return SideEffects(
      common: json['common'] != null ? List<String>.from(json['common']) : null,
      serious: json['serious'] != null ? List<String>.from(json['serious']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (common != null) 'common': common,
      if (serious != null) 'serious': serious,
    };
  }
}
