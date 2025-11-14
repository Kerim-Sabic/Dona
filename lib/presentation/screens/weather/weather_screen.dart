import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/weather/weather_service.dart';
import '../../../data/models/weather_data.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService.instance;
  final TextEditingController _cityController = TextEditingController();
  WeatherData? _currentWeather;
  List<WeatherData> _forecast = [];
  bool _isLoading = true;
  String _currentCity = 'Sarajevo';

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadWeather({String? city}) async {
    setState(() {
      _isLoading = true;
      if (city != null) _currentCity = city;
    });

    try {
      final weather = await _weatherService.getCurrentWeather(city: _currentCity);
      final forecast = await _weatherService.getWeatherForecast(city: _currentCity);

      if (mounted) {
        setState(() {
          _currentWeather = weather;
          _forecast = forecast;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCityDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change City'),
          content: TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              hintText: 'Enter city name',
              prefixIcon: Icon(Icons.location_city),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final city = _cityController.text.trim();
                if (city.isNotEmpty) {
                  Navigator.pop(context);
                  _loadWeather(city: city);
                  _cityController.clear();
                }
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCity),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showCityDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadWeather(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentWeather == null
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _loadWeather(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCurrentWeather(),
                        const SizedBox(height: 24),
                        _buildWeatherDetails(),
                        const SizedBox(height: 24),
                        if (_forecast.isNotEmpty) _buildForecast(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCurrentWeather() {
    if (_currentWeather == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.secondaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Temperature
          Text(
            '${_currentWeather!.temperatureRounded}°C',
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            _currentWeather!.description.toUpperCase(),
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Feels like
          Text(
            'Feels like ${_currentWeather!.feelsLike.round()}°C',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails() {
    if (_currentWeather == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.thermostat,
                    'Min / Max',
                    '${_currentWeather!.tempMin.round()}° / ${_currentWeather!.tempMax.round()}°',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.water_drop,
                    'Humidity',
                    '${_currentWeather!.humidity}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.air,
                    'Wind',
                    '${_currentWeather!.windSpeed.toStringAsFixed(1)} m/s ${_currentWeather!.windDirection}',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.compress,
                    'Pressure',
                    '${_currentWeather!.pressure} hPa',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailItem(
              Icons.cloud,
              'Cloudiness',
              '${_currentWeather!.cloudiness}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondary, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForecast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forecast',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _forecast.length.clamp(0, 8),
            itemBuilder: (context, index) {
              final item = _forecast[index];
              return _buildForecastItem(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForecastItem(WeatherData weather) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weather.formattedTime,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${weather.temperatureRounded}°C',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            weather.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wb_sunny,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Weather not available',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadWeather(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
