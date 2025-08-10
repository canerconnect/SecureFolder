import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/file_model.dart';
import '../../providers/file_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/file_card.dart';
import '../../widgets/empty_state.dart';

class FilesTab extends StatefulWidget {
  const FilesTab({super.key});

  @override
  State<FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends State<FilesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  FileType? _selectedFilter;
  String _sortBy = 'date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    final fileProvider = context.read<FileProvider>();
    await fileProvider.loadFiles();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onFilterChanged(FileType? filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = false;
      }
    });
  }

  List<FileModel> _getFilteredAndSortedFiles(List<FileModel> files) {
    List<FileModel> filteredFiles = files;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredFiles = filteredFiles.where((file) {
        return file.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               file.originalName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply type filter
    if (_selectedFilter != null) {
      filteredFiles = filteredFiles.where((file) {
        return file.type == _selectedFilter;
      }).toList();
    }

    // Apply sorting
    filteredFiles.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'date':
          comparison = a.uploadDate.compareTo(b.uploadDate);
          break;
        case 'size':
          comparison = a.size.compareTo(b.size);
          break;
        case 'type':
          comparison = a.type.toString().compareTo(b.type.toString());
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filteredFiles;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Dateien durchsuchen...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Filter and Sort Row
              Row(
                children: [
                  // Type Filter
                  Expanded(
                    child: DropdownButtonFormField<FileType?>(
                      value: _selectedFilter,
                      decoration: const InputDecoration(
                        labelText: 'Typ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Alle Typen'),
                        ),
                        ...FileType.values.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(_getFileTypeDisplayName(type)),
                        )),
                      ],
                      onChanged: _onFilterChanged,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Sort Dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _sortBy,
                      decoration: const InputDecoration(
                        labelText: 'Sortieren nach',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'date', child: Text('Datum')),
                        DropdownMenuItem(value: 'name', child: Text('Name')),
                        DropdownMenuItem(value: 'size', child: Text('Größe')),
                        DropdownMenuItem(value: 'type', child: Text('Typ')),
                      ],
                      onChanged: _onSortChanged,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Sort Direction Button
                  IconButton(
                    onPressed: () => _onSortChanged(_sortBy),
                    icon: Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    ),
                    tooltip: _sortAscending ? 'Aufsteigend' : 'Absteigend',
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Files List
        Expanded(
          child: Consumer<FileProvider>(
            builder: (context, fileProvider, child) {
              if (fileProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final files = fileProvider.files;
              if (files.isEmpty) {
                return const EmptyState(
                  icon: Icons.folder_open,
                  title: 'Keine Dateien gefunden',
                  message: 'Laden Sie Ihre erste Datei hoch, um loszulegen.',
                );
              }

              final filteredFiles = _getFilteredAndSortedFiles(files);
              
              if (filteredFiles.isEmpty) {
                return const EmptyState(
                  icon: Icons.search_off,
                  title: 'Keine Ergebnisse',
                  message: 'Versuchen Sie andere Suchbegriffe oder Filter.',
                );
              }

              return RefreshIndicator(
                onRefresh: _loadFiles,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredFiles.length,
                  itemBuilder: (context, index) {
                    final file = filteredFiles[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FileCard(
                        file: file,
                        onTap: () => _openFile(file),
                        onDelete: () => _deleteFile(file),
                        onShare: () => _shareFile(file),
                        onDownload: () => _downloadFile(file),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getFileTypeDisplayName(FileType type) {
    switch (type) {
      case FileType.photo:
        return 'Fotos';
      case FileType.video:
        return 'Videos';
      case FileType.audio:
        return 'Audio';
      case FileType.document:
        return 'Dokumente';
      case FileType.note:
        return 'Notizen';
      case FileType.other:
        return 'Sonstige';
    }
  }

  void _openFile(FileModel file) {
    // TODO: Implement file opening based on type
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Öffne ${file.name}'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }

  Future<void> _deleteFile(FileModel file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Datei löschen'),
        content: Text('Möchten Sie "${file.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final fileProvider = context.read<FileProvider>();
      await fileProvider.deleteFile(file.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} wurde gelöscht'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  void _shareFile(FileModel file) {
    // TODO: Implement file sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Teile ${file.name}'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }

  void _downloadFile(FileModel file) {
    // TODO: Implement file download
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lade ${file.name} herunter'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }
}