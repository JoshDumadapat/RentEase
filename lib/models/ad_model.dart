import 'package:flutter/material.dart';

class AdModel {
  final String id;
  final String imageUrl;
  final String brandName;
  final String tagline;
  final IconData icon;
  final int iconColor;

  const AdModel({
    required this.id,
    required this.imageUrl,
    required this.brandName,
    required this.tagline,
    required this.icon,
    required this.iconColor,
  });

  static List<AdModel> getAds() {
    return [
      const AdModel(
        id: 'spotify',
        imageUrl: 'https://completemusicupdate.com/content/images/size/w1200/2025/08/spotify-ads.png',
        brandName: 'Spotify Premium',
        tagline: 'Discover unlimited music, podcasts, and more',
        icon: Icons.music_note,
        iconColor: 0xFF1DB954, // Spotify green
      ),
      const AdModel(
        id: 'nike',
        imageUrl: 'https://i.shgcdn.com/4981bd15-1495-42d3-8fd3-51efe967a285/-/format/auto/-/preview/3000x3000/-/quality/lighter/',
        brandName: 'Nike',
        tagline: 'Just Do It. Find Your Greatness',
        icon: Icons.sports,
        iconColor: 0xFF000000, // Nike black
      ),
      const AdModel(
        id: 'gatorade',
        imageUrl: 'https://blog.adobe.com/en/publish/2017/10/12/media_15a6246838fe3d2c41214ef46bb38dd664c986d04.png?width=750&format=png&optimize=medium',
        brandName: 'Gatorade',
        tagline: 'Win From Within. Fuel Your Performance',
        icon: Icons.local_drink,
        iconColor: 0xFFF77F00, // Gatorade orange
      ),
      const AdModel(
        id: 'mcdo',
        imageUrl: 'https://d3bjzufjcawald.cloudfront.net/public/web/2025-05-17/68283af6f1cb8/McDo_Employer_Branding_2025_McDo_PH_Career_Portal_Banner_Mobile-optimized-banner-mobile.jpg',
        brandName: "McDonald's",
        tagline: 'I\'m Lovin\' It. Join Our Team',
        icon: Icons.restaurant,
        iconColor: 0xFFFFC72C, // McDonald's yellow
      ),
    ];
  }

  static AdModel getAdByIndex(int index) {
    final ads = getAds();
    return ads[index % ads.length];
  }
}
