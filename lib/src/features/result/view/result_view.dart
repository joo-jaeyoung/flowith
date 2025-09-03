import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:io';
import 'result_card.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../data/repositories/room_repository.dart';

/// Result 화면 UI
/// 완료된 세션의 결과를 표시하고 공유 기능 제공
class ResultView extends ConsumerStatefulWidget {
  final String roomId;

  const ResultView({
    super.key,
    required this.roomId,
  });

  @override
  ConsumerState<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends ConsumerState<ResultView> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSaving = false;
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final roomStream = ref.watch(roomStreamProvider(widget.roomId));

    return roomStream.when(
      data: (room) {
        if (room == null) {
          // 룸이 삭제된 경우
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/home');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 집중 시간 계산 (분:초 형식)
        final focusTime = _formatDuration(room.setDurationSeconds);

        return Scaffold(
          backgroundColor: AppTheme.backgroundWhite,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.kDefaultPadding),
              child: Column(
                children: [
                  const SizedBox(height: AppConstants.kLargePadding),
                  
                  // 축하 메시지
                  Text(
                    '🎉 수고하셨어요!',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.kLargePadding),
                  
                  // 결과 카드 (캡처 대상)
                  RepaintBoundary(
                    key: _cardKey,
                    child: ResultCard(
                      room: room,
                      focusTime: focusTime,
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.kLargePadding),
                  
                  // 액션 버튼들
                  Row(
                    children: [
                      // 이미지로 저장 버튼
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _saveAsImage,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_alt),
                          label: Text(_isSaving ? '저장 중...' : '이미지로 저장하기'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: AppConstants.kDefaultPadding),
                      
                      // 공유하기 버튼
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSharing ? null : _shareImage,
                          icon: _isSharing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.share),
                          label: Text(_isSharing ? '준비 중...' : '공유하기'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.kDefaultPadding),
                  
                  // 닫기 버튼
                  TextButton(
                    onPressed: () async {
                      // 방장인 경우 룸 리셋 또는 삭제
                      final roomRepository = ref.read(roomRepositoryProvider);
                      try {
                        await roomRepository.resetTimer(widget.roomId);
                      } catch (e) {
                        // 방장이 아니거나 오류 발생 시 무시
                      }
                      
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/home');
                      }
                    },
                    child: const Text(
                      '닫기',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text('오류가 발생했습니다: $err'),
        ),
      ),
    );
  }

  /// 위젯을 이미지로 캡처
  Future<Uint8List?> _captureWidget() async {
    try {
      RenderRepaintBoundary boundary = 
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      return null;
    }
  }

  /// 이미지로 저장
  Future<void> _saveAsImage() async {
    setState(() => _isSaving = true);

    try {
      final imageData = await _captureWidget();
      
      if (imageData != null) {
        final result = await ImageGallerySaver.saveImage(
          imageData,
          quality: 100,
          name: 'flowith_result_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        if (mounted) {
          final isSuccess = result['isSuccess'] ?? false;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isSuccess ? '이미지가 갤러리에 저장되었습니다!' : '저장에 실패했습니다.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미지 저장 중 오류가 발생했습니다.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// 이미지 공유
  Future<void> _shareImage() async {
    setState(() => _isSharing = true);

    try {
      final imageData = await _captureWidget();
      
      if (imageData != null) {
        // 임시 파일로 저장
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/flowith_result_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(imageData);
        
        // 공유
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '오늘도 Flowith와 함께 집중했어요! 🌱',
        );
        
        // 임시 파일 삭제
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error sharing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('공유 중 오류가 발생했습니다.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  /// 시간을 포맷된 문자열로 변환
  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    
    if (seconds == 0) {
      return '${minutes}분';
    } else if (minutes == 0) {
      return '${seconds}초';
    } else {
      return '${minutes}분 ${seconds}초';
    }
  }
}