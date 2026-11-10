import 'package:flutter/material.dart';

/// 장소 찾기부터 결제 완료까지 화면 사이에 넘기는 값입니다.
/// 서버에 저장하지 않고, 앱을 다시 열면 사라집니다.
class PlaceFlowArgs {
  const PlaceFlowArgs({
    required this.clubId,
    this.placeId,
    this.draft,
    this.reservationId,
    this.reservationIds = const [],
    this.usedTab = false,
  });

  final String clubId;
  final String? placeId;
  final PlaceDraft? draft;
  final String? reservationId;
  final List<String> reservationIds;
  final bool usedTab;
}

class PlaceDraft {
  const PlaceDraft({
    required this.placeId,
    required this.dateIndex,
    required this.time,
    required this.headcount,
    required this.meeting,
    required this.note,
  });

  final String placeId;
  final int dateIndex;
  final String time;
  final int headcount;
  final String meeting;
  final String note;

  int get deposit => headcount * placeDepositPerPerson;

  String get whenLabel => '${placeDates[dateIndex].label} $time';

  String get meetingName => placeMeetingTitle(meeting);

  String get noteLabel => note.trim().isEmpty ? '입력한 요청사항 없음' : note.trim();
}

enum PlaceCategory { restaurant, study, room, practice }

class PlaceMenu {
  const PlaceMenu({
    required this.name,
    required this.price,
    required this.description,
    this.sample = false,
  });

  final String name;
  final int price;
  final String description;
  final bool sample;
}

class PlaceOrderLine {
  const PlaceOrderLine(this.name, this.unitPrice, this.quantity);

  final String name;
  final int unitPrice;
  final int quantity;

  int get amount => unitPrice * quantity;
}

class DummyPlace {
  const DummyPlace({
    required this.id,
    required this.pin,
    required this.name,
    required this.category,
    required this.cuisine,
    required this.km,
    required this.area,
    required this.capacity,
    required this.reviews,
    required this.photos,
    required this.menus,
    required this.address,
    required this.phone,
    this.menuPhoto,
    this.partner = false,
  });

  final String id;
  final int pin;
  final String name;
  final PlaceCategory category;
  final String cuisine;
  final double km;
  final String area;
  final int capacity;
  final int reviews;
  final bool partner;
  final List<String> photos;
  final String? menuPhoto;
  final List<PlaceMenu> menus;
  final String address;
  final String phone;

  String get dishImage => menuPhoto ?? photos.first;

  String get storeImage => menuPhoto == null ? photos[1] : photos.first;

  String get distance => '${km.toStringAsFixed(1)}km';

  String get meta => '$cuisine · $distance · $area';

  String get reserveMeta => '$cuisine · $distance · 최대 $capacity명';
}

enum ReservationKind { upcoming, used }

enum ReservationBadge { confirmed, pending, unpaid }

class DummyReservation {
  const DummyReservation({
    required this.id,
    required this.placeName,
    required this.meeting,
    required this.when,
    required this.headcount,
    required this.kind,
    required this.badge,
    required this.deposit,
    this.countdown,
    this.total = 0,
    this.lines = const [],
  });

  final String id;
  final String placeName;
  final String meeting;
  final String when;
  final int headcount;
  final ReservationKind kind;
  final ReservationBadge badge;
  final int deposit;
  final String? countdown;
  final int total;
  final List<PlaceOrderLine> lines;

  int get balance => total - deposit;

  String get party => '$when · $headcount명';
}

class PlaceDate {
  const PlaceDate(this.weekday, this.day, this.label);

  final String weekday;
  final String day;
  final String label;
}

class PlaceTime {
  const PlaceTime(this.label, {this.open = true});

  final String label;
  final bool open;
}

const placeDepositPerPerson = 5000;

const placeDates = [
  PlaceDate('금', '11.6', '11.6 (금)'),
  PlaceDate('토', '11.7', '11.7 (토)'),
  PlaceDate('일', '11.8', '11.8 (일)'),
  PlaceDate('월', '11.9', '11.9 (월)'),
  PlaceDate('화', '11.10', '11.10 (화)'),
];

const placeTimes = [
  PlaceTime('17:00'),
  PlaceTime('17:30'),
  PlaceTime('18:00', open: false),
  PlaceTime('18:30'),
  PlaceTime('19:00'),
  PlaceTime('19:30'),
  PlaceTime('20:00'),
  PlaceTime('20:30', open: false),
];

const placeMeetings = ['11.7 (토) 11월 출사 뒤풀이', '11.14 (토) 11월 운영진 모임'];

const placeTerms = [
  '[필수] 전자금융거래 이용약관',
  '[필수] 개인정보 수집·이용 동의',
  '[필수] 개인정보 제3자 제공 동의',
];

const placeMapAsset = 'assets/places/map.png';

const placeCardName = '신한카드 · 4821';
const placeCardDetail = '신용·체크카드 · 일시불';
const placeCardPaid = '신한카드 · 4821 / 일시불';
const placePaidAt = '2026.11.8 10:24';

const placeCategories = [
  (PlaceCategory.restaurant, '음식점', Icons.restaurant),
  (PlaceCategory.study, '스터디룸', Icons.menu_book_outlined),
  (PlaceCategory.room, '회의실', Icons.meeting_room_outlined),
  (PlaceCategory.practice, '연습실', Icons.music_note),
];

