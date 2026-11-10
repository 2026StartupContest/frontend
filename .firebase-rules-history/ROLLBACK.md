# Rules rollback

## Deployed
- Project: `moa-club`
- Database: `moa-db`
- Storage bucket: `moa-club.firebasestorage.app`
- Stamp: `20261110T161817Z`
- Change: dues, payments, and ledger rules, plus ledger receipt storage path

## Previous revision (local snapshot)
Captured from the live rules immediately before this deploy.

- Firestore: `pre-accounting-20261110T161817Z.rules`
- Storage: `pre-accounting-20261110T161817Z.storage.rules`

The earlier attendance snapshot `pre-attendance-20261110T142647Z.rules` is still in this folder. Restoring it would also remove the attendance rules that are already live.

## Rollback (CLI)
```bash
cp .firebase-rules-history/pre-accounting-20261110T161817Z.rules firestore.rules
cp .firebase-rules-history/pre-accounting-20261110T161817Z.storage.rules storage.rules
firebase deploy --only firestore:moa-db:rules,storage --project moa-club --non-interactive
```

## Rollback (Console)
Firebase Console → Firestore → Rules → History → restore the release before this one.
https://console.firebase.google.com/project/moa-club/firestore/databases/moa-db/rules

Storage rules history:
https://console.firebase.google.com/project/moa-club/storage/moa-club.firebasestorage.app/rules
