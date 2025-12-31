-- Migration: Add scoring_config column to tournaments table
-- Run this in your Supabase SQL Editor

-- Add scoring_config column for phase-based scoring configuration
-- Stores JSON with scoring rules for pool_play, quarter_finals, semi_finals, finals
ALTER TABLE tournaments
ADD COLUMN IF NOT EXISTS scoring_config JSONB;

-- Add comment for documentation
COMMENT ON COLUMN tournaments.scoring_config IS 'JSON configuration for phase-based scoring. Structure: {sport_type, pool_play, quarter_finals, semi_finals, finals} where each phase has {number_of_sets, points_per_set, tiebreak_points}';

-- Example of what the scoring_config JSON looks like:
-- Volleyball default:
-- {
--   "sport_type": "volleyball",
--   "pool_play": {"number_of_sets": 1, "points_per_set": 25, "tiebreak_points": null},
--   "quarter_finals": {"number_of_sets": 1, "points_per_set": 25, "tiebreak_points": null},
--   "semi_finals": {"number_of_sets": 3, "points_per_set": 21, "tiebreak_points": 15},
--   "finals": {"number_of_sets": 3, "points_per_set": 21, "tiebreak_points": 15}
-- }
--
-- Pickleball default:
-- {
--   "sport_type": "pickleball",
--   "pool_play": {"number_of_sets": 1, "points_per_set": 11, "tiebreak_points": null},
--   "quarter_finals": {"number_of_sets": 1, "points_per_set": 11, "tiebreak_points": null},
--   "semi_finals": {"number_of_sets": 3, "points_per_set": 11, "tiebreak_points": null},
--   "finals": {"number_of_sets": 3, "points_per_set": 11, "tiebreak_points": null}
-- }

-- Verify the column was added
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'tournaments'
AND column_name = 'scoring_config';
