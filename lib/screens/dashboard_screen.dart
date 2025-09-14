// dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:pawradise/screens/map/map_screen.dart';
import '../constants.dart';
import 'community/community_screen.dart';
import 'profile/pet_list_screen.dart';
import 'schedule/schedule_screen.dart';
import 'chat/ai_chat_screen.dart';
import 'profile/add_edit_pet_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pet_service.dart';
import '../models/pet_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'community/post_detail_screen.dart';
import '../models/places_service.dart';
import '../models/location_model.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          appBar: _selectedIndex == 0
              ? AppHeader.buildAppBar(
                  context: context,
                  title: "Pawradise",
                  actions: [
                    IconButton(
                      icon: Icon(Icons.notifications, color: AppColors.accent),
                      onPressed: () {},
                    ),
                  ],
                )
              : null,
          body: _currentPage,
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget get _currentPage {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent(FirebaseAuth.instance.currentUser?.displayName ?? "User");
      case 1:
        return const CommunityScreen();
      case 2:
        return const ScheduleScreen();
      case 3:
        return const MapScreen();
      case 4:
        return const PetListScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: AppBottomBar.items,
      currentIndex: _selectedIndex,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textSecondary,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.secondary,
    );
  }

  Color getContrastColor(Color bgColor) {
    return bgColor.computeLuminance() > 0.5 ? AppColors.accent : AppColors.background;
  }

  Widget _buildDashboardContent(String userName) {
    final sections = [
      {"title": "🐾 My Furry Friends", "child": _buildPetsSection(context), "bg": AppColors.primary},
      {"title": "💌 Community Buzz", "child": _buildCommunityPreview(context), "bg": AppColors.accent.withOpacity(0.5)},
      {"title": "📅 PawSchedule", "child": _buildSchedulePreview(context), "bg": AppColors.primary},
      {"title": "📍 Nearby Parks & Cafes", "child": _buildNearbyPlacesSection(context), "bg": AppColors.accent.withOpacity(0.5)},
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              // 顶部欢迎区
              Container(
                height: 180,
                width: double.infinity,
                color: AppColors.primary,
                padding: const EdgeInsets.only(top: 20, left: 24, right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, $userName!",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.background,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Welcome back to Pawradise",
                      style: TextStyle(
                        fontSize: 20,
                        color: AppColors.background.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -50),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                    border: Border.all(color: AppColors.accent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildQuickActions(context),
                      const SizedBox(height: 24),
                      ...sections.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildSectionContainer(
                          title: s["title"] as String,
                          child: s["child"] as Widget,
                          bgColor: s["bg"] as Color,
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(color: AppColors.secondary),
        ),
      ],
    );
  }

  // 修改后的 Section 容器
Widget _buildSectionContainer({
  required String title,
  required Widget child,
  required Color bgColor,
}) {
  return Container(
    decoration: BoxDecoration(
      color: bgColor, 
      border: Border.all(color: AppColors.accent, width: 2),
      borderRadius: BorderRadius.circular(20),
    ),
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: (title == "💌 Community Buzz" || title == "📍 Nearby Parks & Cafes")
                    ? AppColors.background
                    : AppColors.accent,
                  fontFamily: 'ComicNeue',
                )),
            if (title != "🐾 My Furry Friends")
              TextButton(
                onPressed: () {
                  if (title == "💌 Community Buzz") _switchToCommunity(context);
                  if (title == "📅 PawSchedule") _switchToSchedule(context);
                  if (title == "📍 Nearby Parks & Cafes") _switchToMap(context);
                },
                child: Text("See All",
                    style: TextStyle(
                        color: AppColors.background,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}


  Widget _buildPetsSection(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Text("Please log in to see your pets", style: TextStyle(color: AppColors.textSecondary));
    }

    return SizedBox(
      height: 160,
      child: StreamBuilder<List<Pet>>(
        stream: PetService().getPetsByUserStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final pets = snapshot.data ?? [];
          if (pets.isEmpty) return Row(children: [_buildAddPetCard(context)]);

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pets.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index < pets.length) return _buildPetCard(pets[index]);
              return _buildAddPetCard(context);
            },
          );
        },
      ),
    );
  }

Widget _buildPetCard(Pet pet) {
  return Card(
    elevation: 3,
    color: AppColors.accent.withOpacity(0.3), 
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: AppColors.accent, width: 2),
    ),
    child: Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.secondary.withOpacity(0.9),
            backgroundImage: (pet.imageUrl != null && pet.imageUrl!.isNotEmpty)
                ? NetworkImage(pet.imageUrl!)
                : null,
            child: (pet.imageUrl == null || pet.imageUrl!.isEmpty)
                ? Icon(Icons.pets, size: 32, color: AppColors.accent)
                : null,
          ),
          const SizedBox(height: 8),
          Text(pet.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.secondary),
              textAlign: TextAlign.center),
          Text(pet.breed,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppColors.secondary),
              textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}



  Widget _buildAddPetCard(BuildContext context) {
    return Card(
      elevation: 4,
      color: AppColors.secondary.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.accent, width: 2),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditPetScreen())),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 130,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add_circle, size: 40, color: Colors.white),
              SizedBox(height: 12),
              Text("Add Pet", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _buildActionButton(Icons.chat, "Ask PawPal", AppColors.primary, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AIChatScreen()));
            }),
            _buildActionButton(Icons.add_circle, "New Post", AppColors.accent.withOpacity(0.3), () => _switchToCommunity(context)),
            _buildActionButton(Icons.calendar_today, "Add Event", AppColors.accent.withOpacity(0.3), () => _switchToSchedule(context)),
            _buildActionButton(Icons.place, "Find Places", AppColors.primary, () => _switchToMap(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color cardColor, VoidCallback onPressed) {
    final color = getContrastColor(cardColor);
    return Card(
      elevation: 4,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.accent, width: 2),
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _switchToCommunity(BuildContext context) => setState(() => _selectedIndex = 1);
  void _switchToSchedule(BuildContext context) => setState(() => _selectedIndex = 2);
  void _switchToMap(BuildContext context) => setState(() => _selectedIndex = 3);

  Widget _buildCommunityPreview(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).limit(3).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final posts = snapshot.data?.docs ?? [];
        if (posts.isEmpty) return Text("No community updates yet", style: TextStyle(color: AppColors.textSecondary));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: posts.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildCommunityPost(data['title'] ?? 'Untitled', (data['likes'] ?? 0).toString(), doc.id);
          }).toList(),
        );
      },
    );
  }

