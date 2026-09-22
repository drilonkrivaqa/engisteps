import 'package:flutter/material.dart';

IconData categoryIcon(String category) => switch (category) {
  'Math' => Icons.functions,
  'Physics' => Icons.bolt_outlined,
  'Circuits' => Icons.memory_outlined,
  'Mechanics' => Icons.precision_manufacturing_outlined,
  'Fluid' => Icons.water_drop_outlined,
  'Thermo' => Icons.thermostat_outlined,
  'Electrical' => Icons.electrical_services_outlined,
  'Academic' => Icons.school_outlined,
  _ => Icons.calculate_outlined,
};
