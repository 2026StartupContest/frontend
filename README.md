# 모아

동아리 회비, 모임, 가입, 역할을 한 곳에서 다루는 Flutter 앱입니다. 화면은 `AuthGateway`와 `ClubGateway`만 호출하고, 실제 저장소는 Firebase Authentication, 이름 있는 Firestore 데이터베이스 `moa-db`, Firebase Storage입니다.

현재 실행 대상은 iOS입니다. `lib/firebase_options.dart`의 `DefaultFirebaseOptions.currentPlatform`은 iOS 옵션만 반환합니다.

## 디렉터리

| 경로 | 역할 |
| --- | --- |
| `lib/main.dart` | `.env` 로드, Firebase 초기화, 게이트웨이 주입, 시작 화면 결정 |
| `lib/app/app.dart` | `MaterialApp`, 한국어 로케일, `AppTheme` |
| `lib/router/` | 경로 상수와 화면 연결 |
| `lib/screens/` | 화면. 공용 UI는 여기에 새로 만들지 않습니다 |
| `lib/widgets/` | 여러 화면이 같이 쓰는 컴포넌트 |
| `lib/data/gateways.dart` | 화면이 의존하는 인터페이스 |
| `lib/data/services/` | Firebase 구현 |
| `lib/models/` | Firestore 문서와 화면 인자 |
| `lib/core/` | 색, 시간, 권한, 검증, 포맷 |
| `firestore.rules` | `moa-db` 보안 규칙 |
| `storage.rules` | 이미지 업로드 규칙 |
| `firebase.json` | 배포 대상. Firestore 데이터베이스 ID는 `moa-db` |
| `.firebaserc` | 기본 프로젝트 `moa-club` |

새 화면은 `lib/router/app_routes.dart`에 경로를 추가하고 `lib/router/app_router.dart`의 `switch`에 연결합니다. 화면 생성자에는 `MoaDependencies`를 넘깁니다. Firebase SDK를 화면에서 직접 호출하지 않습니다.

## 환경 설정

### 필요한 도구

- Flutter **3.47.9** (Dart SDK `^3.13.7`)
- Xcode와 iOS 시뮬레이터 또는 실기기
- CocoaPods
- Firebase CLI (`firebase-tools`)
- 프로젝트 `moa-club`에 대한 Firebase 콘솔 권한

버전은 저장소 루트의 `.fvmrc`에 고정되어 있습니다. VS Code / Cursor는 `.vscode/settings.json`에서 SDK를 `.fvm/versions/3.47.9`로 봅니다.

```bash
# FVM이 없다면 https://fvm.app 설치 후
fvm install
fvm flutter pub get
```

FVM 없이 같은 Flutter 버전을 이미 쓰고 있다면 `flutter pub get`만 실행해도 됩니다.

### `.env`

`pubspec.yaml`의 `assets`에 `.env`가 들어 있어서, 파일이 없으면 에셋 번들링이 실패합니다. 파일은 `.gitignore` 대상이라 각자 만듭니다.

```bash
printf 'API_BASE_URL=\n' > .env
```

`EnvConfig.load()`는 파일이 없어도 런타임에서는 넘어가도록 `isOptional: true`입니다. `EnvConfig.apiBaseUrl`은 `API_BASE_URL`을 읽고, 없으면 빈 문자열입니다. 현재 화면 흐름은 이 값을 사용하지 않습니다.

### iOS와 Firebase 클라이언트 설정

아래 파일은 저장소에 포함되어 있습니다. 프로젝트를 새로 만들거나 번들 ID를 바꾸기 전에는 다시 생성하지 않습니다.

| 파일 | 내용 |
| --- | --- |
| `lib/firebase_options.dart` | iOS `FirebaseOptions`. `projectId`는 `moa-club` |
| `ios/Runner/GoogleService-Info.plist` | iOS용 GoogleService 설정 |
| `ios/Runner/Info.plist` | 앱 표시 이름 `모아`, Google 로그인 URL 스킴, `GIDClientID`, 카메라·사진 사용 설명 |
| `ios/Runner.xcodeproj` | 번들 ID `com.example.flutterProj` |

