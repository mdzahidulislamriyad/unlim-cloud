class CloudFolder {
  final String id;
  final String name;
  final String? parentId;
  final DateTime createdAt;

  CloudFolder({
    required this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CloudFolder.fromJson(Map<String, dynamic> json) {
    return CloudFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
