-- Coil global leaderboard
-- Paste this whole file into Supabase > SQL Editor > New query, then press Run.
-- Running it again is safe.

create table if not exists public.coil_scores (
  day        integer     not null,                 -- Coil No. = day + 1 (day 0 is 2026-10-22)
  player     uuid        not null,                 -- random id kept on the player's device, never shown
  name       text        not null,
  time_ms    integer     not null,
  hints      smallint    not null default 0,
  hard       boolean     not null default false,
  score_ms   integer     generated always as (time_ms + hints * 20000) stored,
  created_at timestamptz not null default now(),
  primary key (day, player)
);
create index if not exists coil_scores_rank on public.coil_scores (day, score_ms, created_at);

-- Lock the table. The public can only reach it through the three functions below.
alter table public.coil_scores enable row level security;
revoke all on public.coil_scores from anon, authenticated;

create or replace function public.coil_today() returns integer
language sql stable as $$
  select (now() at time zone 'utc')::date - date '2026-10-22';
$$;

create or replace function public.coil_clean_name(p_name text) returns text
language plpgsql immutable as $$
declare
  n text := regexp_replace(btrim(coalesce(p_name, '')), '\s+', ' ', 'g');
begin
  if char_length(n) < 2 or char_length(n) > 20 or n !~ '^[A-Za-z0-9 _.\-]+$' then
    raise exception 'Use 2 to 20 letters, numbers, spaces, dots, dashes or underscores.';
  end if;
  if lower(regexp_replace(n, '[^A-Za-z]', '', 'g'))
     ~ '(fuck|shit|cunt|nigg|fagg|bitch|whore|slut|rape|nazi|hitler|porn|retard|wank)' then
    raise exception 'Please pick a different name.';
  end if;
  return n;
end $$;

-- Save a finish. Only the first finish per player per day counts.
create or replace function public.coil_submit(
  p_player uuid, p_name text, p_day integer, p_time_ms integer, p_hints integer, p_hard boolean
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_name text := coil_clean_name(p_name);
begin
  if p_player is null then raise exception 'Missing player id.'; end if;
  -- players' local dates can be a day ahead of or behind UTC
  if p_day is null or p_day not between coil_today() - 1 and coil_today() + 1 then
    raise exception 'That Coil is closed. Play today''s puzzle to get on the board.';
  end if;
  if p_time_ms is null or p_time_ms < 8000 or p_time_ms > 86400000 then
    raise exception 'That time doesn''t look right.';
  end if;
  if p_hints is null or p_hints not between 0 and 5 then
    raise exception 'That hint count doesn''t look right.';
  end if;
  insert into coil_scores (day, player, name, time_ms, hints, hard)
  values (p_day, p_player, v_name, p_time_ms, p_hints, coalesce(p_hard, false))
  on conflict (day, player) do nothing;
end $$;

-- The day's board: total finishers, the top N, and the caller's own row.
create or replace function public.coil_board(p_day integer, p_player uuid default null, p_limit integer default 50)
returns json
language sql stable security definer set search_path = public as $$
  with ranked as (
    select name, time_ms, hints, hard, player,
           rank() over (order by score_ms, created_at) as rank
    from coil_scores
    where day = p_day
  )
  select json_build_object(
    'day', p_day,
    'total', (select count(*) from ranked),
    'me', (select json_build_object('rank', rank, 'name', name, 'time_ms', time_ms, 'hints', hints, 'hard', hard)
           from ranked where p_player is not null and player = p_player),
    'top', coalesce((
      select json_agg(json_build_object(
               'rank', rank, 'name', name, 'time_ms', time_ms, 'hints', hints, 'hard', hard,
               'me', coalesce(player = p_player, false)) order by rank)
      from (select * from ranked order by rank limit least(greatest(coalesce(p_limit, 50), 1), 100)) t
    ), '[]'::json)
  );
$$;

-- Change the name on all of a player's finishes.
create or replace function public.coil_rename(p_player uuid, p_name text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_name text := coil_clean_name(p_name);
begin
  update coil_scores set name = v_name where player = p_player;
end $$;

revoke all on function public.coil_submit(uuid, text, integer, integer, integer, boolean) from public;
revoke all on function public.coil_board(integer, uuid, integer) from public;
revoke all on function public.coil_rename(uuid, text) from public;
grant execute on function public.coil_submit(uuid, text, integer, integer, integer, boolean) to anon, authenticated;
grant execute on function public.coil_board(integer, uuid, integer) to anon, authenticated;
grant execute on function public.coil_rename(uuid, text) to anon, authenticated;
