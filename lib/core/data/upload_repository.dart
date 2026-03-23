import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../network/api_client.dart';

/// S3 presigned URL 업로드 결과
class UploadResult {
  final String fileUrl;
  final String key;

  const UploadResult({required this.fileUrl, required this.key});
}

/// 허용 MIME 타입
class AllowedContentType {
  static const imageJpeg = 'image/jpeg';
  static const imagePng = 'image/png';
  static const imageGif = 'image/gif';
  static const imageWebp = 'image/webp';
  static const videoMp4 = 'video/mp4';
  static const videoQuicktime = 'video/quicktime';
  static const applicationPdf = 'application/pdf';

  static const all = [
    imageJpeg, imagePng, imageGif, imageWebp,
    videoMp4, videoQuicktime, applicationPdf,
  ];
}

/// S3 presigned URL을 통한 파일 업로드 레포지토리
///
/// 흐름:
///   1. 서버에 presigned PUT URL 요청 (POST /attachments/presign)
///   2. 반환된 uploadUrl로 S3에 직접 PUT 업로드
///   3. fileUrl 반환 (메시지 전송 시 사용)
class UploadRepository {
  /// 파일(바이트) 업로드
  ///
  /// [bytes]        파일 바이트 (web / File 모두 지원)
  /// [fileName]     원본 파일명 (확장자 포함)
  /// [contentType]  MIME 타입 ([AllowedContentType] 참고)
  /// [onProgress]   업로드 진행률 콜백 (0.0 ~ 1.0)
  static Future<UploadResult> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    // 1. 서버에서 Presigned URL 발급
    final presignRes = await apiClient.post(
      ApiEndpoints.attachmentsPresign,
      data: {
        'fileName': fileName,
        'contentType': contentType,
        'fileSize': bytes.length,
      },
    );

    final data = presignRes.data['data'] as Map<String, dynamic>;
    final uploadUrl = data['uploadUrl'] as String;
    final fileUrl = data['fileUrl'] as String;
    final key = data['key'] as String;

    // 2. S3 직접 PUT 업로드 (인증 헤더 없이 — presigned URL이 이미 서명됨)
    final s3Dio = Dio();
    await s3Dio.put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': bytes.length,
        },
        // 응답 타입을 plain으로 — S3는 성공 시 빈 body 반환
        responseType: ResponseType.plain,
      ),
      onSendProgress: onProgress != null
          ? (sent, total) {
              if (total > 0) onProgress(sent / total);
            }
          : null,
    );

    return UploadResult(fileUrl: fileUrl, key: key);
  }

  /// File 객체로 업로드 (모바일용)
  static Future<UploadResult> uploadFile({
    required File file,
    required String fileName,
    required String contentType,
  }) async {
    final bytes = await file.readAsBytes();
    return uploadBytes(bytes: bytes, fileName: fileName, contentType: contentType);
  }

  /// 파일 확장자에서 MIME 타입 추론
  static String contentTypeFromExtension(String extension) {
    switch (extension.toLowerCase().replaceFirst('.', '')) {
      case 'jpg':
      case 'jpeg':
        return AllowedContentType.imageJpeg;
      case 'png':
        return AllowedContentType.imagePng;
      case 'gif':
        return AllowedContentType.imageGif;
      case 'webp':
        return AllowedContentType.imageWebp;
      case 'mp4':
        return AllowedContentType.videoMp4;
      case 'mov':
        return AllowedContentType.videoQuicktime;
      case 'pdf':
        return AllowedContentType.applicationPdf;
      default:
        return AllowedContentType.imageJpeg;
    }
  }

  /// 이미지 여부 확인
  static bool isImage(String contentType) => contentType.startsWith('image/');

  /// 비디오 여부 확인
  static bool isVideo(String contentType) => contentType.startsWith('video/');
}
