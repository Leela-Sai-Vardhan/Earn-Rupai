-- Add game token columns to user_profiles
ALTER TABLE user_profiles 
ADD COLUMN game_token_balance NUMERIC DEFAULT 0,
ADD COLUMN total_game_tokens_earned NUMERIC DEFAULT 0;

-- Sync existing data from game_tokens into user_profiles
UPDATE user_profiles up
SET 
  game_token_balance = gt.tokens_balance,
  total_game_tokens_earned = gt.total_tokens_earned
FROM game_tokens gt
WHERE up.user_id = gt.user_id;

-- Create a sync function
CREATE OR REPLACE FUNCTION sync_game_tokens_to_user_profiles()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE user_profiles
  SET 
    game_token_balance = NEW.tokens_balance,
    total_game_tokens_earned = NEW.total_tokens_earned,
    updated_at = NOW()
  WHERE user_id = NEW.user_id;
  RETURN NEW;
END;
$$;

-- Create a trigger so that any update/insert on game_tokens mirrors to user_profiles
DROP TRIGGER IF EXISTS trigger_sync_game_tokens ON game_tokens;
CREATE TRIGGER trigger_sync_game_tokens
AFTER INSERT OR UPDATE ON game_tokens
FOR EACH ROW
EXECUTE FUNCTION sync_game_tokens_to_user_profiles();