Google 로그인은 `GoogleSignIn.instance.initialize()` 후 `authenticate()`로 ID 토큰을 받아 `GoogleAuthProvider.credential`로 Firebase Auth에 넘깁니다. 사용자가 시트를 닫으면 `authErrorMessage`가 빈 문자열을 반환하고, 화면은 그 경우 스낵바를 띄우지 않습니다.

카메라 권한 문구는 초대 QR 스캔용이고, 사진 보관함 문구는 동아리 대표 이미지용입니다.

서비스 계정 키(`*-firebase-adminsdk-*.json`)와 `.firebase/`는 커밋하지 않습니다.

### 실행과 검사

```bash
fvm flutter run
fvm flutter analyze
fvm flutter test
```

`flutter test`는 `test/moa_logic_test.dart`와 `test/widget_test.dart`를 실행합니다. 로직 테스트는 Firebase 없이 권한, 세션 분기, 모임 필터, 포맷을 확인합니다.

릴리스 서명은 아직 디버그 키입니다. Android `applicationId`는 `com.example.flutter_proj`이고, 현재 Firebase 옵션은 Android를 지원하지 않습니다.

### Firebase CLI

```bash
npm install -g firebase-tools
firebase login
firebase use moa-club
```

규칙과 인덱스를 `moa-db`에 배포합니다. `firebase.json`이 데이터베이스 ID를 `moa-db`로 지정하므로, 기본 `(default)` 데이터베이스에 배포하지 않습니다.

```bash
firebase deploy --only firestore,storage
```

규칙만 올릴 때는 아래처럼 나눕니다.

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:moa-db:rules
firebase deploy --only storage
```

CLI 버전에 따라 이름 있는 데이터베이스 타깃 표기가 다를 수 있습니다. 배포 전에 `firebase deploy --only firestore --dry-run`으로 대상 데이터베이스가 `moa-db`인지 확인합니다.

Authentication에서 이메일/비밀번호와 Google 로그인이 켜져 있어야 합니다. `firebase.json`의 `auth.providers`가 그 구성을 적고 있습니다. Google 제공자의 지원 이메일은 그 파일에 있습니다.

앱은 시작 시 다음을 수행합니다.

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `EnvConfig.load()`
3. `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
4. `GoogleSignIn.instance.initialize()` (실패해도 앱은 계속 실행)
5. `FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'moa-db')`
6. `FirebaseStorage.instance`
7. 로그인된 uid가 있으면 `ClubGateway.launchFor`로 첫 화면을 고름

콘솔에서 데이터를 볼 때도 데이터베이스 선택기를 `moa-db`로 바꿉니다. `(default)`에 쓴 문서는 앱이 읽지 않습니다.

## 데이터 모델

시간은 Firestore `timestamp`입니다. 모임 시작·종료·회비 마감은 화면의 한국 시각 벽시계를 `kstWallToInstant`로 UTC 순간에 바꿔 저장하고, 읽을 때는 `toKst`로 되돌립니다. `createdAt`, `requestedAt`, `expiresAt`은 서버 타임스탬프 또는 `Timestamp` 그대로입니다.

### `users/{uid}`

본인만 읽고 생성·수정·삭제할 수 있습니다. 목록 조회는 막혀 있습니다.

| 필드 | 규칙 |
| --- | --- |
| `name` | 필수 문자열, 1–30자 |
| `email` | 필수 문자열, 120자 이하 |
| `activityAlerts` | 필수 bool |
| `createdAt` | 필수 timestamp. 수정 시 기존 값과 같아야 함 |
| `nickname` | 생략 가능. 있으면 1–30자 |
| `primaryClubId` | 생략 가능. 있으면 1–128자. 앱을 열 때 먼저 보여줄 동아리 |

그 외 필드는 규칙이 거부합니다. 가입 직후 `FirebaseClubService.ensureUser`가 문서가 없을 때만 생성합니다.

### `users/{uid}/memberships/{clubId}`

사용자 쪽 멤버십 사본입니다. 본인만 목록을 봅니다. 생성·수정은 본인 또는 해당 동아리 `ownerId`이고, 삭제는 본인 또는 오너입니다.

| 필드 | 값 |
| --- | --- |
| `clubId` | 경로의 `clubId`와 같아야 함 |
| `role` | `owner` 또는 `member` |
| `status` | `active` 또는 `pending` |

