import 'package:flutter/material.dart';

/// Returns the most appropriate [IconData] for a listing specification label.
IconData iconForSpec(String label) {
  switch (label.toLowerCase()) {
    case 'year':
    case 'calendar':
      return Icons.calendar_today;
    case 'mileage':
    case 'speed':
      return Icons.speed;
    case 'transmission':
      return Icons.settings;
    case 'fuel type':
    case 'gas':
      return Icons.local_gas_station;
    case 'bedrooms':
    case 'bed':
      return Icons.bed;
    case 'bathrooms':
    case 'bath':
      return Icons.bathtub;
    case 'area':
    case 'size':
      return Icons.square_foot;
    case 'security':
      return Icons.security;
    case 'land use':
      return Icons.foundation;
    case 'title deed':
      return Icons.description;
    default:
      return Icons.info_outline;
  }
}
