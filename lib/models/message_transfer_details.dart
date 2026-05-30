class MessageTransferDownloader {
  final String requesterKey6;
  final String? requesterName;
  final int transferCount;
  final DateTime lastTransferredAt;

  const MessageTransferDownloader({
    required this.requesterKey6,
    this.requesterName,
    required this.transferCount,
    required this.lastTransferredAt,
  });

  MessageTransferDownloader copyWith({
    String? requesterKey6,
    String? requesterName,
    int? transferCount,
    DateTime? lastTransferredAt,
  }) {
    return MessageTransferDownloader(
      requesterKey6: requesterKey6 ?? this.requesterKey6,
      requesterName: requesterName ?? this.requesterName,
      transferCount: transferCount ?? this.transferCount,
      lastTransferredAt: lastTransferredAt ?? this.lastTransferredAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requesterKey6': requesterKey6,
      'requesterName': requesterName,
      'transferCount': transferCount,
      'lastTransferredAtMillis': lastTransferredAt.millisecondsSinceEpoch,
    };
  }

  static MessageTransferDownloader? fromJson(Map<String, dynamic> json) {
    final requesterKey6 = json['requesterKey6'];
    final transferCount = json['transferCount'];
    final lastTransferredAtMillis = json['lastTransferredAtMillis'];
    if (requesterKey6 is! String ||
        transferCount is! int ||
        lastTransferredAtMillis is! int) {
      return null;
    }

    return MessageTransferDownloader(
      requesterKey6: requesterKey6,
      requesterName: json['requesterName'] as String?,
      transferCount: transferCount,
      lastTransferredAt: DateTime.fromMillisecondsSinceEpoch(
        lastTransferredAtMillis,
      ),
    );
  }
}

class MessageTransferCompletion {
  final String requesterKey6;
  final String? requesterName;
  final int completionCount;
  final DateTime lastCompletedAt;

  const MessageTransferCompletion({
    required this.requesterKey6,
    this.requesterName,
    required this.completionCount,
    required this.lastCompletedAt,
  });

  MessageTransferCompletion copyWith({
    String? requesterKey6,
    String? requesterName,
    int? completionCount,
    DateTime? lastCompletedAt,
  }) {
    return MessageTransferCompletion(
      requesterKey6: requesterKey6 ?? this.requesterKey6,
      requesterName: requesterName ?? this.requesterName,
      completionCount: completionCount ?? this.completionCount,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requesterKey6': requesterKey6,
      'requesterName': requesterName,
      'completionCount': completionCount,
      'lastCompletedAtMillis': lastCompletedAt.millisecondsSinceEpoch,
    };
  }

  static MessageTransferCompletion? fromJson(Map<String, dynamic> json) {
    final requesterKey6 = json['requesterKey6'];
    final completionCount = json['completionCount'];
    final lastCompletedAtMillis = json['lastCompletedAtMillis'];
    if (requesterKey6 is! String ||
        completionCount is! int ||
        lastCompletedAtMillis is! int) {
      return null;
    }

    return MessageTransferCompletion(
      requesterKey6: requesterKey6,
      requesterName: json['requesterName'] as String?,
      completionCount: completionCount,
      lastCompletedAt: DateTime.fromMillisecondsSinceEpoch(
        lastCompletedAtMillis,
      ),
    );
  }
}

class MessageTransferDetails {
  final int totalTransfers;
  final int totalCompletedTransfers;
  final List<MessageTransferDownloader> downloaders;
  final List<MessageTransferCompletion> completions;

  const MessageTransferDetails({
    required this.totalTransfers,
    required this.totalCompletedTransfers,
    required this.downloaders,
    required this.completions,
  });

  const MessageTransferDetails.empty()
    : totalTransfers = 0,
      totalCompletedTransfers = 0,
      downloaders = const [],
      completions = const [];

