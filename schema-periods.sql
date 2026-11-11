-- فترات أهداف مخصصة (من تاريخ إلى تاريخ) مع أهدافها لكل قسم — بعد schema-targets.sql
-- نفس قواعد manual_targets: المدير العام بس بيكتب؛ الباقي بيقرأ إذا عنده تبويب الأهداف، وأهداف أقسامه فقط.
create table if not exists public.target_periods (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  d_from date not null,
  d_to date not null,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  check (d_to >= d_from and d_to - d_from <= 366)
);
create table if not exists public.period_targets (
  period_id uuid not null references public.target_periods(id) on delete cascade,
  dept text not null,
  t1 numeric(14,3) not null,
  t2 numeric(14,3) not null,
  t3 numeric(14,3) not null,
  updated_by uuid default auth.uid(),
  updated_at timestamptz not null default now(),
  primary key (period_id, dept),
  check (t1 >= 0 and t1 <= t2 and t2 <= t3)
);
alter table public.target_periods enable row level security;
alter table public.period_targets enable row level security;
drop policy if exists read_allowed on public.target_periods;
create policy read_allowed on public.target_periods for select to authenticated using (
  (select public.is_admin()) or exists (select 1 from public.user_profile p where p.user_id = auth.uid() and 'targets' = any(p.tabs)));
drop policy if exists admin_write on public.target_periods;
create policy admin_write on public.target_periods for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
drop policy if exists read_allowed on public.period_targets;
create policy read_allowed on public.period_targets for select to authenticated using (
  (select public.is_admin()) or (
    exists (select 1 from public.user_profile p where p.user_id = auth.uid() and 'targets' = any(p.tabs))
    and (dept = 'باقي الأقسام' or dept in (select d.name from public.departments d where d.code in (select public.my_depts())))
  ));
drop policy if exists admin_write on public.period_targets;
create policy admin_write on public.period_targets for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
revoke all on public.target_periods, public.period_targets from anon;
grant select, insert, update, delete on public.target_periods, public.period_targets to authenticated;
select 'ok' k, (select count(*) from public.target_periods) periods, (select count(*) from public.period_targets) targets;
