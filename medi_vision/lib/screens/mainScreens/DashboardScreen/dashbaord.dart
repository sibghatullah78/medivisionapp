import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../../../consts/bottomNavbar.dart';
import '../../../consts/themes.dart';
import 'dashboard_components.dart';

class Document {
  final String id;
  final String title;
  final String author;
  final String description;
  final DateTime createdAt;
  final String type;
  final String? filePath;

  Document({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.createdAt,
    required this.type,
    this.filePath,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'author': author,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'type': type,
    'filePath': filePath,
  };

  factory Document.fromMap(Map<String, dynamic> map) => Document(
    id: map['id'] as String,
    title: map['title'] as String,
    author: map['author'] as String,
    description: map['description'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    type: map['type'] as String,
    filePath: map['filePath'] as String?,
  );
}

class Dashboard extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final File? scannedImage;
  final File? pdfFile;

   const Dashboard({super.key, this.userData, this.scannedImage, this.pdfFile});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  late Map<String, dynamic> _userData;
  bool _isExpanded = true;
  List<File> _galleryImages = [];
  final List<Document> _fileDocuments = [];
  bool _isLoading = true;
  bool _hasAddedScannedImage = false;
  bool _hasAddedPdfFile = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        _loadGalleryImages(),
        _loadPdfDocuments(),
      ]);
    } catch (e) {
      _showErrorSnackbar('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeUserData() {
    _userData = widget.userData ?? {};
    _userData['fullName'] = _userData['fullName']?.toString().trim() ?? 'Guest User';
    _userData['email'] = _userData['email']?.toString().trim() ?? 'guest@example.com';
    _userData['phoneNumber'] = _userData['phoneNumber']?.toString().trim() ?? '';
    _userData['userType'] = _userData['userType']?.toString().trim() ?? 'Normal User';
  }

  Future<void> _loadGalleryImages() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = await _getImageFiles(dir);

      if (widget.scannedImage != null && !_hasAddedScannedImage) {
        files.add(await _saveScannedImage(dir));
        _hasAddedScannedImage = true;
      }

      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      if (mounted) setState(() => _galleryImages = files);
    } catch (e) {
      _showErrorSnackbar('Error loading gallery images: $e');
    }
  }

  Future<List<File>> _getImageFiles(Directory dir) async {
    try {
      final entities = await dir.list().toList();
      final uniqueFiles = <String, File>{};
      for (var entity in entities) {
        if (entity is File && _isImageFile(entity)) {
          uniqueFiles[entity.path] = entity;
        }
      }
      return uniqueFiles.values.toList();
    } catch (e) {
      _showErrorSnackbar('Error listing files: $e');
      return [];
    }
  }

  bool _isImageFile(File file) {
    final name = file.path.toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png');
  }

  Future<File> _saveScannedImage(Directory dir) async {
    try {
      final fileName = 'scanned_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = '${dir.path}/$fileName';
      return await widget.scannedImage!.copy(targetPath);
    } catch (e) {
      _showErrorSnackbar('Error saving scanned image: $e');
      rethrow;
    }
  }

  Future<void> _loadPdfDocuments() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final pdfFiles = await _getPdfFiles(dir);

      if (widget.pdfFile != null && !_hasAddedPdfFile) {
        final savedPdf = await _savePdfFile(dir, widget.pdfFile!);
        pdfFiles.add(savedPdf);
        _hasAddedPdfFile = true;
      }

      final pdfDocuments = pdfFiles.map((file) => Document(
        id: 'pdf_${file.path.hashCode}',
        title: file.path.split('/').last.replaceAll('.pdf', ''),
        author: _userData['fullName'] ?? 'User',
        description: 'PDF Document',
        createdAt: file.lastModifiedSync(),
        type: 'pdf',
        filePath: file.path,
      )).toList();

      pdfDocuments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _fileDocuments.clear();
          _fileDocuments.addAll(pdfDocuments);
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error loading PDF documents: $e');
    }
  }

  Future<List<File>> _getPdfFiles(Directory dir) async {
    try {
      final entities = await dir.list().toList();
      return entities.whereType<File>().where((file) {
        final name = file.path.toLowerCase();
        return name.endsWith('.pdf');
      }).toList();
    } catch (e) {
      _showErrorSnackbar('Error listing PDF files: $e');
      return [];
    }
  }

  Future<File> _savePdfFile(Directory dir, File pdfFile) async {
    try {
      final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final targetPath = '${dir.path}/$fileName';
      return await pdfFile.copy(targetPath);
    } catch (e) {
      _showErrorSnackbar('Error saving PDF file: $e');
      rethrow;
    }
  }

  void _onNavBarTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);

    const routes = ['/dashboard', '/scandocscreen', '/profile'];
    if (index < routes.length) {
      Navigator.pushReplacementNamed(context, routes[index],
          arguments: _userData)
          .catchError((e) => _showErrorSnackbar('Navigation error: $e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingView() : _buildBodyContent(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.surface,
      title: Text(
        'Welcome to MediVision',
        style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
      ),
      actions: [_buildAppIcon()],
    );
  }

  Widget _buildAppIcon() {
    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.only(right: AppDimensions.paddingMedium),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
        ),
        child: const Icon(Icons.medical_information, color: AppColors.textOnPrimary),
      ),
    );
  }

  Widget _buildBodyContent() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeaderSection(),
              const SizedBox(height: AppDimensions.paddingMedium),
              const DashboardSearchBar(),
              const SizedBox(height: AppDimensions.paddingLarge),
              _buildRecentSection(),
              const SizedBox(height: AppDimensions.paddingLarge),
              _buildScannedTodaySection(),
              const SizedBox(height: AppDimensions.paddingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Files',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_fileDocuments.length} documents • ${_galleryImages.length} images',
          style: TextStyle(
            fontSize: 14.0,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle('Recently'),
        const SizedBox(height: AppDimensions.paddingSmall),
        _buildCategoryGrid(),
      ],
    );
  }

  Widget _buildScannedTodaySection() {
    final today = DateTime.now();
    final todayImages = _galleryImages.where((image) {
      final modified = image.lastModifiedSync();
      return modified.year == today.year &&
          modified.month == today.month &&
          modified.day == today.day;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle('Scanned Today'),
        Text(
          DateFormat('MMMM dd, yyyy').format(DateTime.now()),
          style: TextStyle(
            fontSize: 14.0,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        todayImages.isEmpty
            ? _buildEmptyScannedSection()
            : ScannedToday(
          isExpanded: _isExpanded,
          toggleExpansion: () => setState(() => _isExpanded = !_isExpanded),
          images: todayImages,
          onImageTap: _showFullScreenImage,
          showAllImages: (BuildContext context, int index) {
            _navigateToGallery();
          },
        ),
      ],
    );
  }

  Widget _buildEmptyScannedSection() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported,
              color: AppColors.textSecondary, size: 32),
          const SizedBox(height: 8),
          Text(
            'No scans today',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/scandocscreen'),
            child: Text('Scan a document',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDimensions.paddingSmall,
        crossAxisSpacing: AppDimensions.paddingSmall,
        childAspectRatio: 1.4,
      ),
      itemCount: _categoryItems.length,
      itemBuilder: (context, index) => _buildCategoryCard(index),
    );
  }

  List<Map<String, dynamic>> get _categoryItems => [
    {
      'title': 'Files',
      'count': _fileDocuments.length,
      'icon': Icons.folder,
      'color': Colors.green,
      'onTap': _navigateToFiles,
    },
    {
      'title': 'Gallery',
      'count': _galleryImages.length,
      'icon': Icons.image,
      'color': Colors.blue,
      'onTap': _navigateToGallery,
    },
  ];

  Widget _buildCategoryCard(int index) {
    final category = _categoryItems[index];
    return CategoryCard(
      title: category['title'] as String,
      count: category['count'] as int,
      icon: category['icon'] as IconData,
      color: category['color'] as Color,
      onTap: category['onTap'] as VoidCallback,
    );
  }

  void _navigateToGallery() {
    if (_galleryImages.isEmpty) {
      _showErrorSnackbar('No images in gallery yet');
      return;
    }

    try {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => _buildGalleryScreen()),
      );
    } catch (e) {
      _showErrorSnackbar('Gallery error: $e');
    }
  }

  Widget _buildGalleryScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingSmall),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _galleryImages.length,
        itemBuilder: (context, index) => _buildGalleryImage(index),
      ),
    );
  }

  Widget _buildGalleryImage(int index) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(index),
      child: Hero(
        tag: 'gallery_image_$index',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
            child: Image.file(
              _galleryImages[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(
                    color: AppColors.background,
                    alignment: Alignment.center,
                    child: const Icon(Icons.error, color: AppColors.error),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(int index) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteImage(index),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareImage(index),
                ),
              ],
            ),
            body: Center(
              child: Hero(
                tag: 'gallery_image_$index',
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    _galleryImages[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, color: Colors.white, size: 64),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackbar('Error displaying image: $e');
    }
  }

  Future<void> _deleteImage(int index) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Image'),
          content: const Text('Are you sure you want to delete this image?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _galleryImages[index].delete();
        setState(() => _galleryImages.removeAt(index));

        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image deleted successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error deleting image: $e');
      }
    }
  }

  Future<void> _shareImage(int index) async {
    try {
      await Share.shareXFiles(
        [XFile(_galleryImages[index].path)],
        subject: 'Sharing image from MediVision',
      );
    } catch (e) {
      _showErrorSnackbar('Error sharing image: $e');
    }
  }

  void _navigateToFiles() {
    if (_fileDocuments.isEmpty) {
      _showErrorSnackbar('No files available');
      return;
    }

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Files'),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            body: _buildFilesList(),
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackbar('Files error: $e');
    }
  }

  Widget _buildFilesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      itemCount: _fileDocuments.length,
      itemBuilder: (context, index) => _buildFileItem(index),
    );
  }

  Widget _buildFileItem(int index) {
    final doc = _fileDocuments[index];
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.picture_as_pdf, color: Colors.red),
        ),
        title: Text(doc.title, style: AppStyles.cardTitleStyle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doc.description, style: AppStyles.cardSubtitleStyle),
            const SizedBox(height: 4),
            Text(
              'Created: ${DateFormat('MMM d, y').format(doc.createdAt)}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () => _openDocument(doc),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showDocumentOptions(doc),
        ),
      ),
    );
  }

  Future<void> _openDocument(Document doc) async {
    if (doc.filePath == null) {
      _showErrorSnackbar('No file path available for this document');
      return;
    }

    try {
      final result = await OpenFile.open(doc.filePath);
      if (result.type != ResultType.done) {
        _showErrorSnackbar('Could not open file: ${result.message}');
      }
    } catch (e) {
      _showErrorSnackbar('Could not open file: ${e.toString()}');
    }
  }

  void _showDocumentOptions(Document doc) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility, color: AppColors.primary),
              title: const Text('View Document'),
              onTap: () {
                Navigator.pop(context);
                _openDocument(doc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text('Share Document'),
              onTap: () {
                Navigator.pop(context);
                _shareDocument(doc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Document'),
              onTap: () {
                Navigator.pop(context);
                _deleteDocument(doc);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareDocument(Document doc) async {
    if (doc.filePath == null) {
      _showErrorSnackbar('No file available to share');
      return;
    }

    try {
      await Share.shareXFiles(
        [XFile(doc.filePath!)],
        subject: 'Sharing document: ${doc.title}',
        text: 'Check out this document from MediVision: ${doc.description}',
      );
    } catch (e) {
      _showErrorSnackbar('Error sharing document: ${e.toString()}');
    }
  }

  Future<void> _deleteDocument(Document doc) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Document'),
          content: Text('Are you sure you want to delete "${doc.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        if (doc.filePath != null) {
          final file = File(doc.filePath!);
          if (await file.exists()) {
            await file.delete();
          }
        }

        setState(() {
          _fileDocuments.removeWhere((d) => d.id == doc.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${doc.title} deleted')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error deleting document: ${e.toString()}');
      }
    }
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: AnimatedNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTapped,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class ScannedToday extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback toggleExpansion;
  final List<File> images;
  final Function(int index) onImageTap;
  final Function(BuildContext context, int index) showAllImages;
  final bool isLoading;

  const ScannedToday({
    super.key,
    required this.isExpanded,
    required this.toggleExpansion,
    required this.images,
    required this.onImageTap,
    required this.showAllImages,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final imagesToShow = isExpanded ? images : images.take(4).toList();

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: imagesToShow.length + (isExpanded ? 0 : 1),
          itemBuilder: (context, index) {
            if (!isExpanded && index == imagesToShow.length) {
              return _buildViewAllButton(context);
            }
            return _buildImageItem(imagesToShow[index], index);
          },
        ),
        if (!isExpanded && images.length > 4)
          TextButton(
            onPressed: toggleExpansion,
            child: const Text('Show More'),
          ),
      ],
    );
  }

  Widget _buildViewAllButton(BuildContext context) {
    return GestureDetector(
      onTap: () => showAllImages(context, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.more_horiz, size: 48),
            Text('View All'),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(File image, int index) {
    return GestureDetector(
      onTap: () => onImageTap(index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  DateFormat('hh:mm a').format(image.lastModifiedSync()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}