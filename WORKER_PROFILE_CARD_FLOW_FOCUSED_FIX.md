# Worker Profile Verification Card – Focused Flow Fix

Only the worker Profile verification card below Resume Upload was changed.

The card now uses the same section-wise server status flow as the working Bank and Documents cards:

1. Send for Verification (red)
2. Pending Approval (yellow)
3. Done (green after admin approval)
4. Editing an approved profile changes only this card back to Send for Verification (red)

The worker Profile card no longer reads the temporary global form verification status, which previously overrode the latest admin-approved section status.

No other UI or workflow was changed.
