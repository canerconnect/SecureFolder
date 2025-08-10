import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_folder/providers/file_provider.dart';
import 'package:secure_folder/providers/auth_provider.dart';
import 'package:secure_folder/models/secure_file.dart';
import 'package:secure_folder/utils/theme.dart';
import 'package:secure_folder/screens/home/file_category_screen.dart';
import 'package:secure_folder/screens/home/upload_bottom_sheet.dart';
import 'package:secure_folder/screens/notes/note_list_screen.dart';
import 'package:secure_folder/screens/settings/settings_screen.dart';
import 'package:intl/intl.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFiles();
    });
  }

  Future<void> _loadFiles() async {
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    await fileProvider.loadFiles();
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UploadBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.systemBackground,
      body: IndexedStack(
        index: _selectedTab,
        children: const [
          _FilesTab(),
          _AlbumsTab(),
          _RecentTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.systemBackground,
          border: Border(
            top: BorderSide(
              color: AppTheme.systemGray4,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _selectedTab,
            onTap: (index) => setState(() => _selectedTab = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppTheme.primaryBlue,
            unselectedItemColor: AppTheme.systemGray,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_outlined),
                activeIcon: Icon(Icons.folder),
                label: 'Dateien',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.photo_library_outlined),
                activeIcon: Icon(Icons.photo_library),
                label: 'Alben',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_time_outlined),
                activeIcon: Icon(Icons.access_time),
                label: 'Neueste',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadOptions,
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilesTab extends StatelessWidget {
  const _FilesTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Sicherer Ordner'),
          backgroundColor: AppTheme.systemBackground,
          floating: true,
          snap: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Consumer<FileProvider>(
              builder: (context, fileProvider, child) {
                return Column(
                  children: [
                    // File Type Categories Grid
                    _FileTypesGrid(fileProvider: fileProvider),
                    
                    const SizedBox(height: 32),
                    
                    // Special Folders
                    _SpecialFolders(fileProvider: fileProvider),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FileTypesGrid extends StatelessWidget {
  final FileProvider fileProvider;

  const _FileTypesGrid({required this.fileProvider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _FileTypeCard(
              title: 'Fotos',
              count: fileProvider.photos.length,
              icon: Icons.photo_library_rounded,
              color: const Color(0xFF34C759),
              onTap: () => _navigateToCategory(context, FileType.photo),
            ),
            const SizedBox(width: 16),
            _FileTypeCard(
              title: 'Dokumente',
              count: fileProvider.documents.length,
              icon: Icons.description_rounded,
              color: const Color(0xFF007AFF),
              onTap: () => _navigateToCategory(context, FileType.document),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _FileTypeCard(
              title: 'Videos',
              count: fileProvider.videos.length,
              icon: Icons.videocam_rounded,
              color: const Color(0xFFFF3B30),
              onTap: () => _navigateToCategory(context, FileType.video),
            ),
            const SizedBox(width: 16),
            _FileTypeCard(
              title: 'Sprachmemos',
              count: fileProvider.audioFiles.length,
              icon: Icons.mic_rounded,
              color: const Color(0xFFFF9500),
              onTap: () => _navigateToCategory(context, FileType.audio),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToCategory(BuildContext context, FileType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileCategoryScreen(fileType: type),
      ),
    );
  }
}

class _FileTypeCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FileTypeCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.secondarySystemBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.systemGray5,
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count ${count == 1 ? 'Element' : 'Elemente'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecialFolders extends StatelessWidget {
  final FileProvider fileProvider;

  const _SpecialFolders({required this.fileProvider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SpecialFolderItem(
          title: 'Urlaub',
          count: 12,
          icon: Icons.beach_access_rounded,
          onTap: () {},
        ),
        _SpecialFolderItem(
          title: 'Wichtige Dateien',
          count: 7,
          icon: Icons.star_rounded,
          onTap: () {},
        ),
        _SpecialFolderItem(
          title: 'Notizen',
          count: fileProvider.notes.length,
          icon: Icons.note_alt_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NoteListScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _SpecialFolderItem extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  const _SpecialFolderItem({
    required this.title,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.systemGray5,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.systemGray,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: Text(
          '$count ${count == 1 ? 'Element' : 'Elemente'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.secondaryLabel,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.systemGray2,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: AppTheme.secondarySystemBackground,
      ),
    );
  }
}

class _AlbumsTab extends StatelessWidget {
  const _AlbumsTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          title: Text('Alben'),
          backgroundColor: AppTheme.systemBackground,
          floating: true,
          snap: true,
          elevation: 0,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: Consumer<FileProvider>(
            builder: (context, fileProvider, child) {
              final photos = fileProvider.photos;
              final videos = fileProvider.videos;
              
              return SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildListDelegate([
                  _AlbumCard(
                    title: 'Alle Fotos',
                    count: photos.length,
                    thumbnailFiles: photos.take(4).toList(),
                  ),
                  _AlbumCard(
                    title: 'Videos',
                    count: videos.length,
                    thumbnailFiles: videos.take(4).toList(),
                  ),
                ]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final String title;
  final int count;
  final List<SecureFile> thumbnailFiles;

  const _AlbumCard({
    required this.title,
    required this.count,
    required this.thumbnailFiles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.systemGray5,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail grid
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.systemGray6,
              ),
              child: thumbnailFiles.isNotEmpty
                  ? _buildThumbnailGrid()
                  : const Center(
                      child: Icon(
                        Icons.photo_library_outlined,
                        size: 48,
                        color: AppTheme.systemGray2,
                      ),
                    ),
            ),
          ),
          // Title and count
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  '$count ${count == 1 ? 'Element' : 'Elemente'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailGrid() {
    if (thumbnailFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    if (thumbnailFiles.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: AppTheme.systemGray3,
          child: const Center(
            child: Icon(
              Icons.image_outlined,
              size: 32,
              color: AppTheme.systemGray,
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        itemCount: thumbnailFiles.length.clamp(0, 4),
        itemBuilder: (context, index) {
          return Container(
            color: AppTheme.systemGray3,
            child: const Center(
              child: Icon(
                Icons.image_outlined,
                size: 20,
                color: AppTheme.systemGray,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecentTab extends StatelessWidget {
  const _RecentTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          title: Text('Neueste'),
          backgroundColor: AppTheme.systemBackground,
          floating: true,
          snap: true,
          elevation: 0,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: Consumer<FileProvider>(
            builder: (context, fileProvider, child) {
              final recentFiles = fileProvider.files.take(20).toList();
              
              if (recentFiles.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 64,
                          color: AppTheme.systemGray2,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Keine Dateien vorhanden',
                          style: TextStyle(
                            fontSize: 17,
                            color: AppTheme.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final file = recentFiles[index];
                    return _RecentFileItem(file: file);
                  },
                  childCount: recentFiles.length,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentFileItem extends StatelessWidget {
  final SecureFile file;

  const _RecentFileItem({required this.file});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildFileIcon(),
        title: Text(
          file.name,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: Text(
          '${DateFormat('dd.MM.yyyy').format(file.createdAt)} • ${file.displaySize}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.secondaryLabel,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () {
            // TODO: Show file options
          },
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: AppTheme.secondarySystemBackground,
      ),
    );
  }

  Widget _buildFileIcon() {
    IconData iconData;
    Color color;

    switch (file.type) {
      case FileType.photo:
        iconData = Icons.image_rounded;
        color = const Color(0xFF34C759);
        break;
      case FileType.video:
        iconData = Icons.videocam_rounded;
        color = const Color(0xFFFF3B30);
        break;
      case FileType.document:
        iconData = Icons.description_rounded;
        color = const Color(0xFF007AFF);
        break;
      case FileType.note:
        iconData = Icons.note_alt_rounded;
        color = const Color(0xFFFF9500);
        break;
      case FileType.audio:
        iconData = Icons.mic_rounded;
        color = const Color(0xFFFF9500);
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: color,
        size: 20,
      ),
    );
  }
}