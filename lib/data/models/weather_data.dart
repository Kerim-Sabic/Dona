class WeatherData {
  final String cityName;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final int pressure;
  final String description;
  final String icon;
  final double windSpeed;
  final int windDeg;
  final int cloudiness;
  final DateTime timestamp;

  WeatherData({
    required this.cityName,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.pressure,
    required this.description,
    required this.icon,
    required this.windSpeed,
    required this.windDeg,
    required this.cloudiness,
    required this.timestamp,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;
    final clouds = json['clouds'] as Map<String, dynamic>;

    return WeatherData(
      cityName: json['name'] ?? 'Unknown',
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      tempMin: (main['temp_min'] as num).toDouble(),
      tempMax: (main['temp_max'] as num).toDouble(),
      humidity: main['humidity'] as int,
      pressure: main['pressure'] as int,
      description: weather['description'] ?? 'Unknown',
      icon: weather['icon'] ?? '01d',
      windSpeed: (wind['speed'] as num).toDouble(),
      windDeg: wind['deg'] as int? ?? 0,
      cloudiness: clouds['all'] as int? ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
    );
  }

  factory WeatherData.fromForecastJson(Map<String, dynamic> json, String cityName) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;
    final clouds = json['clouds'] as Map<String, dynamic>;

    return WeatherData(
      cityName: cityName,
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      tempMin: (main['temp_min'] as num).toDouble(),
      tempMax: (main['temp_max'] as num).toDouble(),
      humidity: main['humidity'] as int,
      pressure: main['pressure'] as int,
      description: weather['description'] ?? 'Unknown',
      icon: weather['icon'] ?? '01d',
      windSpeed: (wind['speed'] as num).toDouble(),
      windDeg: wind['deg'] as int? ?? 0,
      cloudiness: clouds['all'] as int? ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
    );
  }

  /// Get weather icon URL from OpenWeatherMap
  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';

  /// Get temperature rounded to integer
  int get temperatureRounded => temperature.round();

  /// Get wind direction as text
  String get windDirection {
    if (windDeg >= 337.5 || windDeg < 22.5) return 'N';
    if (windDeg >= 22.5 && windDeg < 67.5) return 'NE';
    if (windDeg >= 67.5 && windDeg < 112.5) return 'E';
    if (windDeg >= 112.5 && windDeg < 157.5) return 'SE';
    if (windDeg >= 157.5 && windDeg < 202.5) return 'S';
    if (windDeg >= 202.5 && windDeg < 247.5) return 'SW';
    if (windDeg >= 247.5 && windDeg < 292.5) return 'W';
    if (windDeg >= 292.5 && windDeg < 337.5) return 'NW';
    return 'N';
  }

  /// Format timestamp as time string
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Format timestamp as date string
  String get formattedDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${timestamp.day} ${months[timestamp.month - 1]}';
  }

  Map<String, dynamic> toJson() {
    return {
      'city_name': cityName,
      'temperature': temperature,
      'feels_like': feelsLike,
      'temp_min': tempMin,
      'temp_max': tempMax,
      'humidity': humidity,
      'pressure': pressure,
      'description': description,
      'icon': icon,
      'wind_speed': windSpeed,
      'wind_deg': windDeg,
      'cloudiness': cloudiness,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
