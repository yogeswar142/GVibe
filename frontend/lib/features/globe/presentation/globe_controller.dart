abstract class GlobeViewController {
  void flyToCampus();
  void flyToUser(double lng, double lat, double zoom);
  void updateMarkers(List<Map<String, dynamic>> markers);
  void setGlobeStyle(String styleUrl);
  void setTheme(String theme);
  void setPointerEvents(bool enable);
}

