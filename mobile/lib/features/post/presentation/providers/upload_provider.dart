import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tepilog/features/post/data/post_repository.dart';
import 'package:tepilog/shared/providers/dio_provider.dart';

enum UploadStatus { idle, pickingImage, extractingExif, uploading, success, error }

class UploadState {
  final UploadStatus status;
  final File? selectedImage;
  final DateTime? exifDate;
  final PostModel? createdPost;
  final String? error;

  UploadState({
    this.status = UploadStatus.idle,
    this.selectedImage,
    this.exifDate,
    this.createdPost,
    this.error,
  });

  UploadState copyWith({
    UploadStatus? status,
    File? selectedImage,
    DateTime? exifDate,
    PostModel? createdPost,
    String? error,
  }) {
    return UploadState(
      status: status ?? this.status,
      selectedImage: selectedImage ?? this.selectedImage,
      exifDate: exifDate ?? this.exifDate,
      createdPost: createdPost ?? this.createdPost,
      error: error,
    );
  }
}

class UploadNotifier extends Notifier<UploadState> {
  @override
  UploadState build() => UploadState();

  PostRepository get _postRepo => PostRepository(ref.read(dioProvider));

  void setImage(File image) {
    state = UploadState(
      status: UploadStatus.extractingExif,
      selectedImage: image,
    );
    _extractExif(image);
  }

  Future<void> _extractExif(File image) async {
    final exifDate = await _postRepo.extractExifDate(image);
    state = state.copyWith(
      status: UploadStatus.idle,
      exifDate: exifDate,
    );
  }

  Future<void> upload({
    required double latitude,
    required double longitude,
    String? caption,
    String? locationName,
  }) async {
    if (state.selectedImage == null) return;

    state = state.copyWith(status: UploadStatus.uploading, error: null);

    try {
      final post = await _postRepo.createPost(
        photo: state.selectedImage!,
        latitude: latitude,
        longitude: longitude,
        caption: caption,
        takenAt: state.exifDate,
        locationName: locationName,
      );

      state = state.copyWith(
        status: UploadStatus.success,
        createdPost: post,
      );
    } catch (e) {
      print('Upload error detailed: $e');
      state = state.copyWith(
        status: UploadStatus.error,
        error: 'Gagal mengupload foto. Silakan coba lagi.',
      );
    }
  }

  void reset() {
    state = UploadState();
  }
}

final uploadProvider = NotifierProvider<UploadNotifier, UploadState>(UploadNotifier.new);
