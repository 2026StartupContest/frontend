# Rules rollback

## Deployed
- Project: `moa-club`
- Database: `moa-db`
- Storage bucket: `moa-club.firebasestorage.app`
- Stamp: `20261110T172252Z`
- Change: N차 정산 rules. Notice kind `settlement` is staff-only. Draft settlements are staff-only. Members can read collecting and done settlements, and only their own share.

## Previous revision (local snapshot)
Captured from the repository rules immediately before this deploy. Those rules are the accounting release that was already live.

- Firestore: `pre-settlement-20261110T172252Z.rules`
- Storage was not changed. The accounting snapshot `pre-accounting-20261110T161817Z.storage.rules` is still in this folder.

The earlier attendance snapshot `pre-attendance-20261110T142647Z.rules` is still in this folder. Restoring it would also remove the attendance and accounting rules that are already live.

## Rollback (CLI)
```bash
cp .firebase-rules-history/pre-settlement-20261110T172252Z.rules firestore.rules
firebase deploy --only firestore:moa-db:rules --project moa-club --non-interactive
```

## Rollback (Console)
Firebase Console → Firestore → Rules → History → restore the release before this one.
https://console.firebase.google.com/project/moa-club/firestore/databases/moa-db/rules

Storage rules history:
https://console.firebase.google.com/project/moa-club/storage/moa-club.firebasestorage.app/rules
