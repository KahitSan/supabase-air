-- Add foreign key constraint between transactions.client_id and members.id
-- This enables PostgREST relationship queries like:
-- transactions.select('*, members!transactions_client_id_fkey(*)')

ALTER TABLE public.transactions
ADD CONSTRAINT transactions_client_id_fkey
FOREIGN KEY (client_id)
REFERENCES public.members(id)
ON DELETE SET NULL
ON UPDATE CASCADE;

-- Create index on client_id for better join performance
CREATE INDEX IF NOT EXISTS idx_transactions_client_id ON public.transactions(client_id);