  MessageTransferDetails registerTransfer({
    required String requesterKey6,
    String? requesterName,
    DateTime? transferredAt,
  }) {
    final eventAt = transferredAt ?? DateTime.now();
    final normalizedName = requesterName?.trim();
    final updatedDownloaders = List<MessageTransferDownloader>.from(
      downloaders,
    );
    final index = updatedDownloaders.indexWhere(
      (entry) => entry.requesterKey6 == requesterKey6,
    );

    if (index == -1) {
      updatedDownloaders.add(
        MessageTransferDownloader(
          requesterKey6: requesterKey6,
          requesterName: normalizedName?.isEmpty ?? true
              ? null
              : normalizedName,
          transferCount: 1,
          lastTransferredAt: eventAt,
        ),
      );
    } else {
      final existing = updatedDownloaders[index];
      updatedDownloaders[index] = existing.copyWith(
        requesterName: normalizedName?.isEmpty ?? true
            ? existing.requesterName
            : normalizedName,
        transferCount: existing.transferCount + 1,
        lastTransferredAt: eventAt,
      );
    }

    updatedDownloaders.sort(
      (a, b) => b.lastTransferredAt.compareTo(a.lastTransferredAt),
    );

    return MessageTransferDetails(
      totalTransfers: totalTransfers + 1,
      totalCompletedTransfers: totalCompletedTransfers,
      downloaders: updatedDownloaders,
      completions: completions,
    );
  }

  MessageTransferDetails registerCompletion({
    required String requesterKey6,
    String? requesterName,
    DateTime? completedAt,
  }) {
    final eventAt = completedAt ?? DateTime.now();
    final normalizedName = requesterName?.trim();
    final updatedCompletions = List<MessageTransferCompletion>.from(completions);
    final index = updatedCompletions.indexWhere(
      (entry) => entry.requesterKey6 == requesterKey6,
    );

    if (index == -1) {
      updatedCompletions.add(
        MessageTransferCompletion(
          requesterKey6: requesterKey6,
          requesterName: normalizedName?.isEmpty ?? true
              ? null
              : normalizedName,
          completionCount: 1,
          lastCompletedAt: eventAt,
        ),
      );
    } else {
      final existing = updatedCompletions[index];
      updatedCompletions[index] = existing.copyWith(
        requesterName: normalizedName?.isEmpty ?? true
            ? existing.requesterName
            : normalizedName,
        completionCount: existing.completionCount + 1,
        lastCompletedAt: eventAt,
      );
    }

    updatedCompletions.sort(
      (a, b) => b.lastCompletedAt.compareTo(a.lastCompletedAt),
    );

    return MessageTransferDetails(
      totalTransfers: totalTransfers,
      totalCompletedTransfers: totalCompletedTransfers + 1,
      downloaders: downloaders,
      completions: updatedCompletions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTransfers': totalTransfers,
      'totalCompletedTransfers': totalCompletedTransfers,
      'downloaders': downloaders.map((entry) => entry.toJson()).toList(),
      'completions': completions.map((entry) => entry.toJson()).toList(),
    };
  }

  static MessageTransferDetails? fromJson(Map<String, dynamic> json) {
    final totalTransfers = json['totalTransfers'];
    if (totalTransfers is! int) {
      return null;
    }

    final totalCompletedTransfers =
        json['totalCompletedTransfers'] is int
            ? json['totalCompletedTransfers'] as int
            : 0;

    final rawDownloaders = json['downloaders'] as List<dynamic>? ?? const [];
    final downloaders = rawDownloaders
        .whereType<Map<String, dynamic>>()
        .map(MessageTransferDownloader.fromJson)
        .whereType<MessageTransferDownloader>()
        .toList();

    final rawCompletions = json['completions'] as List<dynamic>? ?? const [];
    final completions = rawCompletions
        .whereType<Map<String, dynamic>>()
        .map(MessageTransferCompletion.fromJson)
        .whereType<MessageTransferCompletion>()
        .toList();

    return MessageTransferDetails(
      totalTransfers: totalTransfers,
      totalCompletedTransfers: totalCompletedTransfers,
      downloaders: downloaders,
      completions: completions,
    );
  }
}