`ClubAccess`와 화면은 `admin`도 다룹니다. 현재 규칙의 `isValidMirror`는 `admin`을 허용하지 않습니다. 역할을 관리자로 바꾸는 쓰기는 규칙을 먼저 넓히지 않으면 거부됩니다.

### `clubs/{clubId}`

로그인한 사용자는 단건 조회만 할 수 있습니다. 목록 조회와 삭제는 거부됩니다.

| 필드 | 값 |
| --- | --- |
| `name` | 1–40자 |
| `tagline` | 80자 이하 |
| `category` | `동아리`, `학회`, `스터디`, `운동 · 취미`, `기타` (`ClubOptions.categories`) |
| `joinPolicy` | `approval` 또는 `open` (`ClubOptions.approval`, `ClubOptions.open`) |
| `ownerId`, `ownerName` | 생성 시 `ownerId`는 현재 uid. 이후 수정해도 `ownerId`와 `createdAt`은 유지 |
| `memberCount` | 0 이상 정수. 생성 시 1 |
| `balance`, `duesPaidCount`, `duesTotalCount` | 정수 |
| `duesMonthLabel` | 문자열 |
| `feeAmount` | 생략 가능한 정수 |
| `imageUrl` | 생략 가능. 700,000자 미만. Storage 다운로드 URL을 넣음 |
| `bankName`, `bankAccount`, `accountHolder` | 생략 가능한 문자열 |
| `inviteCode` | 생략 가능한 문자열 |
| `inviteExpiresAt` | 생략 가능한 timestamp |
| `createdAt` | timestamp |

수정은 오너이거나, 활동 멤버가 `memberCount`만 `+1` 또는 `-1` 하는 경우입니다. 오너가 아닌 멤버의 `-1`은 본인이 오너가 아닐 때만 허용됩니다.

### `clubs/{clubId}/members/{uid}`

| 필드 | 값 |
| --- | --- |
| `userId` | 경로 uid와 같아야 함 |
| `userName` | 30자 이하 |
| `role` | `owner` 또는 `member` |
| `status` | `active` 또는 `pending` |
| `feeReported` | bool |
| `requestedAt` | timestamp |
| `depositName` | 생략 가능. 문자열 또는 null |

조회는 본인, 오너, 활동 멤버입니다. 목록은 오너 또는 활동 멤버입니다.

생성은 본인만 가능하고 다음 중 하나여야 합니다.

- 오너 문서: `role == owner`, `status == active`, 요청자가 클럽 `ownerId`
- 승인 가입: `role == member`, `status == pending`, 클럽 `joinPolicy == approval`
- 즉시 가입: `role == member`, `status == active`, 클럽 `joinPolicy == open`

수정은 오너만 할 수 있고 `userId`는 바뀌면 안 됩니다. 삭제는 오너가 다른 멤버를 지우거나, 오너가 아닌 본인이 `active`/`pending` 멤버십을 지울 때 허용됩니다. 오너 역할 문서는 본인이 지우지 못합니다.

### `clubs/{clubId}/notices/{id}`

오너와 활동 멤버가 읽습니다. 클럽 `members`에 문서가 있는 사용자가 생성할 수 있습니다.

| 필드 | 값 |
| --- | --- |
| `title` | 1–80자 |
| `body` | 200자 이하 |
| `kind` | `join`, `dues`, `event`, `info` |
| `unread` | bool |
| `actorId` | 반드시 현재 uid |
| `createdAt` | timestamp |

수정은 `unread`를 `false`로 바꾸는 것만 허용합니다. 삭제는 없습니다. `markNoticesRead`가 이 수정에 해당합니다.

### `clubs/{clubId}/events/{id}`

오너 또는 활동 멤버가 읽습니다. 생성·수정·삭제는 `isStaff`입니다. 오너이거나, 멤버 문서의 `status == active`이고 `role`이 `owner` 또는 `admin`이면 스태프입니다.

필수 필드: `title`(1–80), `badge`, `description`, `schedule`, `artKicker`, `artTitle`, `place`, `supplies`, `status`(`예정` / `진행 중` / `완료`), `attendanceOpen`, `attendeeIds`, `attendeeInitials`, `attendeeSummary`, `checkedInCount`, `feePaidCount`.

