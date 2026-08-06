create table if not exists questions (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references auth.users(id) on delete cascade,
  client_email text not null,
  prenom text,
  texte text not null,
  reponse text,
  publique boolean default false,
  repondu boolean default false,
  created_at timestamptz default now(),
  answered_at timestamptz
);

create index if not exists idx_questions_coach on questions(coach_id);
create index if not exists idx_questions_pub on questions(coach_id, publique, repondu);

alter table questions enable row level security;

drop policy if exists "coach gere les questions" on questions;
create policy "coach gere les questions" on questions
  for all to authenticated
  using (auth.uid() = coach_id)
  with check (auth.uid() = coach_id);

drop policy if exists "client pose sa question" on questions;
create policy "client pose sa question" on questions
  for insert to authenticated
  with check (lower(client_email) = lower(auth.jwt() ->> 'email'));

drop policy if exists "client lit ses questions et les publiques" on questions;
create policy "client lit ses questions et les publiques" on questions
  for select to authenticated
  using (
    lower(client_email) = lower(auth.jwt() ->> 'email')
    or (publique = true and repondu = true)
  );

drop policy if exists "client supprime sa question" on questions;
create policy "client supprime sa question" on questions
  for delete to authenticated
  using (lower(client_email) = lower(auth.jwt() ->> 'email') and repondu = false);
