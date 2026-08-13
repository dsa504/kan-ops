# Access model (MVP)

Invite-link onboarding with credentials (email/password).

## What we ship

| Setting | Value | Notes |
|---------|--------|------|
| Credentials (email/password) | On | `NEXT_PUBLIC_ALLOW_CREDENTIALS=true` |
| Public signup UI | On for invite-link MVP | See **Kan caveat** below |
| SMTP | On | Existing Proton mailbox (same as other chapter bots) |
| Workspace invite link | Yes | Share in members-only Discord; rotate if leaked |

OAuth (Discord/Google) is out of MVP.

## Kan caveat (`NEXT_PUBLIC_DISABLE_SIGN_UP` + invite links)

On Kan **v0.6.0**, `NEXT_PUBLIC_DISABLE_SIGN_UP=true` only allows new account creation when that email already has a **pending email invite** (`status=invited`). A **workspace invite link** does **not** count for that check.

Practical effect:

- Invite link → Sign up with signup **disabled** → Better Auth often returns **400** (hook rejects user create).
- The signup **page** still opens for `/signup?next=/invite/...`, but account creation fails server-side.

**MVP choice:** keep `NEXT_PUBLIC_DISABLE_SIGN_UP=false` and rely on the **invite link** (Discord-only distribution + rotate if leaked). Locking signup with `true` works for **email invites**, not for invite-link joiners, unless Kan is patched or upgraded to treat invite codes like pending invites.

Do **not** leave `/signup` linked in public chapter materials; only share the invite URL.

## SMTP

Reuse an existing Proton mailbox already used for chapter automation (no new mailbox for MVP). Prefer a From display name like:

```text
NOLA DSA Kan <your-mailbox@example.com>
```

Keep the chapter’s public human inbox separate from Kan automated mail.

Put SMTP values only in the **server** `.env` (and GitHub Actions secrets if a workflow needs them). Never commit them.

## Bootstrap first admin

1. Deploy with `NEXT_PUBLIC_DISABLE_SIGN_UP=false`.
2. Open `https://kan.dsaneworleans.org`, create the admin account.
3. Leave signup **enabled** for invite-link MVP (or switch to email-invite-only if you set `true`).
4. In Kan → **Members** → **Invite** → toggle **Create invite link**; copy the URL.
5. Post the link in the members-only Discord channel (human step).
6. Test a second account: open invite link → **Sign Up** → land in the workspace.
7. Confirm SMTP with a password-reset or email invite.

## Day-to-day onboarding

- Members join via the Discord invite link.
- If the link leaks: deactivate it in Kan, create a new one, update Discord.
- Prefer the invite link over large batches of individual email invites.

## If you need signup locked (`true`)

Use **email invites** (Members → invite by email) so each address has a pending invitation before they register. Workspace invite links will not work for brand-new users until upstream fixes the hook.

## Opening signup later / locking later

Env flip only:

1. Set `NEXT_PUBLIC_DISABLE_SIGN_UP` true/false in server `.env`.
2. Restart the forever job.

Remember: `true` breaks invite-link signup for new users on v0.6.0.

## Options not shipping yet

- Invite-only + per-email invites as the primary path (works with signup disabled)
- Open signup + reactive moderation (Kan has no native signup-notify)
- Patch Kan so invite-link codes exempt `user.create` when signup is disabled

These can be revisited after invite-link onboarding is running.
