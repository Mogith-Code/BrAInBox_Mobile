import 'package:flutter/material.dart';

import '../../../widgets/admin_page.dart';

// RAG source documents (admin). Backend: `api/modules/content/schemas.py`
// (`RagSourceOut`, `RagJobOut`) and `shared/enums.py` (`SourceType`).

/// Ingestion status: `pending | ingesting | ready | failed`.
enum RagSourceStatus {
  pending('Waiting', BadgeTone.neutral, Icons.schedule),
  ingesting('Ingesting', BadgeTone.info, Icons.sync),
  ready('Ready', BadgeTone.success, Icons.check_circle_outline),
  failed('Failed', BadgeTone.danger, Icons.error_outline);

  const RagSourceStatus(this.label, this.tone, this.icon);

  final String label;
  final BadgeTone tone;
  final IconData icon;

  /// Still being chunked + embedded (the list refreshes until it isn't).
  bool get isWorking => this == pending || this == ingesting;

  static RagSourceStatus fromApi(String? value) => switch (value) {
    'ingesting' => ingesting,
    'ready' => ready,
    'failed' => failed,
    _ => pending,
  };
}

/// What kind of approved document it is (backend `SourceType`).
enum RagSourceType {
  syllabus('syllabus', 'Syllabus'),
  nieResourceBook('nie_resource_book', 'NIE resource book'),
  teachersGuide('teachers_guide', "Teacher's guide"),
  approvedNote('approved_note', 'Approved notes'),
  markingScheme('marking_scheme', 'Marking scheme'),
  pastPaper('past_paper', 'Past paper'),
  other('other', 'Other');

  const RagSourceType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static String labelOf(String apiValue) => switch (apiValue) {
    // An older value the ingestion scripts still write.
    'teacher_guide' => teachersGuide.label,
    _ =>
      values.where((t) => t.apiValue == apiValue).firstOrNull?.label ??
          apiValue,
  };
}

/// One row of `GET /admin/rag/sources`.
class RagSource {
  const RagSource({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.status,
    required this.updatedAt,
    this.unitNumber,
    this.year,
    this.chunkCount = 0,
    this.pageCount,
    this.errorMessage,
    this.indexedAt,
  });

  factory RagSource.fromJson(Map<String, dynamic> json) => RagSource(
    id: '${json['id']}',
    title: json['title'] as String? ?? '',
    sourceType: json['source_type'] as String? ?? 'other',
    unitNumber: (json['unit_number'] as num?)?.toInt(),
    year: (json['year'] as num?)?.toInt(),
    status: RagSourceStatus.fromApi(json['status'] as String?),
    chunkCount: (json['chunk_count'] as num?)?.toInt() ?? 0,
    pageCount: (json['page_count'] as num?)?.toInt(),
    errorMessage: json['error_message'] as String?,
    indexedAt: _date(json['indexed_at']),
    updatedAt: _date(json['updated_at']) ?? DateTime(2000),
  );

  final String id;
  final String title;

  /// Backend `SourceType` value; [RagSourceType.labelOf] names it.
  final String sourceType;
  final int? unitNumber;
  final int? year;
  final RagSourceStatus status;
  final int chunkCount;
  final int? pageCount;
  final String? errorMessage;
  final DateTime? indexedAt;
  final DateTime updatedAt;
}

DateTime? _date(Object? v) =>
    v == null ? null : DateTime.tryParse('$v')?.toLocal();

/// `202 {job_id, document_id}` of upload / re-index.
class RagJob {
  const RagJob({required this.jobId, this.documentId});

  factory RagJob.fromJson(Map<String, dynamic> json) => RagJob(
    jobId: '${json['job_id']}',
    documentId: json['document_id'] == null ? null : '${json['document_id']}',
  );

  final String jobId;

  /// Null for "re-index everything".
  final String? documentId;
}

/// The upload form's fields (the file itself travels separately).
class RagUpload {
  const RagUpload({
    required this.title,
    required this.type,
    this.unitNumber,
    this.year,
  });

  final String title;
  final RagSourceType type;
  final int? unitNumber;
  final int? year;

  Map<String, dynamic> toFields() => {
    'title': title,
    'source_type': type.apiValue,
    'unit_number': ?unitNumber,
    'year': ?year,
  };
}
