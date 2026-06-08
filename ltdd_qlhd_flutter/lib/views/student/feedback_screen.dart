import 'package:flutter/material.dart';

import '../../controllers/feedback_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_back_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final FeedbackController _controller = FeedbackController();
  final TextEditingController _contentController = TextEditingController();

  String _selectedType = 'Lỗi hệ thống';

  @override
  void dispose() {
    _controller.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final result = await _controller.submitFeedback(
      type: _selectedType,
      content: _contentController.text,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: result.success ? const Color(0xFF2E7D32) : Colors.red,
      ),
    );

    if (result.success) {
      _contentController.clear();

      setState(() {
        _selectedType = 'Lỗi hệ thống';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  child: Column(
                    children: [
                      _buildIntroCard(),
                      const SizedBox(height: 16),
                      _buildFormCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, topPadding + 8, 18, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF00A8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Row(
        children: [
          AppBackButton(),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Góp ý',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.blueGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary(context).withOpacity(0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.rate_review_rounded, color: Colors.white, size: 34),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ý kiến của bạn giúp ITConnect tốt hơn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Bạn có thể gửi lỗi hệ thống, góp ý về hoạt động, điểm danh hoặc trải nghiệm sử dụng ứng dụng.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.divider(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Loại góp ý'),
          const SizedBox(height: 10),
          _typeDropdown(),
          const SizedBox(height: 18),
          _label('Nội dung góp ý'),
          const SizedBox(height: 10),
          _contentInput(),
          const SizedBox(height: 22),
          _submitButton(),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.title(context),
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _typeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.iconBox(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          dropdownColor: AppColors.card(context),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primary(context),
          ),
          items: _controller.feedbackTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(
                type,
                style: TextStyle(
                  color: AppColors.title(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }).toList(),
          onChanged: _controller.isSubmitting
              ? null
              : (value) {
                  if (value == null) return;

                  setState(() {
                    _selectedType = value;
                  });
                },
        ),
      ),
    );
  }

  Widget _contentInput() {
    return TextField(
      controller: _contentController,
      minLines: 6,
      maxLines: 8,
      enabled: !_controller.isSubmitting,
      cursorColor: AppColors.primary(context),
      style: TextStyle(
        color: AppColors.title(context),
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
      decoration: InputDecoration(
        hintText: 'Nhập nội dung góp ý của bạn...',
        hintStyle: TextStyle(
          color: AppColors.subtitle(context),
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.iconBox(context),
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.divider(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.divider(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.primary(context), width: 1.4),
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _controller.isSubmitting ? null : _submitFeedback,
        icon: _controller.isSubmitting
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.3,
                ),
              )
            : const Icon(Icons.send_rounded),
        label: Text(
          _controller.isSubmitting ? 'Đang gửi...' : 'Gửi góp ý',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary(context),
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.muted(context),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