Widget _buildCommunityPost(String title, String likes, String postId) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.9), 
      border: Border.all(color: AppColors.accent, width: 2),
      borderRadius: BorderRadius.circular(25),
    ),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.forum, color: AppColors.accent),
      title: Text(title,
          style: TextStyle(
              color: AppColors.accent, fontWeight: FontWeight.w500)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.favorite, color: AppColors.accent, size: 16),
        const SizedBox(width: 4),
        Text(likes,
            style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12)),
      ]),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PostDetailScreen(postId: postId))),
    ),
  );
}


  Widget _buildSchedulePreview(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return Text("Please log in to see schedule",
          style: TextStyle(color: AppColors.textSecondary));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('events')
          .orderBy('scheduledTime')
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final events = snapshot.data?.docs ?? [];
        if (events.isEmpty)
          return Text("No upcoming schedule",
              style: TextStyle(color: AppColors.textSecondary));

        return Column(
          children: events.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final scheduledTime = (data['scheduledTime'] as Timestamp).toDate();
            final date = DateFormat('MMM d, hh:mm a').format(scheduledTime);
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.3), 
                border: Border.all(color: AppColors.accent, width: 2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.event, color: AppColors.background),
                title: Text(data['title'] ?? 'Untitled',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: AppColors.background)),
                subtitle: Text(date,
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            );

          }).toList(),
        );
      },
    );
  }

  Widget _buildNearbyPlacesSection(BuildContext context) {
    return FutureBuilder<List<LocationModel>>(
      future: _fetchNearbyPlaces(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final locations = snapshot.data ?? [];
        if (locations.isEmpty) {
          return SizedBox(
            height: 300,
            child: Center(
              child: Text(
                "No nearby dog-friendly places found",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        // 取前 3 个
        final previewLocations = locations.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 小地图（只展示前3个marker）
            SizedBox(
              height: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(previewLocations[0].latitude,
                                  previewLocations[0].longitude),
                    zoom: 13,
                  ),
                  markers: previewLocations.map((loc) {
                    return Marker(
                      markerId: MarkerId(loc.id),
                      position: LatLng(loc.latitude, loc.longitude),
                      infoWindow: InfoWindow(title: loc.name),
                    );
                  }).toSet(),
                  zoomControlsEnabled: false,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 🔹 3个地点卡片
            ...previewLocations.map((loc) {
              return GestureDetector(
                onTap: () {
                  // 点击卡片 → 跳转到 MapScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          )),
                      if (loc.description.isNotEmpty)
                        Text(loc.description,
                            style: TextStyle(color: AppColors.textSecondary)),
                      Text("⭐ ${loc.rating.toStringAsFixed(1)}",
                          style: TextStyle(color: AppColors.accent)),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }



  Future<List<LocationModel>> _fetchNearbyPlaces() async {
    try {
      final loc = await Location().getLocation();
      final results = await PlacesService.fetchPetFriendlyPlaces(loc.latitude!, loc.longitude!);
      return results.map((place) => LocationModel(
        id: place['place_id'],
        name: place['name'],
        description: place['vicinity'],
        latitude: place['geometry']['location']['lat'],
        longitude: place['geometry']['location']['lng'],
        rating: place['rating']?.toDouble() ?? 0.0,
        category: place['types'][0] ?? 'Unknown',
      )).toList();
    } catch (e) {
      print("Error fetching nearby places: $e");
      return [];
    }
  }
}

// Google Map Widget
class GoogleMapWidget extends StatefulWidget {
  final List<LocationModel> locations;
  const GoogleMapWidget({super.key, required this.locations});

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  late GoogleMapController _mapController;
  bool _isMapExpanded = true;

  @override
  Widget build(BuildContext context) {
    final initialPosition = widget.locations.isNotEmpty
        ? LatLng(widget.locations[0].latitude, widget.locations[0].longitude)
        : const LatLng(3.139, 101.6869);

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: initialPosition, zoom: 13),
      markers: widget.locations
          .map((loc) => Marker(
                markerId: MarkerId(loc.id),
                position: LatLng(loc.latitude, loc.longitude),
                infoWindow: InfoWindow(title: loc.name, snippet: loc.description),
              ))
          .toSet(),
      onMapCreated: (controller) => _mapController = controller,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapToolbarEnabled: false,
    );
  }
}