선택 필드: `startsAt`, `endsAt`, `feeAmount`, `feeDueAt`, `imageUrl`(700,000자 미만).

`saveMeeting`은 문서 id가 비어 있으면 새 문서를 만들고, 이미지가 있으면 `clubs/{clubId}/events/{eventId}`에 올린 뒤 `imageUrl`만 다시 갱신합니다. `status == 진행 중`이면 `attendanceOpen`을 true로 저장합니다.

### `clubs/{clubId}/activities/{id}`

오너와 활동 멤버가 읽기만 할 수 있습니다. 클라이언트 쓰기는 전부 거부됩니다.

### `inviteCodes/{code}`

문서 ID가 초대 코드입니다. 코드는 `generateInviteCode`가 만드는 6자이고, 알파벳은 혼동 문자를 뺀 `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`입니다.

| 필드 | 값 |
| --- | --- |
| `clubId` | 문자열 |
| `ownerId` | 현재 uid와 같고, 그 uid가 해당 클럽 오너 |
| `expiresAt` | timestamp. 앱은 30일 뒤로 넣음 |

로그인한 사용자는 코드로 단건 조회만 할 수 있습니다. 생성 후 수정·삭제는 규칙상 거부됩니다. 동아리 생성 시 클럽 문서와 멤버 문서를 만든 다음 이 컬렉션에 코드를 씁니다.

### Storage

`storage.rules`는 로그인한 사용자의 이미지 업로드만 허용합니다. 5MB 미만이고 `contentType`이 `image/`로 시작해야 합니다.

| 경로 | 앱에서의 용도 |
| --- | --- |
| `clubs/{clubId}/cover` | 동아리 대표 이미지 |
| `clubs/{clubId}/events/{eventId}` | 모임 배너 |

읽기도 로그인 사용자만 가능합니다. 다운로드 URL은 클럽·모임 문서의 `imageUrl`에 저장합니다. `moaImage`는 `data:image`로 시작하면 base64로 그리고, 그 외에는 네트워크 이미지로 그립니다.

## 권한과 앱 동작

역할 상수는 `ClubAccess`에 있습니다.

| 역할 | 값 | 화면 라벨 | 설정 진입 |
| --- | --- | --- | --- |
| 회장 | `owner` | 회장 | 가능 |
| 관리자 | `admin` | 관리자 | 가능 |
| 일반 | `member` | 일반 | 불가 |

`ClubAccess.rank`는 회장 0, 관리자 1, 그 외 2입니다. 멤버 목록 정렬에 씁니다.

`launchFor`가 고르는 첫 화면은 다음 순서입니다.

1. 사용자 문서가 없거나 `name`이 비어 있으면 `/signup` (`SignupMode.complete`)
2. `status == active`인 멤버십이 있으면 `/home`. `primaryClubId`가 그 목록에 있으면 그 동아리, 없으면 첫 활동 동아리
3. `pending`만 있으면 `/clubs/join/pending`
4. 그 외에는 `/start` (동아리 없음)

같은 분기를 순수 함수로 쓴 것이 `resolveSession`입니다.

가입 정책이 `open`이면 `joinImmediately`가 멤버와 미러를 `active`로 만들고 `memberCount`를 1 올립니다. `approval`이면 `requestJoin`이 `pending`과 `depositName`, `feeReported`를 저장합니다. 오너는 `approveJoins` / `rejectJoins`로 처리합니다.

회장 위임(`transferOwnership`)은 대상이 활동 멤버일 때만 동작합니다. 클럽 `ownerId`를 바꾸고, 이전 회장 역할을 `admin`으로, 대상 역할을 `owner`로 바꿉니다. 계정 삭제와 동아리 삭제는 회장 멤버십이 남아 있으면 `먼저 회장을 넘겨야 해요.`로 멈춥니다.

탈퇴 전 `ensureRecentLogin`은 ID 토큰의 `authTime`이 5분 이내인지 확인합니다. 아니면 `requires-recent-login`입니다.

비밀번호 규칙은 `AuthValidators`와 Auth 오류 문구가 같습니다. 8자 이상, 영문 1자, 숫자 1자입니다.

