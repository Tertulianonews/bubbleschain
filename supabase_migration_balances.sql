-- Migration Script: ALREADY DONE! 
-- The userBalances table already exists with user data!
-- This file is kept for reference only.

-- : Your current setup:
-- Table: userBalances
-- Columns:
--   - user_id (uuid)
--   - bubblecoin_balance (numeric)
--   - updated_at (timestamp)

-- The app has been updated to read from the 'userBalances' table correctly.
-- No migration needed! Your data is already in the right place.

-- ====================================================================
-- OPTIONAL: If you want to verify your data, run these queries:
-- ====================================================================

-- 1. Check total users and balances
SELECT 
  COUNT(*) as total_users,
  SUM(CASE WHEN bubblecoin_balance > 0 THEN 1 ELSE 0 END) as users_with_balance,
  SUM(bubblecoin_balance) as total_bubble_coins,
  AVG(bubblecoin_balance) as average_balance,
  MAX(bubblecoin_balance) as highest_balance
FROM userBalances;

-- 2. Check individual user balances (top 10)
SELECT 
  user_id,
  bubblecoin_balance,
  updated_at
FROM userBalances
ORDER BY bubblecoin_balance DESC
LIMIT 10;

-- 3. Check if wallets table exists and initialize if needed
INSERT INTO wallets (user_id, coin, balance, created_at)
SELECT user_id, 'USDT', 0.0, NOW() FROM userBalances
ON CONFLICT (user_id, coin) DO NOTHING;

INSERT INTO wallets (user_id, coin, balance, created_at)
SELECT user_id, 'BTC', 0.0, NOW() FROM userBalances
ON CONFLICT (user_id, coin) DO NOTHING;

INSERT INTO wallets (user_id, coin, balance, created_at)
SELECT user_id, 'ETH', 0.0, NOW() FROM userBalances
ON CONFLICT (user_id, coin) DO NOTHING;

INSERT INTO wallets (user_id, coin, balance, created_at)
SELECT user_id, 'TON', 0.0, NOW() FROM userBalances
ON CONFLICT (user_id, coin) DO NOTHING;

-- 4. Verify wallets initialization
SELECT 
  coin, 
  COUNT(*) as users_count, 
  SUM(balance) as total_balance 
FROM wallets 
GROUP BY coin;

-- ====================================================================
-- NOTES:
-- ====================================================================
-- - Your users already have balances in the userBalances table
-- - The app now reads from userBalances.bubblecoin_balance
-- - The app will update userBalances.bubblecoin_balance when users play games
-- - Welcome bonus only applies to NEW users with 0 balance
-- - Existing users keep their current balances!