WORK2WISH - SUPABASE ENGAGEMENT NOTIFICATION SCHEDULER

Vercel Hobby cron scheduling is not used.
The existing /api/cron/engagement endpoint and Web Push flow remain in use.

SETUP
1. Open SUPABASE_ENGAGEMENT_CRON_SETUP.sql.
2. Replace YOUR-WORK2WISH-DOMAIN with your deployed Work2Wish domain.
3. Replace CHANGE-ME-TO-A-LONG-RANDOM-SECRET with a strong secret.
4. Add the same value in Vercel -> Project -> Settings -> Environment Variables as CRON_SECRET.
5. Run the SQL once in Supabase SQL Editor.
6. Keep the existing VAPID variables in Vercel and let each user enable Chrome alerts once.

BEHAVIOR
- Supabase calls the engagement endpoint once per day at 10:00 AM India time.
- The endpoint chooses one random message from the existing 100-message bank (50 worker + 50 employer).
- Each subscribed worker/employer receives at most one automated Chrome engagement push per India calendar day.
- Random engagement nudges shown while Work2Wish is open continue inside the app and notification panel without triggering extra Chrome pushes.
- Existing chat, job, Admin and verification push notifications remain immediate.
