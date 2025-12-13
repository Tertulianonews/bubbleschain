-- File: supabase_schema.sql
-- Schema updates for Bubble Coin and Exchange system

-- Add bubble_coin_balance column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS bubble_coin_balance DOUBLE PRECISION DEFAULT 0.0;

-- Create exchange_transactions table for tracking conversions between currencies
CREATE TABLE IF NOT EXISTS exchange_transactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  from_coin TEXT,
  to_coin TEXT,
  amount DOUBLE PRECISION,
  converted_amount DOUBLE PRECISION,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create wallets table for exchange balances (if it doesn't exist)
CREATE TABLE IF NOT EXISTS wallets (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  coin TEXT NOT NULL,
  balance DOUBLE PRECISION DEFAULT 0.0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, coin)
);

-- Create index for faster queries on user_id
CREATE INDEX IF NOT EXISTS idx_exchange_transactions_user_id ON exchange_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_wallets_user_coin ON wallets(user_id, coin);

-- Add comments for documentation
COMMENT ON TABLE exchange_transactions IS 'Tracks all currency conversions between Bubble Coins and cryptocurrencies';
COMMENT ON TABLE wallets IS 'Stores user balances for each cryptocurrency on the exchange';
COMMENT ON COLUMN users.bubble_coin_balance IS 'User balance in Bubble Coins earned from games';

-- Enable Row Level Security (RLS)
ALTER TABLE exchange_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for exchange_transactions
CREATE POLICY "Users can view their own exchange transactions"
  ON exchange_transactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own exchange transactions"
  ON exchange_transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Create RLS policies for wallets
CREATE POLICY "Users can view their own wallets"
  ON wallets FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own wallets"
  ON wallets FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own wallets"
  ON wallets FOR UPDATE
  USING (auth.uid() = user_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_exchange_transactions_updated_at BEFORE UPDATE ON exchange_transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wallets_updated_at BEFORE UPDATE ON wallets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
