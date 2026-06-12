-- Supabase Storage setup for PBLC assignment files
-- Run this whole script in Supabase SQL Editor.
-- This configuration is for client-side uploads using anon key.

-- 1) Ensure bucket exists and is public so download URLs work directly.
insert into storage.buckets (id, name, public)
values ('assignment-files', 'assignment-files', true)
on conflict (id) do update set public = excluded.public;

-- 2) Remove old conflicting policies if they exist.
drop policy if exists "assignment_files_public_read" on storage.objects;
drop policy if exists "assignment_files_anon_insert" on storage.objects;
drop policy if exists "assignment_files_anon_update" on storage.objects;
drop policy if exists "assignment_files_anon_delete" on storage.objects;

-- 3) Public read for files in assignment-files bucket.
create policy "assignment_files_public_read"
on storage.objects
for select
to public
using (bucket_id = 'assignment-files');

-- 4) Allow anon uploads from Flutter app.
create policy "assignment_files_anon_insert"
on storage.objects
for insert
to anon
with check (bucket_id = 'assignment-files');

-- 5) Allow anon overwrite/upsert from Flutter app.
create policy "assignment_files_anon_update"
on storage.objects
for update
to anon
using (bucket_id = 'assignment-files')
with check (bucket_id = 'assignment-files');

-- 6) Optional: allow anon delete. Keep disabled unless needed.
create policy "assignment_files_anon_delete"
on storage.objects
for delete
to anon
using (bucket_id = 'assignment-files');

-- NOTE:
-- This is practical for student projects and demos.
-- For stronger security, move uploads to a backend and issue signed upload URLs.
