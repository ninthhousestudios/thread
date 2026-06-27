enum HealthCategory {
  organizational(3.5),
  structural(2.5),
  coupling(2.0),
  freshness(1.5),
  coverage(2.0);

  final double cap;
  const HealthCategory(this.cap);
}

const _biomarkerWeights = <String, (double, HealthCategory)>{
  'cochange_scatter': (1.80, HealthCategory.organizational),
  'change_entropy': (1.51, HealthCategory.organizational),
  'ownership_risk': (1.38, HealthCategory.organizational),
  'nested_complexity': (1.34, HealthCategory.structural),
  'function_hotspot': (1.16, HealthCategory.structural),
  'blast_radius_churn': (1.00, HealthCategory.structural),
  'hidden_coupling': (1.00, HealthCategory.coupling),
  'component_instability': (0.50, HealthCategory.coupling),
  'code_age_volatility': (1.10, HealthCategory.freshness),
  'hrr_shape_change': (0.50, HealthCategory.freshness),
  'dead_code_ratio': (0.80, HealthCategory.coverage),
  'coverage_gradient': (0.80, HealthCategory.coverage),
  'convention_drift': (0.50, HealthCategory.coverage),
};

double _severityWeight(String severity) => severity == 'advisory' ? 1.0 : 0.5;

double scoreFile(List<Map<String, dynamic>> findings) {
  final byCategory = <HealthCategory, double>{};
  for (final f in findings) {
    final entry = _biomarkerWeights[f['biomarker_kind'] as String];
    if (entry == null) continue;
    final (weight, category) = entry;
    final raw = _severityWeight(f['severity'] as String) * weight;
    byCategory[category] = (byCategory[category] ?? 0.0) + raw;
  }

  var totalDeduction = 0.0;
  for (final entry in byCategory.entries) {
    final capped = entry.value > entry.key.cap ? entry.key.cap : entry.value;
    totalDeduction += capped;
  }

  return (10.0 - totalDeduction).clamp(1.0, 10.0);
}

double scoreComponent(List<(double, int)> fileScores) {
  var totalNloc = 0;
  var weightedSum = 0.0;
  for (final (score, nloc) in fileScores) {
    totalNloc += nloc;
    weightedSum += score * nloc;
  }
  if (totalNloc == 0) return 10.0;
  return (weightedSum / totalNloc).clamp(1.0, 10.0);
}
