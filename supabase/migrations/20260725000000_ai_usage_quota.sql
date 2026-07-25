-- Controle de custo da IA.
--
-- Antes disto, qualquer JWT válido chamava generate-cards, generate-cards-from-pdf,
-- chat e card-insight sem limite nenhum — um único usuário conseguia esvaziar a
-- conta da DeepSeek.
--
-- Desenho:
--   * `consume_ai_quota` reserva o custo ANTES da chamada à IA, dentro de um
--     advisory lock por usuário, de forma que N requisições simultâneas não
--     passem todas pelo mesmo saldo.
--   * Se a IA falhar, a Edge Function chama `refund_ai_quota` e o usuário não
--     paga pela falha.
--   * As duas funções são `security definer` e só podem ser executadas pelo
--     service_role: se o cliente pudesse chamar `refund_ai_quota` diretamente,
--     bastaria consumir, usar a IA e estornar em seguida.
--   * `ai_quota_status` é o único ponto exposto ao app — somente leitura.

create table if not exists public.ai_user_tiers (
  user_id uuid primary key references auth.users(id) on delete cascade,
  tier text not null default 'free' check (tier in ('free', 'premium')),
  updated_at timestamptz not null default now()
);

alter table public.ai_user_tiers enable row level security;

drop policy if exists "Users can read own tier" on public.ai_user_tiers;
create policy "Users can read own tier"
on public.ai_user_tiers for select
using (user_id = auth.uid());
-- Sem policy de escrita: o tier é definido pelo webhook de billing (service_role).

create table if not exists public.ai_usage (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  operation text not null check (
    operation in ('generate_cards', 'generate_pdf', 'chat', 'insight')
  ),
  cost_units integer not null default 1 check (cost_units > 0),
  created_at timestamptz not null default now()
);

create index if not exists ai_usage_user_created_idx
  on public.ai_usage (user_id, created_at desc);

alter table public.ai_usage enable row level security;

drop policy if exists "Users can read own usage" on public.ai_usage;
create policy "Users can read own usage"
on public.ai_usage for select
using (user_id = auth.uid());
-- Sem policy de insert/update/delete: escrita apenas via funções security definer.

-- Limite mensal em unidades de custo.
create or replace function public.ai_quota_limit(p_tier text)
returns integer
language sql
immutable
as $$
  select case p_tier when 'premium' then 1000 else 30 end;
$$;

-- Teto por minuto, para conter loop acidental do cliente ou disparo em massa.
create or replace function public.ai_rate_limit(p_tier text)
returns integer
language sql
immutable
as $$
  select case p_tier when 'premium' then 20 else 6 end;
$$;

create or replace function public.ai_period_start()
returns timestamptz
language sql
stable
as $$
  select date_trunc('month', now() at time zone 'utc') at time zone 'utc';
$$;

create or replace function public.consume_ai_quota(
  p_user_id uuid,
  p_operation text,
  p_cost_units integer default 1
)
returns table (
  usage_id uuid,
  allowed boolean,
  reason text,
  used integer,
  quota integer,
  period_start timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tier text;
  v_quota integer;
  v_rate integer;
  v_period_start timestamptz := public.ai_period_start();
  v_used integer;
  v_recent integer;
  v_id uuid;
begin
  if p_user_id is null then
    raise exception 'p_user_id is required' using errcode = '22023';
  end if;

  if p_operation not in ('generate_cards', 'generate_pdf', 'chat', 'insight') then
    raise exception 'invalid operation: %', p_operation using errcode = '22023';
  end if;

  if p_cost_units is null or p_cost_units < 1 then
    raise exception 'invalid cost_units: %', p_cost_units using errcode = '22023';
  end if;

  -- Serializa as checagens deste usuário até o fim da transação.
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text, 0));

  select t.tier into v_tier
  from public.ai_user_tiers t
  where t.user_id = p_user_id;

  v_tier := coalesce(v_tier, 'free');
  v_quota := public.ai_quota_limit(v_tier);
  v_rate := public.ai_rate_limit(v_tier);

  select coalesce(sum(u.cost_units), 0)::integer into v_used
  from public.ai_usage u
  where u.user_id = p_user_id
    and u.created_at >= v_period_start;

  select count(*)::integer into v_recent
  from public.ai_usage u
  where u.user_id = p_user_id
    and u.created_at >= now() - interval '1 minute';

  if v_recent >= v_rate then
    return query
      select null::uuid, false, 'rate_limited', v_used, v_quota, v_period_start;
    return;
  end if;

  if v_used + p_cost_units > v_quota then
    return query
      select null::uuid, false, 'quota_exceeded', v_used, v_quota, v_period_start;
    return;
  end if;

  insert into public.ai_usage (user_id, operation, cost_units)
  values (p_user_id, p_operation, p_cost_units)
  returning id into v_id;

  return query
    select v_id, true, null::text, v_used + p_cost_units, v_quota, v_period_start;
end;
$$;

-- Estorna uma reserva quando a chamada à IA falha, para o usuário não pagar
-- por um erro do provedor. A janela curta impede estorno de uso antigo.
create or replace function public.refund_ai_quota(
  p_usage_id uuid,
  p_user_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_deleted integer;
begin
  if p_usage_id is null or p_user_id is null then
    return false;
  end if;

  delete from public.ai_usage
  where id = p_usage_id
    and user_id = p_user_id
    and created_at >= now() - interval '15 minutes';

  get diagnostics v_deleted = row_count;
  return v_deleted > 0;
end;
$$;

-- Consumo do próprio usuário, para a UI. Somente leitura.
create or replace function public.ai_quota_status()
returns table (
  used integer,
  quota integer,
  tier text,
  period_start timestamptz,
  period_end timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_tier text;
  v_period_start timestamptz := public.ai_period_start();
begin
  if v_user_id is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  select t.tier into v_tier
  from public.ai_user_tiers t
  where t.user_id = v_user_id;

  v_tier := coalesce(v_tier, 'free');

  return query
  select
    coalesce(
      (
        select sum(u.cost_units)::integer
        from public.ai_usage u
        where u.user_id = v_user_id
          and u.created_at >= v_period_start
      ),
      0
    ),
    public.ai_quota_limit(v_tier),
    v_tier,
    v_period_start,
    (v_period_start + interval '1 month');
end;
$$;

revoke all on function public.consume_ai_quota(uuid, text, integer) from public;
revoke all on function public.consume_ai_quota(uuid, text, integer) from anon;
revoke all on function public.consume_ai_quota(uuid, text, integer) from authenticated;
grant execute on function public.consume_ai_quota(uuid, text, integer) to service_role;

revoke all on function public.refund_ai_quota(uuid, uuid) from public;
revoke all on function public.refund_ai_quota(uuid, uuid) from anon;
revoke all on function public.refund_ai_quota(uuid, uuid) from authenticated;
grant execute on function public.refund_ai_quota(uuid, uuid) to service_role;

revoke all on function public.ai_quota_status() from public;
revoke all on function public.ai_quota_status() from anon;
grant execute on function public.ai_quota_status() to authenticated;
grant execute on function public.ai_quota_status() to service_role;
