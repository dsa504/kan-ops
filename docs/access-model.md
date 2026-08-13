# Access model (MVP)

Chapter preference (confirmed with access management): **option 2** — not completely open signup; members get in via a **non-public Discord invite link** (and/or email invites), not by advertising open registration.

| Option | Meaning | MVP |
|--------|---------|-----|
| **1** | Completely open signup (lowest friction; bots can hit `/signup`) | Not chosen |
| **2** | Self-service via Discord invite link (not posted publicly) and/or email invites | **Shipping** |

## What we ship

| Setting | Value | Notes |
|---------|--------|------|
| Credentials (email/password) | On | `NEXT_PUBLIC_ALLOW_CREDENTIALS=true` |
| `NEXT_PUBLIC_DISABLE_SIGN_UP` | `false` for invite-link path | See **Kan caveat** — not the same as “option 1” |
| SMTP | On | Existing Proton mailbox (same as other chapter bots) |
| Workspace invite link | Yes | Members-only Discord only; rotate if leaked |

OAuth (Discord/Google) is out of MVP.

## Kan caveat (`NEXT_PUBLIC_DISABLE_SIGN_UP` + invite links)

On Kan **v0.6.0**, `NEXT_PUBLIC_DISABLE_SIGN_UP=true` only allows new account creation when that email already has a **pending email invite** (`status=invited`). A **workspace invite link** does **not** count for that check.

Practical effect:

- Invite link → Sign up with signup **disabled** → Better Auth often returns **400** (hook rejects user create).
- The signup **page** still opens for `/signup?next=/invite/...`, but account creation fails server-side.

**How this still satisfies option 2:** keep `NEXT_PUBLIC_DISABLE_SIGN_UP=false` so the invite-link flow works, and treat access control as **distribution of the invite URL** (members-only Discord, rotate if leaked). Do **not** advertise `/signup` or “create an account at kan.dsaneworleans.org” in public channels.

Residual risk vs true hard-lock: anyone who discovers `/signup` can register while the env flag is `false`. That is narrower than option 1 (no public call-to-action) but not as hard as email-invite-only with `DISABLE_SIGN_UP=true`.

Hard lock (`true`) works for **email invites**, not for invite-link joiners, unless Kan is patched or upgraded to treat invite codes like pending invites.

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
