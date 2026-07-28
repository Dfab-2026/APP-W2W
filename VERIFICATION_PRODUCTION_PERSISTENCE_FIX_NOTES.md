# Verification production persistence fix

Updated only the verification submission persistence flow.

- Verification submission is now re-read from Supabase before the API returns success.
- The API returns an error instead of showing a false Pending state when the database did not persist the status.
- Employer and worker verification submissions both use the same production-safe persistence check.
- The document card now uses the persisted API response and keeps `Pending Approval` after refresh.
- Location, jobs, payments, chat, profile layout, uploads, and other features were not changed.
