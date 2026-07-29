# Worker profile and admin approval final fix

- The worker Profile verification card below Resume now immediately changes from red **Send for Verification** to yellow **Pending Approval** after a successful submission.
- The pending state is preserved through production refreshes even when the loaded user identifier changes during hydration.
- The card also reads the just-saved form verification state while the production profile response catches up.
- Admin section approval remains green and disabled as **Approved** after approval, including while refreshed detail data is loading.
- No unrelated screens or workflows were changed.
