import 'package:flutter/material.dart';
import 'package:flutter_proj/core/auth_error_message.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';
import 'package:image_picker/image_picker.dart';

class CreateClubScreen extends StatefulWidget {
  const CreateClubScreen({super.key, required this.deps});

  final MoaDependencies deps;

  @override
  State<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends State<CreateClubScreen> {
  final _name = TextEditingController();
  final _tagline = TextEditingController();
  final _fee = TextEditingController();
  String _category = ClubOptions.categories.first;
  String _policy = ClubOptions.approval;
  XFile? _image;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _fee.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _message = '동아리 이름을 입력해 주세요.');
      return;
    }
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      ImagePayload? image;
      if (_image != null) {
        image = ImagePayload(bytes: await _image!.readAsBytes(), contentType: 'image/jpeg');
      }
      final created = await widget.deps.clubs.createClub(
        ownerId: uid,
        ownerName: widget.deps.auth.currentDisplayName ?? '회장',
        name: _name.text,
        tagline: _tagline.text,
        category: _category,
        joinPolicy: _policy,
        feeAmount: parseWon(_fee.text),
        image: image,
      );
      if (!mounted) return;
      await Navigator.pushReplacementNamed(context, AppRoutes.invite, arguments: created);
    } catch (error) {
      setState(() => _message = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const MoaPageHeader(title: '새 동아리 만들기'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  const Text('대표 이미지 (선택)', style: TextStyle(fontSize: 13, color: AppColors.label, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: () async {
                          final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
                          if (file != null) setState(() => _image = file);
                        },
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: const Icon(Icons.add, color: AppColors.bud),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('사진 올리기\n대표 이미지는 회장만\n등록하고 바꿀 수 있어요', style: TextStyle(height: 1.4, color: AppColors.muted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  MoaField(label: '동아리 이름', controller: _name),
                  const SizedBox(height: 16),
                  MoaField(label: '한 줄 소개', controller: _tagline),
                  const SizedBox(height: 16),
                  const Text('동아리 종류', style: TextStyle(fontSize: 13, color: AppColors.label, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in ClubOptions.categories)
                        ChoiceChip(
                          label: Text(category),
                          selected: _category == category,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: _category == category ? AppColors.white : AppColors.ink),
                          onSelected: (_) => setState(() => _category = category),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('가입 방식', style: TextStyle(fontSize: 13, color: AppColors.label, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _choice(
                    selected: _policy == ClubOptions.approval,
                    title: '승인 후 가입',
                    body: '회장이 가입 신청과 입금을 확인한 뒤 승인해요. 가입비를 받는 동아리에 추천해요.',
                    onTap: () => setState(() => _policy = ClubOptions.approval),
                  ),
                  const SizedBox(height: 8),
                  _choice(
                    selected: _policy == ClubOptions.open,
                    title: '바로 가입',
                    body: '초대 코드만 있으면 누구나 바로 들어와요.',
                    onTap: () => setState(() => _policy = ClubOptions.open),
                  ),
                  const SizedBox(height: 16),
                  MoaField(label: '가입비 (선택)', controller: _fee, keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  const Text(
                    '동아리를 만든 사람이 회장이 돼요. 회장은 나중에 다른 구성원에게 넘길 수 있어요.',
                    style: TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(_message!, style: const TextStyle(color: AppColors.danger)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: MoaPrimaryButton(label: '동아리 만들기', busy: _busy, onPressed: _submit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice({
    required bool selected,
    required String title,
    required String body,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : AppColors.line, width: selected ? 1.4 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.primary : AppColors.bud),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
