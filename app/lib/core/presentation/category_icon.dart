import 'package:flutter/material.dart';

IconData iconForCategory(String iconKey) {
  switch (iconKey) {
    case 'food_drinks':
      return Icons.restaurant;
    case 'transport':
      return Icons.directions_bus;
    case 'shopping':
      return Icons.shopping_bag_outlined;
    case 'bills':
      return Icons.receipt_long_outlined;
    case 'health':
      return Icons.favorite_border;
    case 'other':
      return Icons.category_outlined;
    default:
      return Icons.category_outlined;
  }
}