## 보안 규칙을 바꿀 때

규칙 파일과 클라이언트 쓰기가 어긋나면 앱은 `permission-denied`가 납니다. 필드를 추가하면 `isValidUser`, `isValidClub`, `isValidMember`, `isValidNotice`, `isValidEvent`, `isValidInvite`의 `hasOnly` 목록에 먼저 넣습니다. 타입과 길이 검사도 같은 함수에 둡니다.

아래 쓰기는 현재 규칙과 다릅니다. 기능을 고칠 때 규칙과 서비스를 같이 맞춥니다.

- 멤버·미러 `role`에 `admin`을 넣음 (`setMemberRole`, `transferOwnership`)
- 가입 승인 시 `joinedAt`을 멤버 문서에 씀 (`approveJoins`)
- 회장 변경·가입 승인 알림에 `actorId`가 없음
- 초대 코드 재발급이 이전 `inviteCodes` 문서를 지우려고 함. 규칙의 수정·삭제는 거부
- 재발급 시 새 초대 문서에 `ownerId`가 없음. `isValidInvite`는 `ownerId`를 요구
- `deleteClub`이 클럽 문서를 삭제. 클럽 `delete`는 거부
- 공지 `kind`에 화면 일부는 `settlement`를 기대하지만, 규칙의 `kind`는 `join`, `dues`, `event`, `info`

배포 후 콘솔 규칙 플레이그라운드에서 오너 생성, 즉시 가입, 승인 가입, 다른 사용자 클럽 목록 조회가 거부되는지를 확인합니다.

## 공용 컴포넌트

새 UI는 `AppColors`만 쓰고, 버튼·입력·헤더는 `lib/widgets/moa_widgets.dart`를 재사용합니다. 동아리 맥락의 카드와 바텀시트는 `club_chrome.dart`, `club_sheets.dart`에 있습니다.

### `AppColors` (`lib/core/theme/app_colors.dart`)

`abstract final class`입니다. 인스턴스를 만들지 않고 상수만 참조합니다.

| 상수 | 용도 |
| --- | --- |
| `background` `#F7F8F3` | 화면 배경. `AppTheme`의 스캐폴드 |
| `surface` `#F9FAF6` | 시트, 입력 배경에 가까운 면 |
| `primary` `#246946` | 주요 버튼, 선택, 브랜드 |
| `ink` `#202B25` | 본문 |
| `muted` `#879087` | 보조 설명 |
| `label` `#6F7A6B` | 필드 라벨 |
| `line`, `lineStrong` | 입력·아웃라인 테두리 |
| `chip` `#E9ECE5` | 카드 테두리 |
| `caper` `#E3EFB9` | 로고 아이콘, 회장 칩 글자 |
| `bud` | 힌트, 비활성 별 |
| `white` | 카드, 버튼 전경 |
| `unreadDot` | 알림 점 |
| `copper`, `peach` | 회비·대기 강조 |
| `danger`, `dangerSolid`, `dangerBg`, `dangerBorder` | 삭제·탈퇴. 확정 버튼은 `dangerSolid` |
| `art`, `artInk`, `artMuted` | 모임 배너 기본 배경과 글자 |
| `live` | 출석 진행 점 |
| `soft` | 아이콘 배경, 관리자 칩 |
| `taskBlue`, `taskCream`, `taskGreen` | 할 일·알림 종류별 아이콘 배경 |
| `dim` | 바텀시트 배리어 |
| `roleGray`, `roleGrayBg` | 일반 역할 칩 |

`AppTheme.light`는 Material 3, 시드 `primary`, 스플래시 없음, 글자색 `ink`입니다. `useBrandFont: true`이면 `GoogleFonts.notoSansKr`를 적용합니다. `MyApp`의 기본값은 true입니다.

### `moa_widgets.dart`

인증·가입처럼 동아리 데이터가 없는 화면에서 씁니다.

`MoaMark`  
초록 라운드 사각에 `Icons.emergency`. `size` 기본 46. 모서리 반지름은 `size * 0.28`, 아이콘은 `size * 0.55`.

`MoaLogo`  
`MoaMark`와 텍스트 `모아`. 글자 크기는 `size * 0.56`, 굵기 900.

