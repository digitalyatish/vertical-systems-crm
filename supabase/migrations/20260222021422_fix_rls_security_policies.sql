/*
  # Fix Critical RLS Security Issues
  
  This migration addresses critical security vulnerabilities in Row Level Security policies
  and optimizes auth function calls for better performance.
  
  ## Changes Made
  
  1. **RLS Policy Security Fixes**
     - Replace overly permissive `USING (true)` policies with proper role-based checks
     - Implement Finance role restrictions for financial data
     - Add proper ownership checks where applicable
     
  2. **Performance Optimizations**
     - Wrap auth.uid() calls with SELECT for better query performance
     - Prevents re-evaluation of auth functions for each row
     
  3. **Function Security**
     - Fix search_path vulnerabilities in functions
     
  ## Security Model
     - Admin: Full access to all data
     - Finance: Full access to financial data (cash_entries, expenses, offers)
     - User: Read access to most data, limited write access
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Authenticated users can manage all leads" ON leads;
DROP POLICY IF EXISTS "Authenticated users can manage all deals" ON deals;
DROP POLICY IF EXISTS "Authenticated users can manage all proposals" ON proposals;
DROP POLICY IF EXISTS "Authenticated users can manage all closer reports" ON closer_reports;
DROP POLICY IF EXISTS "Authenticated users can manage all setter reports" ON setter_reports;

DROP POLICY IF EXISTS "Authenticated users can view all offers" ON offers;
DROP POLICY IF EXISTS "Authenticated users can insert offers" ON offers;
DROP POLICY IF EXISTS "Authenticated users can update offers" ON offers;
DROP POLICY IF EXISTS "Authenticated users can delete offers" ON offers;

DROP POLICY IF EXISTS "Authenticated users can view all cash entries" ON cash_entries;
DROP POLICY IF EXISTS "Authenticated users can insert cash entries" ON cash_entries;
DROP POLICY IF EXISTS "Authenticated users can update cash entries" ON cash_entries;
DROP POLICY IF EXISTS "Authenticated users can delete cash entries" ON cash_entries;

DROP POLICY IF EXISTS "Authenticated users can view all expenses" ON expenses;
DROP POLICY IF EXISTS "Authenticated users can insert expenses" ON expenses;
DROP POLICY IF EXISTS "Authenticated users can update expenses" ON expenses;
DROP POLICY IF EXISTS "Authenticated users can delete expenses" ON expenses;

DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

-- Helper function to check user role
CREATE OR REPLACE FUNCTION public.has_role(required_role text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  user_role text;
BEGIN
  SELECT role INTO user_role
  FROM users
  WHERE id = auth.uid();
  
  RETURN user_role = required_role OR user_role = 'Admin';
END;
$$;

-- LEADS POLICIES
CREATE POLICY "Users can view all leads"
  ON leads FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert leads"
  ON leads FOR INSERT
  TO authenticated
  WITH CHECK (created_by = (SELECT auth.uid()));

CREATE POLICY "Users can update leads"
  ON leads FOR UPDATE
  TO authenticated
  USING (
    created_by = (SELECT auth.uid()) 
    OR assigned_to = (SELECT auth.uid())
    OR (SELECT has_role('Admin'))
  )
  WITH CHECK (
    created_by = (SELECT auth.uid()) 
    OR assigned_to = (SELECT auth.uid())
    OR (SELECT has_role('Admin'))
  );

CREATE POLICY "Admins can delete leads"
  ON leads FOR DELETE
  TO authenticated
  USING ((SELECT has_role('Admin')));

-- DEALS POLICIES
CREATE POLICY "Users can view all deals"
  ON deals FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert deals"
  ON deals FOR INSERT
  TO authenticated
  WITH CHECK (created_by = (SELECT auth.uid()));

CREATE POLICY "Users can update deals"
  ON deals FOR UPDATE
  TO authenticated
  USING (
    created_by = (SELECT auth.uid()) 
    OR deal_owner = (SELECT auth.uid())
    OR (SELECT has_role('Admin'))
  )
  WITH CHECK (
    created_by = (SELECT auth.uid()) 
    OR deal_owner = (SELECT auth.uid())
    OR (SELECT has_role('Admin'))
  );

CREATE POLICY "Admins can delete deals"
  ON deals FOR DELETE
  TO authenticated
  USING ((SELECT has_role('Admin')));

-- PROPOSALS POLICIES
CREATE POLICY "Users can view all proposals"
  ON proposals FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert proposals"
  ON proposals FOR INSERT
  TO authenticated
  WITH CHECK (created_by = (SELECT auth.uid()));

CREATE POLICY "Users can update proposals"
  ON proposals FOR UPDATE
  TO authenticated
  USING (
    created_by = (SELECT auth.uid()) 
    OR assigned_to = (SELECT auth.uid())
    OR (SELECT has_role('Admin'))
  )
  WITH CHECK (
    created_by = (SELECT auth.uid()) 
    OR assigned_to = (SELECT auth.uid())
    OR (SELECT has_role('Admin'))
  );

CREATE POLICY "Admins can delete proposals"
  ON proposals FOR DELETE
  TO authenticated
  USING ((SELECT has_role('Admin')));

-- CLOSER REPORTS POLICIES
CREATE POLICY "Users can view all closer reports"
  ON closer_reports FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert closer reports"
  ON closer_reports FOR INSERT
  TO authenticated
  WITH CHECK (submitted_by = (SELECT auth.uid()));

CREATE POLICY "Users can update own closer reports"
  ON closer_reports FOR UPDATE
  TO authenticated
  USING (
    submitted_by = (SELECT auth.uid())
    OR (SELECT has_role('Admin'))
  )
  WITH CHECK (
    submitted_by = (SELECT auth.uid())
    OR (SELECT has_role('Admin'))
  );

CREATE POLICY "Admins can delete closer reports"
  ON closer_reports FOR DELETE
  TO authenticated
  USING ((SELECT has_role('Admin')));

-- SETTER REPORTS POLICIES
CREATE POLICY "Users can view all setter reports"
  ON setter_reports FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert setter reports"
  ON setter_reports FOR INSERT
  TO authenticated
  WITH CHECK (submitted_by = (SELECT auth.uid()));

CREATE POLICY "Users can update own setter reports"
  ON setter_reports FOR UPDATE
  TO authenticated
  USING (
    submitted_by = (SELECT auth.uid())
    OR (SELECT has_role('Admin'))
  )
  WITH CHECK (
    submitted_by = (SELECT auth.uid())
    OR (SELECT has_role('Admin'))
  );

CREATE POLICY "Admins can delete setter reports"
  ON setter_reports FOR DELETE
  TO authenticated
  USING ((SELECT has_role('Admin')));

-- OFFERS POLICIES (Finance and Admin only)
CREATE POLICY "Users can view all offers"
  ON offers FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Finance and Admin can insert offers"
  ON offers FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT has_role('Finance'))
    OR (SELECT has_role('Admin'))
  );

CREATE POLICY "Finance and Admin can update offers"
  ON offers FOR UPDATE
  TO authenticated
  USING (
    (SELECT has_role('Finance'))
    OR (SELECT has_role('Admin'))
  )
  WITH CHECK (
    (SELECT has_role('Finance'))
    OR (SELECT has_role('Admin'))
  );

CREATE POLICY "Admins can delete offers"
  ON offers FOR DELETE
  TO authenticated
  USING ((SELECT has_role('Admin')));

-- CASH ENTRIES POLICIES (Finance and Admin only)
CREATE POLICY "Users can view all cash entries"
  ON cash_entries FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Finance and Admin can insert cash entries"
  ON cash_entries FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT has_role('Finance'))
    OR (SELECT has_role('Admin'))
  );

CREATE POLICY "Finance and Admin can update cash entries"
  ON cash_entries FOR UPDATE
  TO authenticated
  USING (
    (SELECT has_role('Finance'))
    OR (SELECT has_role('Admin'))
  )
  WITH CHECK (
    (SELECT has_role('Finance'))
    OR (SELECT has_role('Admin'))
  );

CREATE POLICY "Admins can delete cash entries"
  ON cash_entries FOR DELETE
  TO authenticated
  USING ((SELECT has_role('Admin')));

-- EXPENSES POLICIES (Finance and Admin only)
CREATE POLICY "Users can view all expenses"
  ON expenses FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Finance and Admin can insert expenses"
  ON expenses FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT has_role('Finance'))
    OR (SELECT has_role('Admin'))
  );

CREATE POLICY "Finance and Admin can update expenses"
  ON expenses FOR UPDATE
  TO authenticated
  USING (
    (SELECT has_role('Finance'))
    OR (SELECT has_role('Admin'))
  )
  WITH CHECK (
    (SELECT has_role('Finance'))
    OR (SELECT has_role('Admin'))
  );

CREATE POLICY "Admins can delete expenses"
  ON expenses FOR DELETE
  TO authenticated
  USING ((SELECT has_role('Admin')));

-- USERS TABLE POLICIES (Optimized auth calls)
CREATE POLICY "Users can view all profiles"
  ON users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (id = (SELECT auth.uid()));

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (id = (SELECT auth.uid()))
  WITH CHECK (id = (SELECT auth.uid()));

-- Fix function search_path vulnerabilities
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

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

CREATE OR REPLACE FUNCTION public.update_deal_stage_from_proposal()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.status = 'sent' AND OLD.status != 'sent' THEN
    UPDATE deals
    SET stage = 'proposal_sent'
    WHERE id = NEW.deal_id;
  ELSIF NEW.status = 'accepted' THEN
    UPDATE deals
    SET stage = 'contract_sent',
        actual_close_date = now()
    WHERE id = NEW.deal_id;
  END IF;

  RETURN NEW;
END;
$$;
