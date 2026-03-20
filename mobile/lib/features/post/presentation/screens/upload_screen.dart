import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  int _currentStep = 0; // 0=photo, 1=location, 2=caption
  double _lat = -6.2088;
  double _lng = 106.8456;
  bool _hasTaggedLocation = false;
  String? _selectedLocationName;
  DateTime? _exifDate;

  @override
  void dispose() {
    _captionController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'new post',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '${_currentStep + 1}/3',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _StepChip(label: 'photo', done: _currentStep > 0, active: _currentStep == 0),
                const SizedBox(width: 8),
                _StepChip(label: 'location', done: _currentStep > 1, active: _currentStep == 1),
                const SizedBox(width: 8),
                _StepChip(label: 'caption', done: false, active: _currentStep == 2, showNumber: true, number: 3),
              ],
            ),
          ),

          const Divider(color: AppTheme.border, height: 1),

          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStep(uploadState),
            ),
          ),

          // Bottom button
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.of(context).padding.bottom),
            child: _buildButton(uploadState),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(UploadState uploadState) {
    switch (_currentStep) {
      case 0:
        return _buildPhotoStep(uploadState);
      case 1:
        return _buildLocationStep();
      case 2:
        return _buildCaptionStep(uploadState);
      default:
        return const SizedBox();
    }
  }

  // STEP 1: Photo
  Widget _buildPhotoStep(UploadState uploadState) {
    return Column(
      children: [
        if (uploadState.selectedImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(uploadState.selectedImage!.path),
              height: 280,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          if (uploadState.exifDate != null) ...[
            _exifDetected(uploadState.exifDate!),
            Builder(builder: (_) { _exifDate = uploadState.exifDate; return const SizedBox(); }),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _pickImage(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Ganti foto'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: AppTheme.border),
            ),
          ),
        ] else ...[
          const SizedBox(height: 60),
          Icon(Icons.add_a_photo_rounded, size: 64, color: AppTheme.border),
          const SizedBox(height: 16),
          const Text(
            'Pilih foto untuk diunggah',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(source: ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Galeri'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.border),
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(source: ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Kamera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.border),
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // STEP 2: Location
  Widget _buildLocationStep() {
    final uploadState = ref.watch(uploadProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photo preview small
        if (uploadState.selectedImage != null)
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(uploadState.selectedImage!.path),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedLocationName != null)
                      Text(
                        _selectedLocationName!,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    if (_exifDate != null)
                      Text(
                        'taken · ${_formatDate(_exifDate!)}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(height: 20),

        // Location autocomplete
        const Text('Nama Lokasi', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        RawAutocomplete<Location>(
          textEditingController: _locationNameController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.length < 2) {
              return const Iterable<Location>.empty();
            }
            try {
              final repo = LocationRepository(ref.read(dioProvider));
              return await repo.searchLocations(textEditingValue.text);
            } catch (e) {
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
              _selectedLocationName = selection.name;
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            if (controller.text != _locationNameController.text) {
              controller.text = _locationNameController.text;
            }
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Cari nama lokasi...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                elevation: 4,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 200,
                    maxWidth: MediaQuery.of(context).size.width - 40,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(option.name ?? '', style: const TextStyle(color: Colors.white)),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Tag on map button
        OutlinedButton.icon(
          onPressed: () async {
            final result = await Navigator.push<LatLng>(
              context,
              MaterialPageRoute(
                builder: (context) => TagOnMapScreen(initialLat: _lat, initialLng: _lng),
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
      ],
    );
  }

  // STEP 3: Caption
  Widget _buildCaptionStep(UploadState uploadState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview row
        if (uploadState.selectedImage != null)
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(uploadState.selectedImage!.path),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedLocationName != null)
                      Text(
                        _selectedLocationName!,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    if (_exifDate != null)
                      Text(
                        'taken · ${_formatDate(_exifDate!)}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(height: 24),

        // Caption field
        const Text('caption (optional)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: _captionController,
          style: const TextStyle(color: Colors.white),
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Morning light at the upper trail...',
          ),
        ),
        const SizedBox(height: 20),

        // EXIF detected
        if (_exifDate != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border, width: 0.5),
            ),
            child: Row(
              children: [
                const Text('exif detected', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const Spacer(),
                const Icon(Icons.access_time, size: 13, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _formatDate(_exifDate!),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _exifDetected(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 14, color: Colors.green),
          const SizedBox(width: 6),
          const Text('exif detected', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const Spacer(),
          const Icon(Icons.access_time, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            _formatDate(date),
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(UploadState uploadState) {
    if (_currentStep < 2) {
      final canProceed = _currentStep == 0
          ? uploadState.selectedImage != null
          : _hasTaggedLocation && _locationNameController.text.isNotEmpty;

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canProceed
              ? () => setState(() => _currentStep++)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.border,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          ),
          child: const Text('Lanjut', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
    }

    // Step 3: Publish
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: uploadState.status == UploadStatus.uploading
            ? null
            : () => _publish(uploadState),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.border,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        child: uploadState.status == UploadStatus.uploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            : const Text('publish', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }

  Future<void> _pickImage({ImageSource source = ImageSource.gallery}) async {
    final image = await _picker.pickImage(source: source, maxWidth: 1920);
    if (image != null) {
      ref.read(uploadProvider.notifier).setImage(File(image.path));
    }
  }

  Future<void> _publish(UploadState uploadState) async {
    if (uploadState.selectedImage == null) return;

    await ref.read(uploadProvider.notifier).upload(
      latitude: _lat,
      longitude: _lng,
      caption: _captionController.text.isEmpty ? null : _captionController.text,
      locationName: _locationNameController.text.isEmpty ? null : _locationNameController.text,
    );

    final newState = ref.read(uploadProvider);

    if (newState.status == UploadStatus.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post berhasil diupload! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (newState.status == UploadStatus.error && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newState.error ?? 'Gagal upload'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';
  }
}

// Step indicator chip
class _StepChip extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;
  final bool showNumber;
  final int number;

  const _StepChip({
    required this.label,
    required this.done,
    required this.active,
    this.showNumber = false,
    this.number = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? Colors.white.withOpacity(0.3) : AppTheme.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done)
            const Icon(Icons.check_circle, size: 14, color: Colors.green)
          else if (showNumber)
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: active ? Colors.white : AppTheme.textSecondary),
              ),
              child: Center(
                child: Text(
                  number.toString(),
                  style: TextStyle(
                    fontSize: 9,
                    color: active ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (done || showNumber) const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
