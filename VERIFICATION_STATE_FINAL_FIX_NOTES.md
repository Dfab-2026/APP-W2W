# Verification state final fix

Only the verification workflow was changed.

## Result
- Each card has an independent durable state: `draft`, `pending`, `verified`, or `rejected`.
- Editing one card returns only that card to red `Send for Verification`.
- Submitting that card changes only it to yellow `Pending Approval`.
- Admin approval changes only it to green `Done` and it remains green after refresh/login.
- Previously approved cards are not reset when another card is edited.
- Final account verification remains green after it has been completed; later section updates are reviewed section-by-section.
- Worker and employer flows use the same source-of-truth table.

## Required Supabase step
Run `WORK2WISH_VERIFICATION_SECTION_STATE.sql` once in Supabase SQL Editor before deploying the code.
