import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../data/models/room_model.dart';

/// 결과 카드 위젯
/// 이미지로 저장하거나 공유할 수 있는 결과 카드
class ResultCard extends StatelessWidget {
  final RoomModel room;
  final String focusTime;

  const ResultCard({
    super.key,
    required this.room,
    required this.focusTime,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일');
    final today = dateFormat.format(DateTime.now());

    return Container(
      width: 350,
      padding: const EdgeInsets.all(AppConstants.kLargePadding),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppConstants.kLargeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 날짜
          Text(
            today,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: AppConstants.kLargePadding),
          
          // 완성된 식물 이미지
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: AppTheme.lightGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.forest,
              size: 100,
              color: AppTheme.primaryGreen,
            ),
          ),
          
          const SizedBox(height: AppConstants.kLargePadding),
          
          // 메인 메시지
          Text(
            '함께 $focusTime\n집중했어요!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppConstants.kLargePadding),
          
          // 참여자 목록
          Container(
            padding: const EdgeInsets.all(AppConstants.kDefaultPadding),
            decoration: BoxDecoration(
              color: AppTheme.backgroundWhite,
              borderRadius: BorderRadius.circular(AppConstants.kDefaultRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '함께한 친구들',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.kSmallPadding),
                Wrap(
                  spacing: AppConstants.kSmallPadding,
                  runSpacing: AppConstants.kSmallPadding,
                  children: room.participants.map((participant) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.dividerColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: AppTheme.primaryGreen,
                            child: Text(
                              participant.displayName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            participant.displayName,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppConstants.kLargePadding),
          
          // 하단 로고 및 브랜딩
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.eco,
                size: 20,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}