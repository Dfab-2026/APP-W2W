# Custom-domain authentication fix

This build fixes API `401 Unauthorized` responses that occurred on `https://app.work2wish.com` while the same deployment worked on the Vercel URL.

Changes:
- API requests now obtain the access token from Supabase's active session for the current browser origin before using the app's saved wrapper session.
- Login now waits for `supabase.auth.setSession()` to complete before opening the dashboard.
- Supabase token refresh events are synchronized back into the Work2Wish session state.
- Boot restoration saves and uses the refreshed session rather than reusing the old token.
- Multipart uploads use the same current-origin token resolution.

No unrelated UI or feature logic was changed.
