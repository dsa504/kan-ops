# Access model (MVP)

Invite-only with a workspace invite link.

## What we ship

| Setting | Value | Notes |
|---------|--------|------|
| Credentials (email/password) | On | `NEXT_PUBLIC_ALLOW_CREDENTIALS=true` |
| Public signup | Off (after bootstrap) | `NEXT_PUBLIC_DISABLE_SIGN_UP=true` |
| SMTP | On | Existing Proton mailbox (same as other chapter bots) |
| Workspace invite link | Yes | Share in members-only Discord; rotate if leaked |

OAuth (Discord/Google) is out of MVP.

## SMTP

Reuse an existing Proton mailbox already used for chapter automation (no new mailbox for MVP). Prefer a From display name like:

```text
NOLA DSA Kan <your-mailbox@example.com>
```

Keep the chapter’s public human inbox separate from Kan automated mail.

Put SMTP values only in the **server** `.env` (and GitHub Actions secrets if a workflow needs them). Never commit them.

## Bootstrap first admin

On an empty database, Kan allows creating the first user (or temporarily enable signup):

1. Deploy with signup allowed for bootstrap only: set `NEXT_PUBLIC_DISABLE_SIGN_UP=false` (or confirm empty-DB first-registration behavior for the pinned Kan version).
2. Open `https://kan.dsaneworleans.org`, create the admin account.
3. Set `NEXT_PUBLIC_DISABLE_SIGN_UP=true` on the server `.env`.
4. Restart the forever job (`systemctl --user restart …` — exact unit from the MF checklist).
5. In Kan, create a **workspace invite link**.
6. Post the link in the members-only Discord channel (human step).
7. Test a second account joining via the invite link.
8. Confirm SMTP with an invite or password-reset email.

## Day-to-day onboarding

- Members join via the Discord invite link (not one-by-one email invites).
- If the link leaks: deactivate it in Kan, create a new one, update Discord.
- Prefer the invite link over large batches of individual email invites.

## Opening signup later

If the chapter wants open (or temporarily open) signup:

1. Set `NEXT_PUBLIC_DISABLE_SIGN_UP=false` in server `.env`.
2. Restart the forever job.
3. Optionally deactivate the invite link if it is no longer needed.
4. To lock again: set `NEXT_PUBLIC_DISABLE_SIGN_UP=true` and restart.

No code change required — env flip only.

## Options not shipping yet

- Invite-only + per-email invites (higher volunteer cost)
- Open signup + reactive moderation (Kan has no native signup-notify)
- Open signup for a launch window, then lock

These can be revisited with a live demo after invite-link onboarding is running.
