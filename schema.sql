-- ═══════════════════════════════════════════
-- MyEcho v3 — Script SQL Supabase
-- Copiez et collez dans : SQL Editor → New Query
-- ═══════════════════════════════════════════

-- 1. TABLE TRACKS (pistes audio)
CREATE TABLE IF NOT EXISTS tracks (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  username    TEXT,
  name        TEXT NOT NULL,
  category    TEXT DEFAULT 'music' CHECK (category IN ('music','voice','creation','other','ambient_mix')),
  audio_url   TEXT NOT NULL,
  cover_url   TEXT,
  is_public   BOOLEAN DEFAULT false,
  play_count  INT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- 2. INDEX pour les performances
CREATE INDEX IF NOT EXISTS idx_tracks_user ON tracks(user_id);
CREATE INDEX IF NOT EXISTS idx_tracks_public ON tracks(is_public);
CREATE INDEX IF NOT EXISTS idx_tracks_category ON tracks(category);
CREATE INDEX IF NOT EXISTS idx_tracks_created ON tracks(created_at DESC);

-- 3. ROW LEVEL SECURITY (RLS)
ALTER TABLE tracks ENABLE ROW LEVEL SECURITY;

-- Politique : lecture publique des pistes publiques
CREATE POLICY "Lecture pistes publiques"
  ON tracks FOR SELECT
  USING (is_public = true OR auth.uid() = user_id);

-- Politique : insertion par utilisateur connecté
CREATE POLICY "Insertion par propriétaire"
  ON tracks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Politique : modification par propriétaire
CREATE POLICY "Modification par propriétaire"
  ON tracks FOR UPDATE
  USING (auth.uid() = user_id);

-- Politique : suppression par propriétaire
CREATE POLICY "Suppression par propriétaire"
  ON tracks FOR DELETE
  USING (auth.uid() = user_id);

-- 4. STORAGE BUCKET (si pas encore créé via l'interface)
-- Allez dans Storage → New Bucket → "myecho-audio" → cochez Public

-- Politique storage : lecture publique
INSERT INTO storage.buckets (id, name, public) VALUES ('myecho-audio', 'myecho-audio', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Lecture publique storage"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'myecho-audio');

CREATE POLICY "Upload par utilisateur connecté"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'myecho-audio' AND auth.uid() IS NOT NULL);

CREATE POLICY "Suppression par propriétaire storage"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'myecho-audio' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ═══════════════════════════════════════════
-- TERMINÉ ! Votre base de données est prête.
-- ═══════════════════════════════════════════
