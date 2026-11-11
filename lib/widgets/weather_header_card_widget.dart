import 'package:flutter/material.dart';

class WeatherHeaderCardWidget extends StatelessWidget {
  const WeatherHeaderCardWidget({
    super.key,
    required this.temperature,
    required this.condition,
    required this.windSpeed,
    required this.humidity,
    required this.time,
    required this.date,
    required this.location,
    this.isGpsActive = true,
    this.onLocationTap,
  });

  final int temperature;
  final String condition;
  final int windSpeed;
  final int humidity;
  final String time;
  final String date;
  final String location;
  final bool isGpsActive;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Column: Weather Info (safe from overflow)
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wb_sunny_rounded,
                  color: Color(0xFFF9A825),
                  size: 36,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$temperature°C',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              condition,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Wind NW ${windSpeed}km/h\nHumidity $humidity%',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          height: 1.25,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 48,
            width: 1,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          // Right Column: Time, Date, Location
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    time,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    date,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: onLocationTap,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          isGpsActive
                              ? Icons.location_on_outlined
                              : Icons.location_off_outlined,
                          size: 11,
                          color: isGpsActive
                              ? const Color(0xFF800000)
                              : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: isGpsActive
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
