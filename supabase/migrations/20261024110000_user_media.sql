-- ============================================================================
-- Médias hors base : bucket privé user_media
-- ============================================================================
-- Les images des fiches et des cartes ne sont plus encodées dans le texte
-- des lignes (base64) : elles sont déposées dans Storage, et le texte ne
-- garde qu'une référence `media://<user_id>/<fichier>`. Chaque compte ne voit
-- et n'écrit que son propre dossier, nommé d'après son identifiant.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'user_media', 'user_media', false, 5242880,
  array['image/png', 'image/jpeg', 'image/gif', 'image/webp']
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "user_media_select_own" on storage.objects;
create policy "user_media_select_own" on storage.objects
  for select to authenticated
  using (bucket_id = 'user_media'
         and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "user_media_insert_own" on storage.objects;
create policy "user_media_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'user_media'
              and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "user_media_update_own" on storage.objects;
create policy "user_media_update_own" on storage.objects
  for update to authenticated
  using (bucket_id = 'user_media'
         and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'user_media'
              and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "user_media_delete_own" on storage.objects;
create policy "user_media_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'user_media'
         and (storage.foldername(name))[1] = auth.uid()::text);