`MoaPrimaryButton`  
높이 46, 가로 전체. `label`, `onPressed`, `busy`, `icon`. `busy`이면 버튼을 비활성화하고 18px 인디케이터를 보여 줍니다. `onPressed`가 null이면 비활성입니다.

`MoaOutlineButton`  
같은 높이의 흰 아웃라인 버튼. `label`, `onPressed`, `icon`.

`MoaField`  
라벨, `TextEditingController`, `hint`, `obscure`, `keyboardType`, `helper`, `helperColor`. 포커스 테두리는 `primary`, 기본 테두리는 `line`, 힌트는 `bud`.

`MoaPageHeader`  
높이 56. 가운데 `title`. 뒤로 가기는 `onBack`이 없으면 `Navigator.maybePop`. 오른쪽은 너비 48의 `trailing`.

`MoaStepper`  
가입 2단계 표시. `active`가 1 이상이면 첫 막대, 2 이상이면 둘째 막대가 `primary`.

`showMoaSheet(context, title:, body:)`  
제목과 본문만 있는 정보 시트. 결과는 `Future<void>`.

### `moa_bottom_nav.dart`

`MoaTab`  
`home`, `reservation`, `attendance`, `settlement`, `myPage`. 라벨은 `홈`, `예약`, `출석`, `정산`, `마이페이지`.

`MoaBottomNav`  
`selected`와 `onSelected`. 출석 탭은 가운데로 떠 있는 QR 원이고, 나머지 선택 탭은 아이콘 뒤 캡슐을 그립니다. 탭 키는 `nav-${tab.name}`입니다. `onSelected`가 null이면 탭이 동작하지 않습니다.

### `club_chrome.dart`

`moaImage(source)`  
`data:image`면 콤마 뒤 base64를 `Image.memory`로 그립니다. 디코드에 실패하거나 그 외 문자열이면 `Image.network`입니다. `width`, `height`, `fit`, `errorBuilder`를 넘길 수 있습니다.

`HomeIcon`  
`HomeIcon('bell')`은 `assets/home/bell.svg`입니다. 이름에 확장자를 붙이지 않습니다. 있는 파일은 `activity_in`, `activity_out`, `art_star`, `asterisk`, `bell`, `chevron`, `chevron_down`, `chevron_small`, `dues`, `gear`, `ledger`, `qr`, `settle`, `task_dues`, `task_join`, `task_settle`입니다.

`ClubMark`  
`name`, `imageUrl`, `size` 기본 43, `radius` 기본 15. 이미지가 없거나 실패하면 이름의 첫 룬과 마침표를 Lora 이탤릭으로 그립니다. 빈 이름은 `모`.

`ClubTopBar`  
`club`, `hasUnread`, `showSettings`, `onClub`, `onNotices`, `onSettings`. 왼쪽은 마크·태그라인·이름·아래 화살표이고 탭하면 `onClub`입니다. 종 아이콘은 `onNotices`이고 `hasUnread`일 때 점을 찍습니다. `showSettings`일 때만 톱니바퀴를 보여 줍니다. 회장·관리자 여부는 호출부가 `ClubAccess.showsSettings`로 결정합니다.

`MoaEmptyCard`  
`title`, `body`, `icon`. 흰 카드와 42px 아이콘 박스.

`SectionTitle`  
`title`, 선택 `action` 문자열, `onAction`. 액션이 있으면 작은 셰브론과 함께 탭 영역이 생깁니다.

`meetingKindLabels`  
`정기 출사`, `뒤풀이`, `회의`, `기타`.

`MeetingArtBanner`  
`event`, `clubName`. 높이 119. `imageUrl`이 있으면 사진을 깔고 왼쪽이 어두운 그라데이션을 올립니다. 없으면 `art_star`를 기울여 놓습니다. 키커는 `meetingClubLabel(clubName)`이고, 큰 제목은 `artTitle`이 비어 있으면 `title`입니다.

`EventCard`  
배너 아래 배지, 제목, `scheduleLine`, 참석 이니셜 최대 3개, `attendeeSummary`. 시작일이 오늘(KST)이면 배지는 `오늘 · {동아리} 모임`입니다. `attendanceOpen`이면 `출석 진행 중`을 보여 줍니다.

