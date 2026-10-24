-- ============================================================================
-- Fiches : PDF importés et annotés
-- ============================================================================
-- Un bloc `pdf` garde en JSON la référence du fichier (Storage), son nom et
-- ses annotations (surlignages, soulignements, ratures en coordonnées PDF).
-- Le bucket user_media accepte désormais les PDF, jusqu'à 20 Mo.

alter table public.note_blocks
  drop constraint if exists note_blocks_type_check;
alter table public.note_blocks
  add constraint note_blocks_type_check
  check (type in ('paragraph', 'heading', 'bulleted', 'todo', 'quote',
                  'code', 'image', 'video', 'link', 'divider', 'pdf'));

update storage.buckets
   set file_size_limit = 20971520,
       allowed_mime_types = array['image/png', 'image/jpeg', 'image/gif',
                                  'image/webp', 'application/pdf']
 where id = 'user_media';
