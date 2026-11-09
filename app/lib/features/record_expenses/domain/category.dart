class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.isActive,
    required this.isProtected,
  });

  final String id;
  final String name;
  final String iconKey;
  final bool isActive;
  final bool isProtected;
}
