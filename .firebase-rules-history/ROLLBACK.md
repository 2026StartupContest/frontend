# Firestore rules rollback

## Deployed
- Project: `moa-club`
- Database: `moa-db`
- Stamp: `20261110T142647Z`
- Change: QR attendance (`qr` / `attendance` / `proofs`) rules

## Previous revision (local snapshot)
- File: `pre-attendance-20261110T142647Z.rules`
- Captured from live rules immediately before this deploy

## Rollback (CLI)
```bash
cp .firebase-rules-history/pre-attendance-20261110T142647Z.rules firestore.rules
firebase deploy --only firestore:rules --project moa-club --non-interactive
```

## Rollback (Console)
Firebase Console → Firestore → Rules → History → restore previous release
https://console.firebase.google.com/project/moa-club/firestore/databases/moa-db/rules
