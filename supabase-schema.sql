-- ============================================================
--  HT DIGITAL SKILLS — SUPABASE DATABASE SCHEMA
-- ============================================================
--  HOW TO USE:
--  1. Open your Supabase project.
--  2. Go to "SQL Editor" -> "New query".
--  3. Paste this whole file and click "Run".
--
--  This creates the tables, security rules (RLS), an automatic
--  profile on signup, and seeds the 10 courses (no fees are
--  invented — the admin can add fees/durations later from the
--  admin dashboard).
-- ============================================================

create extension if not exists "pgcrypto";

-- ------------------------------------------------------------
--  TABLES
-- ------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text default '',
  phone text default '',
  role text not null default 'student' check (role in ('student', 'admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.courses (
  id bigint generated always as identity primary key,
  name text not null unique,
  fee text default '',
  duration text default '',
  description text default '',
  created_at timestamptz not null default now()
);

create table if not exists public.applications (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users (id) on delete set null,
  full_name text not null default '',
  phone text not null default '',
  email text default '',
  course_name text not null default '',
  message text default '',
  source text not null default 'website' check (source in ('website', 'guest_whatsapp')),
  status text not null default 'new' check (status in ('new', 'contacted', 'enrolled', 'rejected')),
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
--  HELPER: is the logged-in user an admin?
-- ------------------------------------------------------------

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ------------------------------------------------------------
--  AUTO-CREATE PROFILE ON SIGNUP
-- ------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.raw_user_meta_data ->> 'phone', ''),
    'student'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ------------------------------------------------------------
--  ROW LEVEL SECURITY (RLS)
-- ------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.courses enable row level security;
alter table public.applications enable row level security;

-- Table privileges (RLS policies below still control the rows)
grant select on public.courses to anon, authenticated;
grant insert, update, delete on public.courses to authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update, delete on public.applications to anon, authenticated;

-- ---------- PROFILES policies ----------
drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile"
  on public.profiles for select
  to authenticated
  using (id = auth.uid());

drop policy if exists "Admins can read all profiles" on public.profiles;
create policy "Admins can read all profiles"
  on public.profiles for select
  to authenticated
  using (public.is_admin());

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles for insert
  to authenticated
  with check (id = auth.uid() and role = 'student');

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid() and role = 'student');

drop policy if exists "Admins can update all profiles" on public.profiles;
create policy "Admins can update all profiles"
  on public.profiles for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------- COURSES policies ----------
drop policy if exists "Anyone can read courses" on public.courses;
create policy "Anyone can read courses"
  on public.courses for select
  to anon, authenticated
  using (true);

drop policy if exists "Admins can add courses" on public.courses;
create policy "Admins can add courses"
  on public.courses for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "Admins can update courses" on public.courses;
create policy "Admins can update courses"
  on public.courses for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Admins can delete courses" on public.courses;
create policy "Admins can delete courses"
  on public.courses for delete
  to authenticated
  using (public.is_admin());

-- ---------- APPLICATIONS policies ----------
drop policy if exists "Anyone can submit an application" on public.applications;
create policy "Anyone can submit an application"
  on public.applications for insert
  to anon, authenticated
  with check (user_id is null or user_id = auth.uid());

drop policy if exists "Users can read own applications" on public.applications;
create policy "Users can read own applications"
  on public.applications for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "Admins can read all applications" on public.applications;
create policy "Admins can read all applications"
  on public.applications for select
  to authenticated
  using (public.is_admin());

drop policy if exists "Admins can update applications" on public.applications;
create policy "Admins can update applications"
  on public.applications for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Admins can delete applications" on public.applications;
create policy "Admins can delete applications"
  on public.applications for delete
  to authenticated
  using (public.is_admin());

-- ------------------------------------------------------------
--  SEED THE 10 COURSES (fee / duration left empty on purpose —
--  the admin fills them in from the admin dashboard)
-- ------------------------------------------------------------

insert into public.courses (name) values
  ('YouTube Automation'),
  ('Digital Marketing'),
  ('Copyright Work'),
  ('Graphic Design'),
  ('Video Editing'),
  ('Web Development'),
  ('SEO'),
  ('TikTok Automation'),
  ('Facebook Automation'),
  ('E-Commerce')
on conflict (name) do nothing;

-- ============================================================
--  MAKE YOURSELF ADMIN (run AFTER you sign up on the website)
-- ============================================================
--  1. Sign up on your website with your own email + password.
--  2. Come back here, replace YOUR_EMAIL_HERE with that email,
--     and run only this one line:
--
--  update public.profiles set role = 'admin' where id = (select id from auth.users where email = 'YOUR_EMAIL_HERE');
-- ============================================================
