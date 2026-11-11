-- الأهداف اليدوية لخانة "الأهداف" — مشتركة بين تطبيق الجهاز والرابط المشترك
-- المدير العام بس بيكتب. الباقي بيقرأ إذا عنده تبويب الأهداف، وبس أقسامه (+ "باقي الأقسام").
-- dept = اسم القسم كما يظهر بخانة الأهداف (نفس departments.name).
create table if not exists public.manual_targets (
  m date not null,                       -- أول يوم بالشهر
  dept text not null,
  t1 numeric(14,3) not null,
  t2 numeric(14,3) not null,
  t3 numeric(14,3) not null,
  updated_by uuid default auth.uid(),
  updated_at timestamptz not null default now(),
  primary key (m, dept),
  check (t1 >= 0 and t1 <= t2 and t2 <= t3)
);
alter table public.manual_targets enable row level security;
drop policy if exists read_allowed on public.manual_targets;
create policy read_allowed on public.manual_targets for select to authenticated using (
  (select public.is_admin()) or (
    exists (select 1 from public.user_profile p where p.user_id = auth.uid() and 'targets' = any(p.tabs))
    and (dept = 'باقي الأقسام' or dept in (select d.name from public.departments d where d.code in (select public.my_depts())))
  ));
drop policy if exists admin_write on public.manual_targets;
create policy admin_write on public.manual_targets for all to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
revoke all on public.manual_targets from anon;
grant select, insert, update, delete on public.manual_targets to authenticated;
