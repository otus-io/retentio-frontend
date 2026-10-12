# Account and navigation

🌐 [中文](knowledge_base_auth_zh.md) · [Knowledge base](knowledge_base.md)

On launch the app restores the last session. Signed-out users can complete account flows and open a public deck detail. Signed-in users land in a three-tab shell: decks, discovery, and profile. When the session dies, protected screens return to login.

## What a session stores

| Object | Fields | Where |
| ------ | ------ | ----- |
| `User` | `email`, `username`, `emailVerified` | `GET /api/profile` |
| Session | `token`, plus a logged-in flag | `SharedPreferences` keys `token` and `isLogin`; a copy of the token is kept in memory for the Authorization header |

Theme mode lives in Hive via HydratedStorage. Locale uses the `localeCode` key. There is no refresh token.

Restore counts as signed in only when `isLogin` is true and `token` is non-empty.

## Startup

1. Crash reporting, Hive, and the API client start. The saved token is loaded.
2. The session is restored. Routes do not redirect until that finishes.
3. The initial location is `/login`.
4. Signed in on `/login` goes to `/`. Signed out on a protected path goes to `/login`.

## Account flows

| Step | Success | Failure or non-goal |
| ---- | ------- | ------------------- |
| Sign in | Username and password are both set; response token is non-empty; tab resets to Decks; go to `/` | Missing fields or API error: show the message. Email verification is not checked |
| Register | All fields set and passwords match; snack says to check email; pop back to login | Does not sign in. The login screen pushes the register page; `/register` is still a public route |
| Forgot password | `POST /auth/forgot-password`. A `reset_token` in the body (dev, no mailer) opens `/reset-password?token=` | Production depends on the mail link. The client does not prove the mail was sent |
| Reset password | Token required; after confirm, go to login | Missing token: error, then login |
| Verify email | Opening `/verify-email?token=` submits immediately | Missing token fails at once; failure can be retried |
| Sign out | Confirm on profile, `POST /auth/logout`, clear token, `isLogin=false` | — |
| 401 | Clear the in-memory and stored token, then restore. An empty token restores as signed out, so protected routes go to login | No guaranteed global toast. The logout endpoint is not called |

## Routes

| Path | Login | Typical source | Rule |
| ---- | ----- | -------------- | ---- |
| `/login` | No | Launch, guard, signed-out placeholder | Signed-in users go to `/` |
| `/register` | No | Deep link | — |
| `/reset-password` | No | Mail, or a dev token | — |
| `/verify-email` | No | Mail | — |
| `/` | Yes | Sign-in or restore | The shell |
| `/discovery/:id` | No | Discovery list or a deep link | Detail is public; Import sends the user to login |
| `/study` | Yes | My decks, or Study after import | `extra` must include a `Deck`. Without it, the screen offers a way home |

The guard runs only after auth state is registered.

## Shell

Three bottom tabs. The default index is 0. A successful sign-in resets the tab to Decks.

| Tab | Signed in | Note |
| --- | --------- | ---- |
| Decks | The user’s deck list | The shell is not reachable signed out |
| Discovery | Public catalog | The catalog API may omit the token, but this tab sits on `/`, so the normal path still requires login |
| Profile | Profile and settings | — |

The shell also has a locked placeholder with a sign-in button. With the guard in place, a signed-out user does not remain on `/`, so that placeholder is rare.

## Profile and preferences

Profile loads `GET /api/profile` and shows username, email, and an initial. An unverified email gets an explanation and a resend action.

Settings: locale (en / zh / ja), theme (light / dark / sepia / system), statistics, tag manager, sign out. Locale starts as en, then the stored `localeCode` replaces it. If theme hydration fails, the fallback is dark. The login-screen theme control only toggles light and dark.

The client does not call a profile update endpoint.

## Code

`lib/main.dart`, `lib/features/auth/`, `lib/routers/app_pages.dart`, `lib/screen/login/`, `lib/screen/register/`, `lib/screen/profile/`, `lib/providers/theme_provider.dart`, `lib/providers/locale_provider.dart`.
