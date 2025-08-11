import 'package:flutter/foundation.dart';
import '../models/file_model.dart';

class FileProvider extends ChangeNotifier {
  List<FileModel> _files = [];
  List<FileModel> _filteredFiles = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  FileType? _selectedFileType;
  SortOption _sortOption = SortOption.date;
  bool _sortAscending = false;

  // Getters
  List<FileModel> get files => _files;
  List<FileModel> get filteredFiles => _filteredFiles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  FileType? get selectedFileType => _selectedFileType;
  SortOption get sortOption => _sortOption;
  bool get sortAscending => _sortAscending;

  FileProvider() {
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    _setLoading(true);
    _clearError();
    
    try {
      // TODO: Load files from StorageService
      // For now, load sample data
      await Future.delayed(const Duration(seconds: 1));
      
      _files = _generateSampleFiles();
      _applyFiltersAndSort();
      
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Laden der Dateien: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  List<FileModel> _generateSampleFiles() {
    return [
      FileModel(
        id: '1',
        name: 'sample_photo_1.jpg',
        originalName: 'Urlaubsfoto.jpg',
        type: FileType.photo,
        size: 2048576, // 2MB
        uploadDate: DateTime.now().subtract(const Duration(days: 1)),
        isEncrypted: true,
        thumbnailPath: null,
        localPath: '/secure_files/1.jpg',
        cloudPath: null,
      ),
      FileModel(
        id: '2',
        name: 'sample_video_1.mp4',
        originalName: 'Geburtstagsfeier.mp4',
        type: FileType.video,
        size: 15728640, // 15MB
        uploadDate: DateTime.now().subtract(const Duration(days: 3)),
        isEncrypted: true,
        thumbnailPath: null,
        localPath: '/secure_files/2.mp4',
        cloudPath: null,
      ),
      FileModel(
        id: '3',
        name: 'sample_document_1.pdf',
        originalName: 'Wichtiges_Dokument.pdf',
        type: FileType.document,
        size: 1048576, // 1MB
        uploadDate: DateTime.now().subtract(const Duration(days: 5)),
        isEncrypted: true,
        thumbnailPath: null,
        localPath: '/secure_files/3.pdf',
        cloudPath: null,
      ),
    ];
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setFileTypeFilter(FileType? fileType) {
    _selectedFileType = fileType;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void toggleSortDirection() {
    _sortAscending = !_sortAscending;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    _filteredFiles = List.from(_files);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredFiles = _filteredFiles.where((file) {
        return file.originalName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply file type filter
    if (_selectedFileType != null) {
      _filteredFiles = _filteredFiles.where((file) {
        return file.type == _selectedFileType;
      }).toList();
    }
    
    // Apply sorting
    _filteredFiles.sort((a, b) {
      int comparison = 0;
      
      switch (_sortOption) {
        case SortOption.name:
          comparison = a.originalName.compareTo(b.originalName);
          break;
        case SortOption.date:
          comparison = a.uploadDate.compareTo(b.uploadDate);
          break;
        case SortOption.size:
          comparison = a.size.compareTo(b.size);
          break;
        case SortOption.type:
          comparison = a.type.toString().compareTo(b.type.toString());
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
  }

  Future<void> addFile(FileModel file) async {
    try {
      _files.add(file);
      _applyFiltersAndSort();
      notifyListeners();
      
      // TODO: Save to StorageService
    } catch (e) {
      _setError('Fehler beim Hinzufügen der Datei: ${e.toString()}');
    }
  }

  Future<void> deleteFile(String fileId) async {
    try {
      _files.removeWhere((file) => file.id == fileId);
      _applyFiltersAndSort();
      notifyListeners();
      
      // TODO: Delete from StorageService
    } catch (e) {
      _setError('Fehler beim Löschen der Datei: ${e.toString()}');
    }
  }

  Future<void> updateFile(FileModel updatedFile) async {
    try {
      final index = _files.indexWhere((file) => file.id == updatedFile.id);
      if (index != -1) {
        _files[index] = updatedFile;
        _applyFiltersAndSort();
        notifyListeners();
        
        // TODO: Update in StorageService
      }
    } catch (e) {
      _setError('Fehler beim Aktualisieren der Datei: ${e.toString()}');
    }
  }

  Future<void> refreshFiles() async {
    await _loadFiles();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}

enum SortOption {
  name,
  date,
  size,
  type,
}