import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/post_model.dart';
import '../../models/location_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/places_service.dart';
import 'dart:async';
import '../../constants.dart';

class EditPostScreen extends StatefulWidget {
  final PostModel post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _keywordController = TextEditingController();
  final _locationSearchController = TextEditingController();
  String _selectedType = 'discussion';
  bool _isLoading = false;
  File? _selectedImage;
  bool _isUploadingImage = false;
  List<String> _keywords = [];

  // Location related variables
  LocationModel? _selectedLocation;
  bool _isGettingLocation = false;
  String _locationStatus = '';
  bool _isSearchingLocation = false;
  List<Map<String, dynamic>> _searchResults = [];

  final _postTypes = [
    {'value': 'discussion', 'label': 'Discussion'},
    {'value': 'alert', 'label': 'Alert'},
    {'value': 'event', 'label': 'Event'},
  ];

  @override
  void initState() {
    super.initState();
    
    // 使用现有帖子的数据填充表单
    _titleController.text = widget.post.title;
    _contentController.text = widget.post.content;
    _selectedType = widget.post.type;
    _keywords = List<String>.from(widget.post.keywords);
    
    // 设置位置信息
    if (widget.post.location != null) {
      _selectedLocation = LocationModel(
        id: widget.post.location!['id'] ?? '',
        name: widget.post.location!['name'] ?? '',
        description: widget.post.location!['description'] ?? '',
        latitude: widget.post.location!['latitude'] ?? 0.0,
        longitude: widget.post.location!['longitude'] ?? 0.0,
        rating: (widget.post.location!['rating'] ?? 0.0).toDouble(),
        category: widget.post.location!['category'] ?? '',
      );
      _locationSearchController.text = _selectedLocation!.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          child: AppBar(
            title: const Text(
              'Edit Post',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.background,
            elevation: 2,
            actions: [
              if (widget.post.hasImage && widget.post.imageUrl.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteExistingImage,
                  tooltip: 'Remove Image',
                ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Post type selection
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Post Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.background.withOpacity(0.5),
                ),
                items: _postTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),

              // Image section
              _buildImageSection(),
              const SizedBox(height: 16),

              // Title input
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.background.withOpacity(0.5),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please input title';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Content input
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.background.withOpacity(0.5),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please input content';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location section
              _buildLocationSection(),
              const SizedBox(height: 16),

              // Keywords section
              _buildKeywordsSection(),
              const SizedBox(height: 24),

              // Update button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent.withOpacity(0.9),
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: AppColors.background)
                      : const Text('Update Post'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 删除现有图片
  Future<void> _deleteExistingImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Image'),
        content: const Text('Are you sure you want to remove the image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _selectedImage = null;
      });
    }
  }

  // 更新帖子
  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String imageUrl = widget.post.imageUrl;
      bool hasImage = widget.post.hasImage;

      // 如果选择了新图片，上传新图片
      if (_selectedImage != null) {
        setState(() => _isUploadingImage = true);
        imageUrl = await _uploadImage(_selectedImage!);
        hasImage = true;
        setState(() => _isUploadingImage = false);
      } else if (_selectedImage == null && widget.post.hasImage) {
        // 保持原有图片
        hasImage = true;
        imageUrl = widget.post.imageUrl;
      } else {
        // 没有图片
        hasImage = false;
        imageUrl = '';
      }

      final autoKeywords = PostModel.generateKeywords(
        _titleController.text, 
        _contentController.text
      );
      final allKeywords = {...autoKeywords, ..._keywords}.toList();

      final locationMap = _selectedLocation != null
          ? PostModel.locationFromModel(_selectedLocation!)
          : null;

      // 更新帖子数据
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .update({
            'title': _titleController.text,
            'content': _contentController.text,
            'type': _selectedType,
            'hasImage': hasImage,
            'imageUrl': imageUrl,
            'keywords': allKeywords,
            'location': locationMap,
            'updatedAt': Timestamp.now(),
          });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update post: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isUploadingImage = false;
      });
    }
  }

  // 以下方法与 CreatePostScreen 相同，需要复制过来：
  // _buildLocationSection, _debounceSearch, _searchLocation, _selectSearchResult,
  // _getCurrentLocation, _getAddressFromPlacemark, _formatPlacemark, _clearLocation,
  // _buildKeywordsSection, _addKeyword, _removeKeyword, _buildImageSection,
  // _pickImage, _uploadImage, dispose

  // 复制 CreatePostScreen 中的以下方法：
Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        // Location search and current location button
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _locationSearchController,
                decoration: InputDecoration(
                  hintText: 'Search for a location...',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isSearchingLocation
                      ? const CircularProgressIndicator()
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchLocation,
                        ),
                ),
                onChanged: (value) {
                  if (value.length > 2) {
                    _debounceSearch();
                  } else {
                    setState(() {
                      _searchResults = [];
                    });
                  }
                },
                onTap: () {
                  if (_locationSearchController.text.length > 2) {
                    _searchLocation();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isGettingLocation ? null : _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              tooltip: 'Use Current Location',
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue[50],
                foregroundColor: Colors.blue[700],
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Search results
        if (_searchResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  title: Text(result['name'] ?? 'Unknown location'),
                  subtitle: Text(result['formatted_address'] ?? ''),
                  leading: const Icon(Icons.location_on, size: 20, color: Colors.blue),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  onTap: () => _selectSearchResult(result),
                );
              },
            ),
          ),
        
        // Selected location display
        if (_selectedLocation != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedLocation!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: _clearLocation,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (_selectedLocation!.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _selectedLocation!.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        
        // Location status message
        if (_locationStatus.isNotEmpty && _selectedLocation == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _locationStatus,
              style: TextStyle(
                color: Colors.orange[700],
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  // Fixed debounce search implementation
  Timer? _searchDebounce;
  void _debounceSearch() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    
    _searchDebounce = Timer(const Duration(milliseconds: 800), () {
      _searchLocation();
    });
  }

  // Improved search location method
  Future<void> _searchLocation() async {
    final query = _locationSearchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearchingLocation = false;
      });
      return;
    }

    setState(() {
      _isSearchingLocation = true;
    });

    try {
      // First try autocomplete for faster results
      final autocompleteResults = await PlacesService.autocomplete(query);
      
      if (autocompleteResults.isNotEmpty) {
        // Convert autocomplete predictions to search format
        final formattedResults = autocompleteResults.map((prediction) {
          return {
            'name': prediction['description'],
            'place_id': prediction['place_id'],
            'formatted_address': prediction['description'],
          };
        }).toList();
        
        setState(() {
          _searchResults = formattedResults;
          _isSearchingLocation = false;
        });
        return;
      }
      
      // Fallback to full search if autocomplete returns nothing
      final results = await PlacesService.searchPlaces(query);
      setState(() {
        _searchResults = results;
        _isSearchingLocation = false;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _isSearchingLocation = false;
        _locationStatus = 'Search failed. Please check your internet connection.';
        _searchResults = [];
      });
    }
  }

  // Improved select search result method
  Future<void> _selectSearchResult(Map<String, dynamic> result) async {
    setState(() {
      _isSearchingLocation = true;
      _locationStatus = 'Loading location details...';
    });

    try {
      // If we have a place_id from autocomplete, get full details
      if (result['place_id'] != null) {
        final details = await PlacesService.getPlaceDetails(result['place_id']);
        if (details != null) {
          setState(() {
            _selectedLocation = LocationModel(
              id: result['place_id'],
              name: details['name'] ?? result['name'] ?? 'Unknown Location',
              description: details['formatted_address'] ?? result['formatted_address'] ?? '',
              latitude: details['geometry']['location']['lat'],
              longitude: details['geometry']['location']['lng'],
              rating: (details['rating'] ?? 0.0).toDouble(),
              category: details['types']?.isNotEmpty == true 
                  ? details['types'][0] 
                  : 'establishment',
            );
            _locationSearchController.text = _selectedLocation!.name;
            _searchResults = [];
            _locationStatus = '';
            _isSearchingLocation = false;
          });
          return;
        }
      }
      
      // Fallback for direct search results
      setState(() {
        _selectedLocation = LocationModel(
          id: result['place_id'] ?? 'search_result_${DateTime.now().millisecondsSinceEpoch}',
          name: result['name'] ?? 'Unknown Location',
          description: result['formatted_address'] ?? '',
          latitude: result['geometry']?['location']?['lat'] ?? 0.0,
          longitude: result['geometry']?['location']?['lng'] ?? 0.0,
          rating: (result['rating'] ?? 0.0).toDouble(),
          category: result['types']?.isNotEmpty == true 
              ? result['types'][0] 
              : 'establishment',
        );
        _locationSearchController.text = _selectedLocation!.name;
        _searchResults = [];
        _locationStatus = '';
        _isSearchingLocation = false;
      });
    } catch (e) {
      print('Error selecting result: $e');
      setState(() {
        _locationStatus = 'Failed to get location details. Please try again.';
        _isSearchingLocation = false;
      });
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationStatus = 'Getting location...';
      _searchResults = [];
    });

    try {
      final status = await Permission.location.request();
      if (!status.isGranted) {
        setState(() {
          _locationStatus = 'Location permission denied';
          _isGettingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final placemark = placemarks.isNotEmpty ? placemarks[0] : null;
      final locationName = placemark != null
          ? _formatPlacemark(placemark)
          : 'Current Location';

      setState(() {
        _selectedLocation = LocationModel(
          id: 'current_location_${DateTime.now().millisecondsSinceEpoch}',
          name: locationName,
          description: _getAddressFromPlacemark(placemark),
          latitude: position.latitude,
          longitude: position.longitude,
          rating: 0.0,
          category: 'current',
        );
        _locationSearchController.text = locationName;
        _locationStatus = '';
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'Failed to get location: $e';
        _isGettingLocation = false;
      });
    }
  }

  // Format address from placemark
  String _getAddressFromPlacemark(Placemark? placemark) {
    if (placemark == null) return 'Unknown address';
    
    final parts = [
      placemark.street,
      placemark.locality,
      placemark.administrativeArea,
      placemark.country
    ].where((part) => part != null && part.isNotEmpty).toList();
    
    return parts.isNotEmpty ? parts.join(', ') : 'Unknown address';
  }

  // Format placemark for display name
  String _formatPlacemark(Placemark placemark) {
    if (placemark.name != null && placemark.name!.isNotEmpty) {
      return placemark.name!;
    }
    
    final parts = [
      placemark.street,
      placemark.locality,
    ].where((part) => part != null && part.isNotEmpty).toList();
    
    return parts.isNotEmpty ? parts.join(', ') : 'Current Location';
  }

  // Clear location
  void _clearLocation() {
    setState(() {
      _selectedLocation = null;
      _locationSearchController.clear();
      _locationStatus = '';
      _searchResults = [];
    });
  }

  // Rest of the code remains the same (keywords section, image section, create post, etc.)
  // ... [Keep the existing _buildKeywordsSection, _buildImageSection, _createPost methods] ...
  
  Widget _buildKeywordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Keywords',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _keywordController,
                decoration: InputDecoration(
                  hintText: 'Add keyword...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.background.withOpacity(0.5),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add, color: AppColors.accent),
                    onPressed: _addKeyword,
                  ),
                ),
                onFieldSubmitted: (_) => _addKeyword(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addKeyword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent.withOpacity(0.9),
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_keywords.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _keywords.map((keyword) {
              return Chip(
                label: Text(keyword),
                backgroundColor: AppColors.accent.withOpacity(0.1),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeKeyword(keyword),
                labelStyle: TextStyle(color: AppColors.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.accent.withOpacity(0.5)),
                ),
              );
            }).toList(),
          ),
        if (_keywords.isEmpty)
          Text(
            'Add keywords to help others find your post',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  void _addKeyword() {
    final keyword = _keywordController.text.trim();
    if (keyword.isNotEmpty && !_keywords.contains(keyword)) {
      setState(() {
        _keywords.add(keyword);
        _keywordController.clear();
      });
    }
  }

  void _removeKeyword(String keyword) {
    setState(() {
      _keywords.remove(keyword);
    });
  }
  
  Widget _buildImageSection() {
    return Column(
      children: [
        if (_selectedImage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      onPressed: () => setState(() => _selectedImage = null),
                      icon: Icon(Icons.close, size: 16, color: AppColors.background),
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickImage,
            icon: Icon(Icons.camera_alt, color: AppColors.accent),
            label: Text("Select Image", style: TextStyle(color: AppColors.accent)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.accent),
            ),
          ),
        ),
        if (_isUploadingImage)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(),
          )
      ],
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select image: $e')),
      );
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final String fileName = 'posts/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Upload Error: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _keywordController.dispose();
    _locationSearchController.dispose();
    super.dispose();
  }
}