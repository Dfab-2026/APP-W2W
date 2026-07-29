# Worker card complete verification flow

Only the section verification state flow was changed.

1. Worker submits a card: that section is stored as `pending`.
2. Worker edits a pending or approved card: that card immediately returns to red `Send for Verification` locally.
3. Worker resubmits: only that section becomes `pending`; untouched section rows remain `verified`.
4. Admin approves the changed section: that section is stored as `verified` and the worker card becomes green `Done` after reload.
5. Because a verified account was edited, the overall account is reopened (`verified = false`) and Admin must use Final Verify again after the changed section is approved.
6. Final Verify restores the overall verified account state.

Run `WORK2WISH_VERIFICATION_SECTION_STATE.sql` in Supabase if the durable section-state table has not already been created.
