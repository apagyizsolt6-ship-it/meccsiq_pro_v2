/*
===========================================
MeccsIQ Pro v2.0
Build: #006
Version: v2.0.0
File: ai_prediction_model.dart
===========================================
*/

class AiPredictionModel {
  const AiPredictionModel({
    required this.score,
    required this.homeProbability,
    required this.drawProbability,
    required this.awayProbability,

    this.confidence = 0,

    this.isValueBet = false,

    this.recommendation,

    this.reason,

    this.updatedAt,
  });

  /// AI pontszám (0-100)
  final int score;

  /// Hazai győzelem %
  final double homeProbability;

  /// Döntetlen %
  final double drawProbability;

  /// Vendég győzelem %
  final double awayProbability;

  /// Biztonsági szint (0-100)
  final int confidence;

  /// Value Bet
  final bool isValueBet;

  /// AI ajánlás
  final String? recommendation;

  /// Rövid indoklás
  final String? reason;

  /// Frissítés ideje
  final DateTime? updatedAt;

  bool get isHighConfidence => confidence >= 85;

  bool get isStrongTip => score >= 90;

  AiPredictionModel copyWith({
    int? score,
    double? homeProbability,
    double? drawProbability,
    double? awayProbability,
    int? confidence,
    bool? isValueBet,
    String? recommendation,
    String? reason,
    DateTime? updatedAt,
  }) {
    return AiPredictionModel(
      score: score ?? this.score,
      homeProbability:
          homeProbability ?? this.homeProbability,
      drawProbability:
          drawProbability ?? this.drawProbability,
      awayProbability:
          awayProbability ?? this.awayProbability,
      confidence: confidence ?? this.confidence,
      isValueBet: isValueBet ?? this.isValueBet,
      recommendation:
          recommendation ?? this.recommendation,
      reason: reason ?? this.reason,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'homeProbability': homeProbability,
      'drawProbability': drawProbability,
      'awayProbability': awayProbability,
      'confidence': confidence,
      'isValueBet': isValueBet,
      'recommendation': recommendation,
      'reason': reason,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory AiPredictionModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return AiPredictionModel(
      score: map['score'] ?? 0,
      homeProbability:
          (map['homeProbability'] as num).toDouble(),
      drawProbability:
          (map['drawProbability'] as num).toDouble(),
      awayProbability:
          (map['awayProbability'] as num).toDouble(),
      confidence: map['confidence'] ?? 0,
      isValueBet: map['isValueBet'] ?? false,
      recommendation: map['recommendation'],
      reason: map['reason'],
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }
}
