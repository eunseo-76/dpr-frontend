class ProductionOverviewRow {
  final int clientId;
  final String clientName;
  final int processId;
  final String processName;
  final int unitId;
  final String unitName;
  final double result;

  ProductionOverviewRow({
    required this.clientId,
    required this.clientName,
    required this.processId,
    required this.processName,
    required this.unitId,
    required this.unitName,
    required this.result,
  });

  factory ProductionOverviewRow.fromJson(Map<String, dynamic> json) {
    return ProductionOverviewRow(
      clientId: json['clientId'] as int,
      clientName: json['clientName'] as String,
      processId: json['processId'] as int,
      processName: json['processName'] as String,
      unitId: json['unitId'] as int,
      unitName: json['unitName'] as String,
      result: (json['result'] as num).toDouble(),
    );
  }
}

class ProcessSummaryEntry {
  final int processId;
  final String processName;
  final int unitId;
  final String unitName;
  final double result;

  ProcessSummaryEntry({
    required this.processId,
    required this.processName,
    required this.unitId,
    required this.unitName,
    required this.result,
  });

  factory ProcessSummaryEntry.fromJson(Map<String, dynamic> json) {
    return ProcessSummaryEntry(
      processId: json['processId'] as int,
      processName: json['processName'] as String,
      unitId: json['unitId'] as int,
      unitName: json['unitName'] as String,
      result: (json['result'] as num).toDouble(),
    );
  }
}

class ProductionOverview {
  final List<ProductionOverviewRow> rows;
  final List<ProcessSummaryEntry> processSummary;

  ProductionOverview({required this.rows, required this.processSummary});

  factory ProductionOverview.fromJson(Map<String, dynamic> json) {
    return ProductionOverview(
      rows: (json['rows'] as List)
          .map((e) => ProductionOverviewRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      processSummary: (json['processSummary'] as List)
          .map((e) => ProcessSummaryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