const dummyPlaces = [
  DummyPlace(
    id: 'yeonnam',
    pin: 1,
    name: '연남 소반',
    category: PlaceCategory.restaurant,
    cuisine: '한식 주점',
    km: 0.4,
    area: '마포구 연남동',
    capacity: 40,
    reviews: 218,
    partner: true,
    photos: [
      'assets/places/yeonnam-1.png',
      'assets/places/yeonnam-2.png',
      'assets/places/yeonnam-3.png',
    ],
    menuPhoto: 'assets/places/yeonnam-menu.png',
    address: '서울 마포구 연남로 12',
    phone: '02-332-1400',
    menus: [
      PlaceMenu(
        name: '소고기 육전',
        price: 24000,
        description: '노릇하게 부친 육전과 산뜻한 파채',
        sample: true,
      ),
      PlaceMenu(
        name: '해물파전',
        price: 22000,
        description: '여럿이 나누기 좋은 한 접시',
        sample: true,
      ),
    ],
  ),
  DummyPlace(
    id: 'hwaro',
    pin: 2,
    name: '화로정 홍대점',
    category: PlaceCategory.restaurant,
    cuisine: '고깃집',
    km: 0.7,
    area: '마포구 서교동',
    capacity: 30,
    reviews: 145,
    photos: [
      'assets/places/hwaro-1.png',
      'assets/places/hwaro-2.png',
      'assets/places/hwaro-3.png',
    ],
    address: '서울 마포구 와우산로 21',
    phone: '02-333-2210',
    menus: [
      PlaceMenu(
        name: '모둠 구이',
        price: 32000,
        description: '여럿이 나눠 먹는 한 상',
        sample: true,
      ),
      PlaceMenu(
        name: '된장찌개',
        price: 8000,
        description: '식사와 함께 내는 찌개',
        sample: true,
      ),
    ],
  ),
  DummyPlace(
    id: 'morak',
    pin: 3,
    name: '모락 키친',
    category: PlaceCategory.restaurant,
    cuisine: '이탈리안',
    km: 1.1,
    area: '마포구 동교동',
    capacity: 24,
    reviews: 92,
    photos: [
      'assets/places/morak-1.png',
      'assets/places/morak-2.png',
      'assets/places/morak-3.png',
    ],
    address: '서울 마포구 양화로 18',
    phone: '02-336-0911',
    menus: [
      PlaceMenu(
        name: '파스타 세트',
        price: 18000,
        description: '단체 코스로 내는 예시 메뉴',
        sample: true,
      ),
      PlaceMenu(
        name: '피자',
        price: 26000,
        description: '테이블에서 나눠 먹는 한 판',
        sample: true,
      ),
    ],
  ),
];

const dummyReservations = [
  DummyReservation(
    id: 'up-yeonnam',
    placeName: '연남 소반',
    meeting: '11월 출사 뒤풀이',
    when: '11.7 (토) 19:00',
    headcount: 24,
    kind: ReservationKind.upcoming,
    badge: ReservationBadge.confirmed,
    countdown: 'D-5',
    deposit: 120000,
  ),
  DummyReservation(
    id: 'up-seogyo',
    placeName: '서교 다이닝',
    meeting: '11월 운영진 모임',
    when: '11.14 (토) 18:30',
    headcount: 12,
    kind: ReservationKind.upcoming,
    badge: ReservationBadge.pending,
    deposit: 60000,
  ),
  DummyReservation(
    id: 'used-yeonnam',
    placeName: '연남 소반',
    meeting: '11월 출사 뒤풀이',
    when: '11.7 (토) 19:00',
    headcount: 24,
    kind: ReservationKind.used,
    badge: ReservationBadge.unpaid,
    deposit: 120000,
    total: 720000,
    lines: [
      PlaceOrderLine('소고기 육전', 24000, 10),
      PlaceOrderLine('해물파전', 22000, 10),
      PlaceOrderLine('보쌈 수육', 38000, 5),
      PlaceOrderLine('음료 및 주류', 5000, 14),
    ],
  ),
  DummyReservation(
    id: 'used-mangwon',
    placeName: '망원 한상',
    meeting: '사진 동아리 운영진 모임',
    when: '11.6 (금) 18:30',
    headcount: 12,
    kind: ReservationKind.used,
    badge: ReservationBadge.unpaid,
    deposit: 60000,
    total: 240000,
    lines: [PlaceOrderLine('한상 정식', 18000, 10), PlaceOrderLine('음료', 5000, 12)],
  ),
];

DummyPlace placeById(String id) =>
    dummyPlaces.firstWhere((place) => place.id == id);

DummyReservation reservationById(String id) =>
    dummyReservations.firstWhere((item) => item.id == id);

List<DummyReservation> reservationsByIds(List<String> ids) {
  return [for (final id in ids) reservationById(id)];
}

List<DummyReservation> get upcomingReservations => dummyReservations
    .where((item) => item.kind == ReservationKind.upcoming)
    .toList();

List<DummyReservation> get usedReservations => dummyReservations
    .where((item) => item.kind == ReservationKind.used)
    .toList();

String placeMeetingTitle(String value) {
  final match = RegExp(r'^\d+\.\d+ \([^)]+\) ').firstMatch(value);
  if (match == null) return value;
  return value.substring(match.end);
}

String reservationBadgeLabel(ReservationBadge badge) {
  return switch (badge) {
    ReservationBadge.confirmed => '예약 확정',
    ReservationBadge.pending => '사장님 확인 중',
    ReservationBadge.unpaid => '미결제',
  };
}

int reservationDepositSum(List<DummyReservation> items) =>
    items.fold(0, (sum, item) => sum + item.deposit);

int reservationTotalSum(List<DummyReservation> items) =>
    items.fold(0, (sum, item) => sum + item.total);

int reservationBalanceSum(List<DummyReservation> items) =>
    items.fold(0, (sum, item) => sum + item.balance);
