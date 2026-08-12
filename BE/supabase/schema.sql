-- ============================================================================
-- MASTER DATABASE SCHEMA FOR AI STUDY-HUB (POSTGRESQL / SUPABASE)
-- Run this script ONCE in a clean Supabase SQL Editor to initialize the entire DB.
-- ============================================================================

-- 1. Enable Required PostgreSQL Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Create Core Domain Tables

-- Profiles / Users
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  email CHARACTER VARYING NOT NULL UNIQUE,
  username CHARACTER VARYING NOT NULL UNIQUE,
  password_hash CHARACTER VARYING NOT NULL,
  full_name CHARACTER VARYING,
  avatar_url TEXT,
  bio TEXT DEFAULT '',
  date_of_birth DATE,
  is_dob_public BOOLEAN DEFAULT FALSE,
  role CHARACTER VARYING NOT NULL DEFAULT 'USER',
  status CHARACTER VARYING NOT NULL DEFAULT 'ACTIVE',
  session_id UUID,
  notifications_read_at TIMESTAMPTZ,
  last_login_at TIMESTAMPTZ,
  last_name_change TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- OTP Tokens
CREATE TABLE IF NOT EXISTS public.otp_tokens (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  email CHARACTER VARYING NOT NULL,
  otp_code CHARACTER VARYING NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Libraries
CREATE TABLE IF NOT EXISTS public.libraries (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name CHARACTER VARYING NOT NULL,
  description TEXT,
  is_public BOOLEAN DEFAULT FALSE,
  share_on_profile BOOLEAN DEFAULT FALSE,
  views_count INTEGER NOT NULL DEFAULT 0,
  stars_count INTEGER NOT NULL DEFAULT 0,
  downloads_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Workspaces
CREATE TABLE IF NOT EXISTS public.workspaces (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name CHARACTER VARYING NOT NULL,
  description TEXT,
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workspace Members
CREATE TABLE IF NOT EXISTS public.workspace_members (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role CHARACTER VARYING NOT NULL DEFAULT 'member',
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT workspace_members_pkey PRIMARY KEY (workspace_id, user_id)
);

-- Documents
CREATE TABLE IF NOT EXISTS public.documents (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  uploader_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  library_id UUID REFERENCES public.libraries(id) ON DELETE SET NULL,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE SET NULL,
  title CHARACTER VARYING NOT NULL,
  file_url TEXT NOT NULL,
  file_size_bytes BIGINT DEFAULT 0,
  mime_type TEXT,
  is_public BOOLEAN DEFAULT FALSE,
  status CHARACTER VARYING DEFAULT 'APPROVED',
  ai_reject_reason JSONB,
  deleted_at TIMESTAMPTZ,
  reviewed_at TIMESTAMPTZ,
  reviewed_by_admin_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  admin_review_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  tagging_error TEXT,
  tagging_status TEXT NOT NULL DEFAULT 'COMPLETED',
  tagging_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  replacement_document_ids JSONB NOT NULL DEFAULT '[]'::jsonb
);

-- Document Chunks with Vector Embeddings (768 dimensions for Gemini text-embedding-004)
CREATE TABLE IF NOT EXISTS public.document_chunks (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  document_id UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
  chunk_index INTEGER NOT NULL,
  content TEXT NOT NULL,
  embedding vector(768),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS document_chunks_document_id_idx ON public.document_chunks(document_id);

-- AI Summaries
CREATE TABLE IF NOT EXISTS public.ai_summaries (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  document_id UUID REFERENCES public.documents(id) ON DELETE CASCADE,
  summary_text TEXT NOT NULL,
  keywords TEXT[],
  generated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chat Conversations & History
CREATE TABLE IF NOT EXISTS public.chat_conversations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  document_id UUID REFERENCES public.documents(id) ON DELETE SET NULL,
  primary_document_id UUID REFERENCES public.documents(id) ON DELETE SET NULL,
  title TEXT NOT NULL DEFAULT 'New Conversation',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.chat_messages (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  conversation_id UUID NOT NULL REFERENCES public.chat_conversations(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'user',
  sender_type TEXT NOT NULL DEFAULT 'user',
  content TEXT NOT NULL,
  sources JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Workspace Messages
CREATE TABLE IF NOT EXISTS public.workspace_messages (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  is_edited BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Flashcard Sets & Flashcards
CREATE TABLE IF NOT EXISTS public.flashcard_sets (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  document_id UUID REFERENCES public.documents(id) ON DELETE SET NULL,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE SET NULL,
  creator_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.flashcards (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  set_id UUID NOT NULL REFERENCES public.flashcard_sets(id) ON DELETE CASCADE,
  document_id UUID REFERENCES public.documents(id) ON DELETE SET NULL,
  workspace_id UUID REFERENCES public.workspaces(id) ON DELETE SET NULL,
  creator_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tags & Hierarchical Document Tagging
CREATE TABLE IF NOT EXISTS public.tags (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  level INTEGER NOT NULL DEFAULT 1,
  parent_id UUID REFERENCES public.tags(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT tags_name_level_unique UNIQUE (name, level)
);

CREATE TABLE IF NOT EXISTS public.document_tags (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  document_id UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
  level_1_tag_id UUID REFERENCES public.tags(id) ON DELETE SET NULL,
  level_2_tag_id UUID REFERENCES public.tags(id) ON DELETE SET NULL,
  level_3_tag_id UUID REFERENCES public.tags(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT document_tags_document_id_key UNIQUE (document_id)
);

-- Admin Telemetry & Activity Logs
CREATE TABLE IF NOT EXISTS public.activity_logs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  actor_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  admin_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action_type CHARACTER VARYING NOT NULL,
  entity_type CHARACTER VARYING,
  entity_id UUID,
  old_data JSONB,
  new_data JSONB,
  details TEXT,
  risk_level TEXT NOT NULL DEFAULT 'INFO',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ai_usage_logs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
  tokens_consumed INTEGER DEFAULT 0,
  chat_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT ai_usage_logs_user_date_key UNIQUE (user_id, usage_date)
);

CREATE TABLE IF NOT EXISTS public.daily_quota_usage (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
  tokens_consumed INTEGER DEFAULT 0,
  chat_count INTEGER DEFAULT 0,
  bytes_uploaded BIGINT NOT NULL DEFAULT 0,
  bytes_downloaded BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT daily_quota_usage_user_date_key UNIQUE (user_id, usage_date)
);

CREATE TABLE IF NOT EXISTS public.system_issue_reports (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  reporter_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title CHARACTER VARYING NOT NULL,
  description TEXT NOT NULL,
  screenshot_url TEXT,
  category TEXT NOT NULL DEFAULT 'OTHER',
  priority TEXT NOT NULL DEFAULT 'MEDIUM',
  status CHARACTER VARYING NOT NULL DEFAULT 'OPEN',
  attachments JSONB NOT NULL DEFAULT '[]'::jsonb,
  page_path TEXT,
  admin_note TEXT,
  admin_notes TEXT,
  handled_by_admin_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  handled_by_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  handled_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Library Stars & Downloads
CREATE TABLE IF NOT EXISTS public.library_stars (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  library_id UUID NOT NULL REFERENCES public.libraries(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT library_stars_library_user_key UNIQUE (library_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.library_downloads (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  library_id UUID NOT NULL REFERENCES public.libraries(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Disable Row Level Security (RLS) & Grant All Permissions
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.otp_tokens DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.libraries DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_chunks DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_summaries DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_conversations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspaces DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspace_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspace_messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_usage_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_quota_usage DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_issue_reports DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.flashcards DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.flashcard_sets DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.tags DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_tags DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.library_stars DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.library_downloads DISABLE ROW LEVEL SECURITY;

GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO postgres, anon, authenticated, service_role;

-- 4. Stored RPC Functions

-- Vector Cosine Similarity Search Procedure
CREATE OR REPLACE FUNCTION public.match_document_chunks(
  match_document_id UUID,
  query_embedding vector(768),
  match_count INT DEFAULT 15
)
RETURNS TABLE (
  id UUID,
  document_id UUID,
  chunk_index INT,
  content TEXT,
  similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    dc.id,
    dc.document_id,
    dc.chunk_index,
    dc.content,
    1 - (dc.embedding <=> query_embedding) AS similarity
  FROM public.document_chunks dc
  WHERE dc.document_id = match_document_id
  ORDER BY dc.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

-- Library Deletion Procedure
CREATE OR REPLACE FUNCTION public.delete_owned_library(
  p_library_id UUID,
  p_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_owner_id UUID;
BEGIN
  SELECT user_id INTO v_owner_id
  FROM public.libraries
  WHERE id = p_library_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'LIBRARY_NOT_FOUND';
  END IF;
  IF v_owner_id <> p_user_id THEN
    RAISE EXCEPTION 'LIBRARY_OWNER_REQUIRED';
  END IF;

  DELETE FROM public.library_stars WHERE library_id = p_library_id;
  DELETE FROM public.library_downloads WHERE library_id = p_library_id;
  UPDATE public.documents
  SET library_id = NULL, is_public = FALSE
  WHERE library_id = p_library_id;
  DELETE FROM public.libraries WHERE id = p_library_id;
END;
$$;

-- Admin Hard Delete Workspace Procedure
CREATE OR REPLACE FUNCTION public.admin_hard_delete_workspace(p_workspace_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_workspace_name TEXT;
  v_deleted_at TIMESTAMPTZ;
  v_deleted_document_count INTEGER := 0;
  v_preserved_document_count INTEGER := 0;
BEGIN
  SELECT name, deleted_at INTO v_workspace_name, v_deleted_at
  FROM public.workspaces WHERE id = p_workspace_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'WORKSPACE_NOT_FOUND'; END IF;
  IF v_deleted_at IS NULL THEN RAISE EXCEPTION 'WORKSPACE_NOT_SOFT_DELETED'; END IF;

  SELECT count(*) INTO v_deleted_document_count FROM public.documents
  WHERE workspace_id = p_workspace_id AND library_id IS NULL;
  SELECT count(*) INTO v_preserved_document_count FROM public.documents
  WHERE workspace_id = p_workspace_id AND library_id IS NOT NULL;

  UPDATE public.documents SET workspace_id = NULL
  WHERE workspace_id = p_workspace_id AND library_id IS NOT NULL;
  DELETE FROM public.workspaces WHERE id = p_workspace_id;

  RETURN jsonb_build_object('workspaceId', p_workspace_id, 'workspaceName', v_workspace_name,
    'documentsDeleted', v_deleted_document_count, 'documentsPreserved', v_preserved_document_count);
END;
$$;

-- Grant EXECUTE Permissions on Functions
GRANT EXECUTE ON FUNCTION public.match_document_chunks TO service_role, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.delete_owned_library TO service_role, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_hard_delete_workspace TO service_role, anon, authenticated;

-- 5. Seed Comprehensive Level 1 Subject Tags
INSERT INTO public.tags (name, level) VALUES
  ('Physics', 1),
  ('Chemistry', 1),
  ('Biology', 1),
  ('Mathematics', 1),
  ('Computer Science', 1),
  ('Literature', 1),
  ('History', 1),
  ('Economics', 1),
  ('Foreign Languages', 1),
  ('Geography', 1),
  ('Philosophy', 1),
  ('Medicine & Health', 1),
  ('Law & Legal Studies', 1),
  ('Psychology', 1),
  ('Marketing & Communications', 1),
  ('Architecture & Construction', 1),
  ('Mechanical Engineering', 1),
  ('Electrical Engineering', 1),
  ('Environmental Science', 1),
  ('Art & Design', 1)
ON CONFLICT (name, level) DO NOTHING;

-- 6. Force PostgREST Cache Reload
NOTIFY pgrst, 'reload schema';
