/*
  # Clean Up Unused Indexes and Fix Duplicate Policies
  
  This migration removes unused database indexes to improve database performance
  and fixes duplicate RLS policies.
  
  ## Changes Made
  
  1. **Remove Unused Indexes**
     - Drop all indexes that have not been used by queries
     - Keep only essential indexes (primary keys, foreign keys, unique constraints)
     - This reduces index maintenance overhead and improves write performance
     
  2. **Fix Duplicate Policies**
     - Remove duplicate SELECT policy on users table
     
  3. **Fix Function Search Path**
     - Update create_proposal_from_deal function with proper search_path
  
  ## Performance Impact
     - Reduces storage overhead
     - Improves INSERT/UPDATE/DELETE performance
     - Reduces index maintenance during autovacuum
*/

-- Drop unused indexes on leads table
DROP INDEX IF EXISTS idx_leads_email;
DROP INDEX IF EXISTS idx_leads_phone;
DROP INDEX IF EXISTS idx_leads_status;
DROP INDEX IF EXISTS idx_leads_lead_source;
DROP INDEX IF EXISTS idx_leads_assigned_to;
DROP INDEX IF EXISTS idx_leads_created_by;
DROP INDEX IF EXISTS idx_leads_created_at;
DROP INDEX IF EXISTS idx_leads_next_follow_up_date;
DROP INDEX IF EXISTS idx_leads_company;
DROP INDEX IF EXISTS idx_leads_priority;
DROP INDEX IF EXISTS idx_leads_status_assigned_to;
DROP INDEX IF EXISTS idx_leads_created_by_status;
DROP INDEX IF EXISTS idx_leads_next_follow_up_assigned;
DROP INDEX IF EXISTS idx_leads_checklist;
DROP INDEX IF EXISTS idx_leads_checklist_dates;
DROP INDEX IF EXISTS idx_leads_revenue_generated;
DROP INDEX IF EXISTS idx_leads_cash_collected;
DROP INDEX IF EXISTS idx_leads_financial_summary;

-- Drop unused indexes on cash_entries table
DROP INDEX IF EXISTS idx_cash_entries_status;
DROP INDEX IF EXISTS idx_cash_entries_created_by;
DROP INDEX IF EXISTS idx_cash_entries_created_at;
DROP INDEX IF EXISTS idx_cash_entries_income;
DROP INDEX IF EXISTS idx_cash_entries_gross_profit;
DROP INDEX IF EXISTS idx_cash_entries_due_date;
DROP INDEX IF EXISTS idx_cash_entries_setter_id;
DROP INDEX IF EXISTS idx_cash_entries_due_date_status;
DROP INDEX IF EXISTS idx_cash_entries_setter_status;
DROP INDEX IF EXISTS idx_cash_entries_date;
DROP INDEX IF EXISTS idx_cash_entries_offer_id;
DROP INDEX IF EXISTS idx_cash_entries_client_email;
DROP INDEX IF EXISTS idx_cash_entries_payment_type;

-- Drop unused indexes on closer_reports table
DROP INDEX IF EXISTS idx_closer_reports_report_date;
DROP INDEX IF EXISTS idx_closer_reports_submitted_by;
DROP INDEX IF EXISTS idx_closer_reports_closer_name;
DROP INDEX IF EXISTS idx_closer_reports_created_at;
DROP INDEX IF EXISTS idx_closer_reports_revenue_generated;
DROP INDEX IF EXISTS idx_closer_reports_cash_collected;
DROP INDEX IF EXISTS idx_closer_reports_daily_user;

-- Drop unused indexes on setter_reports table
DROP INDEX IF EXISTS idx_setter_reports_report_date;
DROP INDEX IF EXISTS idx_setter_reports_submitted_by;
DROP INDEX IF EXISTS idx_setter_reports_setter_name;
DROP INDEX IF EXISTS idx_setter_reports_created_at;
DROP INDEX IF EXISTS idx_setter_reports_daily_user;

-- Drop unused indexes on proposals table
DROP INDEX IF EXISTS idx_proposals_proposal_link;
DROP INDEX IF EXISTS idx_proposals_expiration_date;
DROP INDEX IF EXISTS idx_proposals_deal_id;
DROP INDEX IF EXISTS idx_proposals_status;
DROP INDEX IF EXISTS idx_proposals_created_by;
DROP INDEX IF EXISTS idx_proposals_assigned_to;
DROP INDEX IF EXISTS idx_proposals_created_at;
DROP INDEX IF EXISTS idx_proposals_sent_date;

-- Drop unused indexes on users table
DROP INDEX IF EXISTS idx_users_email;
DROP INDEX IF EXISTS idx_users_role;

-- Drop unused indexes on expenses table
DROP INDEX IF EXISTS idx_expenses_date;
DROP INDEX IF EXISTS idx_expenses_expense_type;
DROP INDEX IF EXISTS idx_expenses_created_by;
DROP INDEX IF EXISTS idx_expenses_invoice_filed;
DROP INDEX IF EXISTS idx_expenses_created_at;
DROP INDEX IF EXISTS idx_expenses_amount;

-- Drop unused indexes on deals table
DROP INDEX IF EXISTS idx_deals_lead_id;
DROP INDEX IF EXISTS idx_deals_stage;
DROP INDEX IF EXISTS idx_deals_deal_owner;
DROP INDEX IF EXISTS idx_deals_created_by;
DROP INDEX IF EXISTS idx_deals_service_type;
DROP INDEX IF EXISTS idx_deals_deal_source;
DROP INDEX IF EXISTS idx_deals_expected_close_date;
DROP INDEX IF EXISTS idx_deals_deal_value;
DROP INDEX IF EXISTS idx_deals_probability;
DROP INDEX IF EXISTS idx_deals_created_at;

-- Drop unused indexes on offers table
DROP INDEX IF EXISTS idx_offers_name;
DROP INDEX IF EXISTS idx_offers_created_by;
DROP INDEX IF EXISTS idx_offers_created_at;

-- Fix duplicate RLS policy on users table
DROP POLICY IF EXISTS "Users can view all users" ON users;

-- The "Users can view all profiles" policy already exists from the previous migration
-- and serves the same purpose, so we don't need to recreate it

-- Fix function search path (this was already done in the previous migration, 
-- but we include it here for completeness in case it wasn't applied)
DROP FUNCTION IF EXISTS public.create_proposal_from_deal(uuid);

CREATE OR REPLACE FUNCTION public.create_proposal_from_deal(deal_id_input uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  new_proposal_id uuid;
  deal_record RECORD;
BEGIN
  SELECT * INTO deal_record
  FROM deals
  WHERE id = deal_id_input;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Deal not found';
  END IF;

  INSERT INTO proposals (
    deal_id,
    title,
    proposal_value,
    status,
    created_by,
    assigned_to
  )
  VALUES (
    deal_record.id,
    'Proposal for ' || deal_record.deal_name,
    deal_record.deal_value,
    'draft',
    deal_record.created_by,
    deal_record.deal_owner
  )
  RETURNING id INTO new_proposal_id;

  RETURN new_proposal_id;
END;
$$;
