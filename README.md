# HT Digital Skills — Website Setup Guide

This is your complete website. It is one static site (made for GitHub + Vercel)
that uses **Supabase** (free) for accounts, one shared login and saved data.

**Good news:** the public website and WhatsApp enrollment work **even before**
any setup. Supabase setup is only needed to switch ON the login, student
dashboard and admin dashboard.

Files in this project:

| File | What it is |
|---|---|
| `index.html` | The whole website (home, courses, enroll, login, signup, dashboards) |
| `config.js` | Where you paste your Supabase keys |
| `supabase-schema.sql` | Database setup — run once in Supabase |
| `assets/founder-poster.png` | Founder poster used on the website |
| `README.md` | This guide |

---

## STEP 1 — Create the free Supabase project (database + login system)

1. Go to **supabase.com** and sign up (free).
2. Click **New project**. Give it any name, e.g. `ht-digital-skills`.
3. Set a database password and save it somewhere safe. Choose the nearest region.
4. Wait 1–2 minutes for the project to be created.
5. In the left menu, open **SQL Editor** → **New query**.
6. Open the file `supabase-schema.sql` from this project, copy **everything**,
   paste it into the SQL Editor, and click **Run**.
   - This creates the students, courses and applications tables,
     all security rules, and your 10 courses (fees left empty on purpose —
     you will add fees later from your admin dashboard).

## STEP 2 — Make your own account the ADMIN

There is **only one Sign Up and one Login** on this website. The owner uses
the same Sign Up/Login as students — there is no separate admin login page
and no default admin password.

Do this step after the website is connected and live (Steps 3–5):

1. Open your live website and click **Sign Up**.
2. Create your account with **your own email** and **your own password**.
   (If email confirmation is on, confirm the email first.)
3. Go to Supabase → **SQL Editor** → **New query**.
4. Run this **one line**, replacing `YOUR_EMAIL_HERE` with the exact email
   you used in Sign Up:

```sql
update public.profiles set role = 'admin' where id = (select id from auth.users where email = 'YOUR_EMAIL_HERE');
```

5. Log out of the website, then log in again from the same **Login** using
   that email and password. Your **Admin Dashboard** will open automatically.

> Students use the exact same Sign Up/Login and see the student dashboard.
> Only the account you upgrade with the SQL line above becomes admin.

## STEP 3 — Connect the website to Supabase

1. In Supabase, go to **Settings → API**.
2. Copy the **Project URL** and the **anon public** key.
3. Open `config.js` and paste them:

```js
window.HT_CONFIG = {
  SUPABASE_URL: "https://your-project.supabase.co",
  SUPABASE_ANON_KEY: "your-anon-public-key-here"
};
```

4. Save the file. (On GitHub you can edit `config.js` directly in the
   browser and commit — Vercel will redeploy automatically.)

## STEP 4 — Put the website on GitHub

1. Go to **github.com** → **New repository**. Name it e.g. `ht-digital-skills`.
2. Choose **Public**, create the repo.
3. Click **uploading an existing file** and upload ALL project files,
   keeping the same structure:

```
index.html
config.js
supabase-schema.sql   (optional on GitHub, safe to include)
README.md             (optional)
assets/founder-poster.png
```

   Make sure `assets/founder-poster.png` stays inside the `assets` folder.
4. Click **Commit changes**.

## STEP 5 — Deploy on Vercel

1. Go to **vercel.com** → sign in with GitHub.
2. Click **Add New → Project** and import your `ht-digital-skills` repo.
3. Framework Preset: **Other**. Build Command: **leave empty**. Output: default.
4. Click **Deploy**. In about a minute your website is live on a
   `*.vercel.app` address.
5. Every time you push a change to GitHub, Vercel redeploys automatically.

---

## How the website works

### For visitors (no account)
- They browse courses and click **Enroll Now → Guest**.
- The form opens **WhatsApp** with their details ready to send to
  **+92 304 6004229**. Nothing is ever lost.
- If Supabase is connected, the same lead is also saved in the admin
  dashboard (marked "WhatsApp Guest").

### For students (free account)
- **Sign Up** with name, phone, email and password → **Login**.
- In the student dashboard they can submit a course application
  **inside the website** and see its status (New / Contacted /
  Enrolled / Rejected).
- They can also choose WhatsApp from the enroll page if they prefer.

### For you (admin)
- Use the same **Login** with the owner email and password from Step 2.
- **Applications:** see all guest + student applications, filter by
  status, change status, or delete.
- **Students:** see all registered students and how many applications
  each one submitted.
- **Courses:** add, edit (name, fee, duration, description) or delete
  courses. Changes appear on the public website automatically.
- **Counts:** total applications, new, enrolled and total courses.

## Notes

- Course fees and durations were **not** invented. Add the real ones
  from your admin dashboard (Courses box) and they will show on the
  public course cards.
- If login ever shows "not active", it means `config.js` does not have
  the Supabase keys yet — the rest of the website still works.
- Keep your Supabase **service_role** key secret. Only the **anon public**
  key goes in `config.js` — that is safe for websites because the
  database security rules (RLS) protect your data.

Founder & CEO: **Hafiz Tabbasum** — HT Digital Skills
Contact: +92 304 6004229 • htdigitalskills@gmail.com • htdigitalskills.vercel.app
