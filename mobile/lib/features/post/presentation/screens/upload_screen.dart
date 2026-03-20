import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tepilog/app/theme.dart';
import 'package:tepilog/features/map/data/location_repository.dart';
import 'package:tepilog/features/post/presentation/providers/upload_provider.dart';
import 'package:tepilog/features/post/presentation/screens/tag_on_map_screen.dart';
import 'package:tepilog/shared/providers/dio_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _captionController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _picker = ImagePicker();

  // Dynamic coordinates from Tag on Map
  double _lat = -6.2088;
  double _lng = 106.8456;
  bool _hasTaggedLocation = false;

  @override
  void dispose() {
    _captionController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      ref.read(uploadProvider.notifier).setImage(File(picked.path));
    }
  }

  Future<void> _takePicture() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      ref.read(uploadProvider.notifier).setImage(File(picked.path));
    }
  }

  void _handleUpload() {
    ref.read(uploadProvider.notifier).upload(
          latitude: _lat,
          longitude: _lng,
          caption: _captionController.text.isNotEmpty
              ? _captionController.text
              : null,
          locationName: _locationNameController.text.isNotEmpty
              ? _locationNameController.text
              : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadProvider);

    ref.listen<UploadState>(uploadProvider, (prev, next) {
      if (next.status == UploadStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto berhasil diupload! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(uploadProvider.notifier).reset();
        context.pop();
      }
      if (next.status == UploadStatus.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(uploadProvider.notifier).reset();
            context.pop();
          },
        ),
        title: const Text('Tepi Log Baru'),
        actions: [
          if (uploadState.selectedImage != null)
            TextButton(
              onPressed: uploadState.status == UploadStatus.uploading
                  ? null
                  : _handleUpload,
              child: uploadState.status == UploadStatus.uploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Upload',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 360,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 0.5),
                ),
                child: uploadState.selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              uploadState.selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // EXIF Overlay
                          if (uploadState.exifDate != null)
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        size: 10, color: Colors.white70),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatDate(uploadState.exifDate!),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Loading EXIF indicator
                          if (uploadState.status == UploadStatus.extractingExif)
                            const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 60, color: AppTheme.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'Ketuk untuk pilih foto',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Quick Actions (Gallery / Camera)
            if (uploadState.selectedImage == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galeri'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _takePicture,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Kamera'),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Tag on Map button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<LatLng>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TagOnMapScreen(
                        initialLat: _lat,
                        initialLng: _lng,
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _lat = result.latitude;
                      _lng = result.longitude;
                      _hasTaggedLocation = true;
                    });
                  }
                },
                icon: Icon(
                  _hasTaggedLocation ? Icons.check_circle : Icons.map_outlined,
                  size: 18,
                ),
                label: Text(
                  _hasTaggedLocation
                      ? 'Lokasi: ${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}'
                      : 'Tag di Peta',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _hasTaggedLocation ? Colors.green : Colors.white,
                  side: BorderSide(
                    color: _hasTaggedLocation ? Colors.green.withOpacity(0.5) : AppTheme.border,
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Caption
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _captionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Tulis caption... (opsional)',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location Name (Autocomplete)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RawAutocomplete<Location>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.length < 2) {
                    return const Iterable<Location>.empty();
                  }
                  try {
                    print('Searching locations for: ${textEditingValue.text}');
                    final repo = LocationRepository(ref.read(dioProvider));
                    final searchResult = await repo.searchLocations(textEditingValue.text);
                    print('Found ${searchResult.length} locations');
                    return searchResult;
                  } catch (e) {
                    print('Search error: $e');
                    return const Iterable<Location>.empty();
                  }
                },
                displayStringForOption: (Location option) => option.name ?? '',
                onSelected: (Location selection) {
                  _locationNameController.text = selection.name ?? '';
                  setState(() {
                    _lat = selection.latitude;
                    _lng = selection.longitude;
                    _hasTaggedLocation = true;
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  // Sync internal Autocomplete controller with our _locationNameController
                  // but we mainly use the one provided by Autocomplete for suggestions
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (val) => _locationNameController.text = val,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Nama lokasi... (opsional)',
                      prefixIcon: Icon(Icons.location_on_outlined,
                          color: AppTheme.textSecondary),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: MediaQuery.of(context).size.width - 32,
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (context, index) =>
                              Divider(color: AppTheme.border, height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final Location option = options.elementAt(index);
                            return ListTile(
                              title: Text(
                                option.name ?? 'Tanpa Nama',
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${option.postCount} kiriman',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 12),
                              ),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // EXIF info bar
            if (uploadState.exifDate != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Timestamp otomatis dari EXIF: ${_formatDate(uploadState.exifDate!)}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            if (uploadState.exifDate == null && uploadState.selectedImage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'EXIF tidak ditemukan — akan menggunakan waktu upload',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year} • '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