`QuickActions`  
회비 관리, QR 출석, N차 정산, 회계 장부. 현재 각 칸에는 탭 콜백이 없습니다.

`TaskCard`  
`HomeTask`와 `onTap`. `kind`가 `dues`면 크림색과 `task_dues`, `settlement`면 녹색과 `task_settle`, 그 외는 파란색과 `task_join`입니다. `count`가 있으면 제목 옆에 붙고, 회비는 `copper`, 그 외는 `primary`입니다.

`ActivityRow`  
`ActivityItem`. `amount >= 0`이면 수입으로 `+`, 아니면 `−`와 `activity_out`. 금액은 `formatWon`.

`avatarColor(index)`  
네 가지 파스텔을 순환합니다. 참석 이니셜과 `MemberAvatar`가 같이 씁니다.

`RoleChip`  
`ClubAccess` 라벨. 회장은 잉크 배경과 왕관 아이콘, 관리자는 `soft`, 일반은 회색입니다.

`MemberAvatar`  
`initial`, `index`, `size` 기본 36.

`showMoaError(context, error)`  
마운트되어 있으면 `Bad state:`  접두어를 지운 문자열로 스낵바를 띄웁니다. 인증 실패 문구는 이 함수 전에 `authErrorMessage`로 바꿉니다.

### `club_sheets.dart`

모두 모달 바텀시트입니다. 배경은 `AppColors.background`, 배리어는 `dim`, 위 모서리는 25입니다. bool을 반환하는 시트는 닫히거나 취소되면 `false`입니다.

| 함수 | 반환 | 동작 |
| --- | --- | --- |
| `showNoticeSheet(context, notices)` | `Future<void>` | `새로운 소식`. 비어 있으면 `MoaEmptyCard`. `kind`가 `join` / `dues` / `settlement` / 그 외로 아이콘이 갈립니다. `unread`면 `새 알림` 배지. 본문이 비어 있으면 `formatNoticeTime` |
| `showClubSwitcher(...)` | `Future<void>` | `options`, `onPrimary`, `onOpen`, `onCreate`, `onJoin`. 대기 중 행은 별이 없고 `입금 확인 중`. 별은 대표 동아리(`primary`)를 바꿉니다. `onPrimary`가 성공하면 시트 안의 대표 표시만 갱신합니다. 행을 누르면 시트를 닫고 `onOpen` |
| `showDeleteClubSheet(context, club)` | `Future<bool>` | 동아리 이름을 그대로 입력해야 삭제 버튼이 켜집니다. 구성원 수, 회비·장부, 정산·출석이 지워진다고 안내합니다 |
| `showTransferSheet(...)` | `Future<bool>` | `targetName`, `targetRole`, `myName`. 대상이 회장이 되고 현재 사용자는 관리자가 된다고 안내합니다 |
| `showRemoveMemberSheet(context, member:)` | `Future<bool>` | `unpaidDues`가 null이면 `없음`, 아니면 `N건`. `unsettledAmount`가 null이면 `없음`, 아니면 `formatWon` |
| `showLeaveAccountSheet(context, ownedLine:, joinedLine:)` | `Future<bool>` | 계정 탈퇴. 문구는 `ProfileData.ownedLine`, `joinedLine`을 그대로 넣습니다 |

## 같이 쓰는 모델과 헬퍼

화면 사이에서 넘기는 인자는 `lib/models/app_user.dart`에 있습니다.

| 타입 | 용도 |
| --- | --- |
| `SignupMode` | `create` 또는 `complete` |
| `SignupDoneArgs` | 가입 완료 화면의 이름·이메일 |
| `HomeArgs` | 홈의 `clubId` |
| `ClubArgs` | 마이페이지, 모임 목록, 대기, 설정 등 `clubId`만 필요한 화면 |
| `MeetingArgs` | `clubId`, 선택 `eventId`, `role` 기본 `member`, `selectedIds` |

`lib/models/club.dart`의 화면용 묶음은 다음과 같습니다.

