import 'package:flutter/material.dart';

IconData categoryIconData(String icon) =>
    categoryIconOptions[icon] ?? Icons.attach_money;

IconData walletIconData(String type) {
  return switch (type) {
    'cash' => Icons.payments_outlined,
    'ewallet' => Icons.account_balance_wallet_outlined,
    // Legacy key kept so existing rows still resolve to an icon.
    'gcash' => Icons.phone_android_outlined,
    'bank' => Icons.account_balance_outlined,
    _ => Icons.wallet_outlined,
  };
}

const categoryIconOptions = <String, IconData>{
  'food': Icons.restaurant_outlined,
  'transport': Icons.directions_car_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'bills': Icons.receipt_outlined,
  'health': Icons.favorite_outline,
  'entertainment': Icons.movie_outlined,
  'savings': Icons.savings_outlined,
  'salary': Icons.work_outline,
  'freelance': Icons.laptop_outlined,
  'business': Icons.business_center_outlined,
  'investment': Icons.trending_up_outlined,
  'allowance': Icons.wallet_outlined,
  'education': Icons.school_outlined,
  'coffee': Icons.local_cafe_outlined,
  'fitness': Icons.fitness_center_outlined,
  'pets': Icons.pets_outlined,
  'travel': Icons.flight_outlined,
  'gifts': Icons.card_giftcard_outlined,
  'subscriptions': Icons.subscriptions_outlined,
};

const categoryColorOptions = <String>[
  '#FF6B6B',
  '#4ECDC4',
  '#A78BFA',
  '#F97316',
  '#1D9E75',
  '#007DFF',
  '#AB47BC',
  '#FF5B5B',
  '#FFA726',
  '#4B9FFF',
  '#EC4899',
  '#8B5CF6',
  '#14B8A6',
  '#F59E0B',
  '#EF4444',
  '#10B981',
];
