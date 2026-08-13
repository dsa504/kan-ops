# Access model (MVP)

Chapter preference: **not** completely open signup. Members are brought in deliberately.

| Option | Meaning | Status |
|--------|---------|--------|
| **1** | Completely open signup (lowest friction; bots can hit `/signup`) | Not chosen |
| **2a** | **Email-invite-only** — admin emails invites; `NEXT_PUBLIC_DISABLE_SIGN_UP=true` | **Shipping first** |
| **2b** | Workspace **invite link** in members-only Discord | Optional later — see risk below |

## What we ship first (2a)

| Setting | Value | Notes |
|---------|--------|------|
| Credentials (email/password) | On | `NEXT_PUBLIC_ALLOW_CREDENTIALS=true` |
| Public signup | **Off** | `NEXT_PUBLIC_DISABLE_SIGN_UP=true` |
| SMTP | On | Required for email invites / password reset |
| Workspace invite link | Off / unused for MVP start | Can enable later if chapter accepts residual risk |

OAuth (Discord/Google) is out of MVP.

## How email invites work

1. Admin → **Members** → **Invite** → enter the person’s email → send.
2. They receive mail (Proton SMTP) with a join/sign-up path.
3. With signup disabled, Kan only allows account creation if that email has a **pending invitation** (`status=invited`).
4. After they accept, they appear as a workspace member.

This matches hard invite-only on Kan **v0.6.0**.

## Optional later: invite link (2b) and residual risk

On Kan **v0.6.0**, a workspace invite link **does not** count as a pending email invite. For link joiners to self-register, `NEXT_PUBLIC_DISABLE_SIGN_UP` must be **`false`**.

Residual risk if the chapter enables 2b:

- Anyone who discovers `/signup` can create an account while the flag is `false`.
- Mitigations: do not advertise `/signup` publicly; only share the invite URL in members-only Discord; rotate the link if leaked; watch the Members list.

**Decision pending access management:** if they accept that risk, flip to `NEXT_PUBLIC_DISABLE_SIGN_UP=false`, create an invite link, post it in Discord. Until then, stay on **2a**.

## SMTP

Reuse an existing Proton mailbox already used for chapter automation (no new mailbox for MVP). Prefer a From display name like:

```text
NOLA DSA Kan <your-mailbox@example.com>
```

Keep the chapter’s public human inbox separate from Kan automated mail.

Put SMTP values only in the **server** `.env` (and GitHub Actions secrets if a workflow needs them). Never commit them.

## Bootstrap first admin

1. Deploy with `NEXT_PUBLIC_DISABLE_SIGN_UP=false` long enough to create the first admin (or empty-DB first user).
2. Create admin account at `https://kan.dsaneworleans.org`.
3. Set `NEXT_PUBLIC_DISABLE_SIGN_UP=true` and restart the forever job.
4. Confirm `/signup` shows signup disabled for strangers.
5. Invite a test user **by email** from Members → Invite; confirm mail + join.
6. Confirm password-reset email if desired.

## Day-to-day onboarding (2a)

- Admins send email invites from Members (batch carefully; volunteer cost is higher than a single Discord link).
- No public signup; no Discord invite link required for MVP start.

## Flipping env

1. Edit `NEXT_PUBLIC_DISABLE_SIGN_UP` in server `.env`.
2. `systemctl --user restart red-item-388573.service` (or current unit name).

## Options not shipping yet

- Open signup + reactive moderation (option 1)
- Patch Kan so invite-link codes exempt `user.create` when signup is disabled
