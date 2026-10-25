INSERT INTO badge_catalog (badge_key,badge_name,description) VALUES
('life_saver','Life Saver','Thank you for being there when it mattered most.'),
('accident_angel','Accident Angel','You turned a stressful moment into a safer one.'),
('medical_hero','Medical Hero','Your quick response brought hope and healing.'),
('fire_fighter','Fire Fighter','Courage, quick action and a big heart!'),
('flood_warrior','Flood Warrior','You stood strong when waters rose.'),
('rescue_champ','Rescue Champ','You go beyond limits to save lives.'),
('womens_safety_guardian','Women''s Safety Guardian','You made a difference when it mattered most.'),
('child_care_hero','Child Care Hero','You keep our little ones safe and sound.'),
('location_legend','Location Legend','You were right there when we needed you.'),
('team_player','Team Player','Your support means the world.'),
('reliable_responder','Reliable Responder','Always ready, always dependable.'),
('community_supporter','Community Supporter','You care, you help, you make a difference.'),
('brave_soul','Brave Soul','Not all heroes wear capes, some wear your badge.'),
('hope_giver','Hope Giver','You bring hope in difficult times.'),
('special_thanks','Special Thanks','Just thank you. For being you.')
ON CONFLICT (badge_key) DO UPDATE SET badge_name=EXCLUDED.badge_name, description=EXCLUDED.description;
