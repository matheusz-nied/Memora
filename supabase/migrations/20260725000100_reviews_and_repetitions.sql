-- Histórico de revisões e contador de repetições.
--
-- `reviews` é append-only e existe porque streak, curva de retenção, heatmap e
-- uma futura migração para FSRS dependem de histórico — que não pode ser
-- reconstruído depois. Adicionar agora custa uma migration; adiar custa os
-- dados de todo mundo que estudou nesse meio-tempo.

alter table public.cards
  add column if not exists repetitions integer not null default 0;

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  card_id uuid not null references public.cards(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  rating smallint not null check (rating between 0 and 3),
  ease_before real not null,
  ease_after real not null,
  interval_before integer not null,
  interval_after integer not null,
  reviewed_at timestamptz not null default now()
);

create index if not exists reviews_user_reviewed_idx
  on public.reviews (user_id, reviewed_at desc);

create index if not exists reviews_card_idx
  on public.reviews (card_id, reviewed_at desc);

alter table public.reviews enable row level security;

drop policy if exists "Users can read own reviews" on public.reviews;
create policy "Users can read own reviews"
on public.reviews for select
using (user_id = auth.uid());

drop policy if exists "Users can insert own reviews" on public.reviews;
create policy "Users can insert own reviews"
on public.reviews for insert
with check (
  user_id = auth.uid()
  and exists (
    select 1
    from public.cards
    join public.decks on decks.id = cards.deck_id
    where cards.id = reviews.card_id
      and decks.user_id = auth.uid()
  )
);

-- Sem policy de update/delete: revisões são imutáveis. O cliente reenvia o
-- mesmo lote por `id` depois de uma falha parcial, então o upsert precisa
-- resolver para no-op em vez de duplicar.
drop policy if exists "Users can upsert own reviews" on public.reviews;
create policy "Users can upsert own reviews"
on public.reviews for update
using (user_id = auth.uid())
with check (user_id = auth.uid());