- `Club.requiresApproval`는 `joinPolicy == approval`입니다. `joinPolicyLabel`은 `승인 후 가입` 또는 `바로 가입`입니다.
- `ClubEvent.scheduleLine`은 장소에 일정이 없으면 `일정  |  장소`를 붙입니다. `attendeeCount`는 `attendeeIds`가 비어 있으면 이니셜 개수입니다.
- `HomeData.hasUnread`는 공지 중 `unread`가 하나라도 있는지입니다.
- `ProfileData.visibleClubs`는 대기가 아닌 동아리를 대표 우선, 그다음 이름순으로 정렬합니다. `ownedLine` / `joinedLine`은 탈퇴 시트 문구입니다.
- `ImagePayload`는 `bytes`와 `contentType`입니다. Storage 업로드 직전에만 사용합니다.

`lib/core/format.dart`는 화면 문자열을 한곳으로 모읍니다. 금액은 `formatWon`, 숫자만 뽑으면 `parseWon`, 알림 시각은 `formatNoticeTime`, 모임 구간은 `formatMeetingWhen`, 초대 만료는 `formatInviteUntil`입니다. 날짜 비교는 `isSameDay`입니다.

`lib/core/kst.dart`의 `kstNow()`는 기기의 로컬 시간대가 아니라 UTC에 9시간을 더한 벽시계입니다. 모임 시각을 저장할 때는 `kstWallToInstant`를 씁니다.

`lib/core/meeting_filter.dart`의 `MeetingFilter`는 `upcoming`, `past`, `all`입니다. `attendanceOpen`인 모임은 과거로 보지 않습니다. 상태가 `past`, `done`, `완료`이거나 시작일이 오늘보다 이전이면 과거입니다. `uniqueMeetings`는 제목과 분 단위 시작 시각이 같은 항목을 하나면 남깁니다.

`BaseViewModel`은 `isLoading`, `error`, `setLoading`, `setError`만 제공합니다. 로그인·가입 뷰모델이 이를 상속합니다.

## 경로

| 상수 | 경로 | 인자 |
| --- | --- | --- |
| `login` | `/login` | 없음 |
| `signup` | `/signup` | `SignupMode` 또는 생략 시 `create` |
| `signupDone` | `/signup-done` | `SignupDoneArgs` |
| `noClub` | `/start` | 없음 |
| `createClub` | `/clubs/create` | 없음 |
| `invite` | `/clubs/invite` | `CreatedClub` |
| `join` | `/clubs/join` | 없음 |
| `joinRequest` | `/clubs/join/request` | `Club` |
| `joinPending` | `/clubs/join/pending` | `ClubArgs` |
| `home` | `/home` | `HomeArgs` |
| `myPage` | `/my-page` | `ClubArgs` |
| `meetings` | `/home/meetings` | `ClubArgs` |
| `meetingDetail` | `/home/meetings/detail` | `MeetingArgs` |
| `meetingEdit` | `/home/meetings/edit` | `MeetingArgs` |
| `meetingAttendees` | `/home/meetings/attendees` | `MeetingArgs` |
| `clubSettings` | `/clubs/settings` | `ClubArgs` |
| `memberRoles` | `/clubs/members` | `ClubArgs` |
| `joinInbox` | `/clubs/join/inbox` | `ClubArgs` |
| `scan` | `/clubs/join/scan` | 없음. QR 스캔 |

로그인 뒤 스택을 교체할 때는 `openLaunch(context, deps)`를 호출합니다. 이 함수가 `launchFor` 결과로 `pushNamedAndRemoveUntil`을 실행합니다.

## 작업할 때

- 색과 간격을 화면에 숫자로 새로 넣기보다 `AppColors`와 기존 위젯 기본값을 맞춥니다.
- Firestore 필드명과 문자열 역할 값(`owner`, `admin`, `member`, `active`, `pending`, `approval`, `open`)은 모델·규칙·서비스가 같은 리터럴을 씁니다. 한곳만 바꾸지 않습니다.
- 모임 시각은 KST 벽시계로 다룬 뒤 저장 직전에 `kstWallToInstant`를 적용합니다.
- 이미지를 문서는 URL로만 저장합니다. 바이트는 `ImagePayload`로 서비스에 넘깁니다.
- `.env`, 서비스 계정 JSON, `.firebase/`는 커밋하지 않습니다.
