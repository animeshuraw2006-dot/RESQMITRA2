import 'package:flutter/material.dart';

/// The 15 appreciation badges (artwork cut from the ResQ-Mitra badge sheet).
class BadgeDef {
  final String key, title, blurb, asset;
  final Color color;
  const BadgeDef(this.key, this.title, this.blurb, this.asset, this.color);
}

const kBadges = <BadgeDef>[
  BadgeDef('life_saver', 'Life Saver', 'Thank you for being there when it mattered most.', 'assets/badges/life_saver.png', Color(0xFFFF3B4E)),
  BadgeDef('accident_angel', 'Accident Angel', 'You turned a stressful moment into a safer one.', 'assets/badges/accident_angel.png', Color(0xFFFFB81F)),
  BadgeDef('medical_hero', 'Medical Hero', 'Your quick response brought hope and healing.', 'assets/badges/medical_hero.png', Color(0xFF22A7FF)),
  BadgeDef('fire_fighter', 'Fire Fighter', 'Courage, quick action and a big heart!', 'assets/badges/fire_fighter.png', Color(0xFFFF6A1A)),
  BadgeDef('flood_warrior', 'Flood Warrior', 'You stood strong when waters rose.', 'assets/badges/flood_warrior.png', Color(0xFF2CC4FF)),
  BadgeDef('rescue_champ', 'Rescue Champ', 'You go beyond limits to save lives.', 'assets/badges/rescue_champ.png', Color(0xFF3FD84A)),
  BadgeDef('womens_safety_guardian', "Women's Safety Guardian", 'You made a difference when it mattered most.', 'assets/badges/womens_safety_guardian.png', Color(0xFFC04BFF)),
  BadgeDef('child_care_hero', 'Child Care Hero', 'You keep our little ones safe and sound.', 'assets/badges/child_care_hero.png', Color(0xFF19D3E6)),
  BadgeDef('location_legend', 'Location Legend', 'You were right there when we needed you.', 'assets/badges/location_legend.png', Color(0xFF5B6BFF)),
  BadgeDef('team_player', 'Team Player', 'Your support means the world.', 'assets/badges/team_player.png', Color(0xFFA066FF)),
  BadgeDef('reliable_responder', 'Reliable Responder', 'Always ready, always dependable.', 'assets/badges/reliable_responder.png', Color(0xFFFFC53D)),
  BadgeDef('community_supporter', 'Community Supporter', 'You care, you help, you make a difference.', 'assets/badges/community_supporter.png', Color(0xFF45D66B)),
  BadgeDef('brave_soul', 'Brave Soul', 'Not all heroes wear capes, some wear your badge.', 'assets/badges/brave_soul.png', Color(0xFF4F7BFF)),
  BadgeDef('hope_giver', 'Hope Giver', 'You bring hope in difficult times.', 'assets/badges/hope_giver.png', Color(0xFFFF8A2B)),
  BadgeDef('special_thanks', 'Special Thanks', 'Just... Thank you. For being you.', 'assets/badges/special_thanks.png', Color(0xFFFF4FA3)),
];

BadgeDef? badgeByKey(String? k) {
  for (final b in kBadges) {
    if (b.key == k) return b;
  }
  return null;
}

/// Greyscale filter used for badges that are not earned yet.
const kGreyFilter = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);
