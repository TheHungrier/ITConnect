import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../controllers/campus_map_controller.dart';
import '../../models/campus_location_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_back_button.dart';

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({Key? key}) : super(key: key);

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  final CampusMapController _controller = CampusMapController();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  CampusLocationModel? _selectedLocation;

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _focusLocation(CampusLocationModel location) {
    setState(() {
      _selectedLocation = location;
    });

    _mapController.move(location.position, 18);
  }

  void _showLocationDetail(CampusLocationModel location) {
    _focusLocation(location);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider(context),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.blueGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(location.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        location.name,
                        style: TextStyle(
                          color: AppColors.title(context),
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _detailRow(
                  icon: Icons.location_city_rounded,
                  title: 'Khu vực',
                  value: location.building,
                ),
                _detailRow(
                  icon: Icons.layers_rounded,
                  title: 'Vị trí',
                  value: location.floor,
                ),
                _detailRow(
                  icon: Icons.info_outline_rounded,
                  title: 'Mô tả',
                  value: location.description,
                ),
                _detailRow(
                  icon: Icons.tips_and_updates_rounded,
                  title: 'Lưu ý',
                  value: location.note,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.iconBox(context),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.primary(context), size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.subtitle(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.title(context),
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final locations = _controller.filteredLocations();

        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                        child: _buildMapCard(locations),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                        child: _buildSearchBox(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                        child: _buildAreaFilter(),
                      ),
                    ),
                    if (locations.isEmpty)
                      SliverToBoxAdapter(
                        child: _emptyBox('Không tìm thấy địa điểm phù hợp'),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                        sliver: SliverList.separated(
                          itemCount: locations.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _locationCard(locations[index]);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, topPadding + 8, 18, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF00A8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Row(
        children: [
          AppBackButton(),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bản đồ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(List<CampusLocationModel> locations) {
    return Container(
      height: 310,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.divider(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _controller.campusCenter,
                initialZoom: 17,
                minZoom: 15,
                maxZoom: 19,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ltdd_qlhd_flutter',
                ),
                MarkerLayer(
                  markers: _controller.locations.map((location) {
                    final selected = _selectedLocation?.id == location.id;

                    return Marker(
                      point: location.position,
                      width: selected ? 54 : 46,
                      height: selected ? 54 : 46,
                      child: GestureDetector(
                        onTap: () {
                          _showLocationDetail(location);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            gradient: AppColors.blueGradient,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: selected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary(
                                  context,
                                ).withOpacity(selected ? 0.38 : 0.22),
                                blurRadius: selected ? 18 : 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            location.icon,
                            color: Colors.white,
                            size: selected ? 28 : 24,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card(context).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider(context)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary(context),
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Chạm vào marker để xem chi tiết địa điểm',
                        style: TextStyle(
                          color: AppColors.title(context),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: () {
                  _mapController.move(_controller.campusCenter, 17);
                  setState(() {
                    _selectedLocation = null;
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.card(context).withOpacity(0.94),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider(context)),
                  ),
                  child: Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primary(context),
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      onChanged: _controller.updateKeyword,
      cursorColor: AppColors.primary(context),
      style: TextStyle(
        color: AppColors.title(context),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: 'Tìm hội trường, phòng học, văn phòng...',
        hintStyle: TextStyle(
          color: AppColors.subtitle(context),
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AppColors.primary(context),
        ),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  _controller.updateKeyword('');
                },
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.subtitle(context),
                ),
              ),
        filled: true,
        fillColor: AppColors.card(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.divider(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.divider(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.primary(context), width: 1.3),
        ),
      ),
    );
  }

  Widget _buildAreaFilter() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _controller.areas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final area = _controller.areas[index];
          final selected = area == _controller.selectedArea;

          return GestureDetector(
            onTap: () {
              _controller.changeArea(area);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                gradient: selected ? AppColors.blueGradient : null,
                color: selected ? null : AppColors.card(context),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : AppColors.divider(context),
                ),
              ),
              child: Center(
                child: Text(
                  area,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.primary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _locationCard(CampusLocationModel location) {
    return GestureDetector(
      onTap: () {
        _showLocationDetail(location);
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow(context),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: AppColors.blueGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(location.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: TextStyle(
                      color: AppColors.title(context),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${location.building} • ${location.floor}',
                    style: TextStyle(
                      color: AppColors.subtitle(context),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    location.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.subtitle(context),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.primary(context),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.divider(context)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.subtitle(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
