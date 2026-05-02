create extension if not exists pgcrypto;

create table if not exists public.decks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  agent_name text not null default 'Tutor',
  agent_prompt text,
  agent_template text not null default 'general',
  agent_language text not null default 'português',
  agent_level text not null default 'intermediário',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.cards (
  id uuid primary key default gen_random_uuid(),
  deck_id uuid not null references public.decks(id) on delete cascade,
  front text not null,
  back text not null,
  ease_factor real not null default 2.5,
  interval_days integer not null default 1,
  due_date date not null default current_date,
  insight text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  deck_id uuid not null references public.decks(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists decks_user_id_updated_at_idx
  on public.decks (user_id, updated_at desc);

create index if not exists cards_deck_id_due_date_idx
  on public.cards (deck_id, due_date asc);

create index if not exists chat_messages_deck_id_created_at_idx
  on public.chat_messages (deck_id, created_at asc);

alter table public.decks enable row level security;
alter table public.cards enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists "Users can read own decks" on public.decks;
create policy "Users can read own decks"
on public.decks for select
using (user_id = auth.uid());

drop policy if exists "Users can insert own decks" on public.decks;
create policy "Users can insert own decks"
on public.decks for insert
with check (user_id = auth.uid());

drop policy if exists "Users can update own decks" on public.decks;
create policy "Users can update own decks"
on public.decks for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "Users can delete own decks" on public.decks;
create policy "Users can delete own decks"
on public.decks for delete
using (user_id = auth.uid());

drop policy if exists "Users can read cards from own decks" on public.cards;
create policy "Users can read cards from own decks"
on public.cards for select
using (
  exists (
    select 1 from public.decks
    where decks.id = cards.deck_id
      and decks.user_id = auth.uid()
  )
);

drop policy if exists "Users can insert cards into own decks" on public.cards;
create policy "Users can insert cards into own decks"
on public.cards for insert
with check (
  exists (
    select 1 from public.decks
    where decks.id = cards.deck_id
      and decks.user_id = auth.uid()
  )
);

drop policy if exists "Users can update cards from own decks" on public.cards;
create policy "Users can update cards from own decks"
on public.cards for update
using (
  exists (
    select 1 from public.decks
    where decks.id = cards.deck_id
      and decks.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.decks
    where decks.id = cards.deck_id
      and decks.user_id = auth.uid()
  )
);

drop policy if exists "Users can delete cards from own decks" on public.cards;
create policy "Users can delete cards from own decks"
on public.cards for delete
using (
  exists (
    select 1 from public.decks
    where decks.id = cards.deck_id
      and decks.user_id = auth.uid()
  )
);

drop policy if exists "Users can read own chat messages" on public.chat_messages;
create policy "Users can read own chat messages"
on public.chat_messages for select
using (
  user_id = auth.uid()
  and exists (
    select 1 from public.decks
    where decks.id = chat_messages.deck_id
      and decks.user_id = auth.uid()
  )
);

drop policy if exists "Users can insert own chat messages" on public.chat_messages;
create policy "Users can insert own chat messages"
on public.chat_messages for insert
with check (
  user_id = auth.uid()
  and exists (
    select 1 from public.decks
    where decks.id = chat_messages.deck_id
      and decks.user_id = auth.uid()
  )
);

insert into storage.buckets (id, name, public)
values ('pdfs', 'pdfs', false)
on conflict (id) do nothing;

drop policy if exists "Users can read own PDFs" on storage.objects;
create policy "Users can read own PDFs"
on storage.objects for select
using (
  bucket_id = 'pdfs'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can upload own PDFs" on storage.objects;
create policy "Users can upload own PDFs"
on storage.objects for insert
with check (
  bucket_id = 'pdfs'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can update own PDFs" on storage.objects;
create policy "Users can update own PDFs"
on storage.objects for update
using (
  bucket_id = 'pdfs'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'pdfs'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can delete own PDFs" on storage.objects;
create policy "Users can delete own PDFs"
on storage.objects for delete
using (
  bucket_id = 'pdfs'
  and (storage.foldername(name))[1] = auth.uid()::text
);
