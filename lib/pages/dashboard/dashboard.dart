import 'package:flutter/material.dart';
import '/../components/aqi_card.dart';
import '/../dialogs/info_dialog.dart';
import '/../models/device.dart';
import 'widgets/device_chip.dart';
import 'widgets/section_card.dart';
import 'widgets/toggle_row.dart';
import 'widgets/fan_speed_selector.dart';

class Dashboard extends StatelessWidget {
  final List<Device> devices;
  final int selectedDeviceIndex;
  final ValueChanged<int> onSelectDevice;
  final ValueChanged<Device> onUpdateDevice;

  const Dashboard({
    super.key,
    required this.devices,
    required this.selectedDeviceIndex,
    required this.onSelectDevice,
    required this.onUpdateDevice,
  });

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) return const SizedBox.shrink();

    final safeIndex = selectedDeviceIndex.clamp(0, devices.length - 1);
    final selectedDevice = devices[safeIndex];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1F2228) : Colors.white;
    final surfaceColor = isDark
        ? const Color(0xFF1F2228)
        : const Color(0xFFF3F4F6);
    final borderColor = isDark
        ? const Color(0xFF2B2F36)
        : const Color(0xFFE5E7EB);
    final titleColor = isDark
        ? const Color(0xFFF3F4F6)
        : const Color(0xFF111827);
    final bodyColor = isDark
        ? const Color(0xFFB9C0CB)
        : const Color(0xFF4B5563);
    final primary = isDark ? const Color(0xFF415A77) : const Color(0xFF1B263B);

    final deviceChipBaseColor = isDark ? const Color(0xFF1B263B) : primary;
    final fanInactiveFill = const Color(0xFF1B263B);
    final fanActiveColor = const Color(0xFF415A77);
    final fanInactiveTextColor = isDark
        ? bodyColor
        : Colors.white.withValues(alpha: 0.95);

    // 🖋 Text styles
    final titleMedium =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final bodyMedium =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

    final sectionTitleStyle = titleMedium.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: (titleMedium.fontSize ?? 16) + 1,
      color: titleColor,
    );

    final cardTitleStyle = titleMedium.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: (titleMedium.fontSize ?? 16) + 1,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AqiCard(
            background: primary,
            titleStyle: cardTitleStyle,
            bodyStyle: bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            onInfo: () {
              showInfoDialog(
                context,
                title: 'AQI',
                body:
                    'Air Quality Index (AQI) indicates overall air quality on a 0–200 scale, where 0 is excellent and 200 is very unhealthy. Higher values mean cleaner air.',
              );
            },
            valueLabel: selectedDevice.aqiLabel,
            aqiValue: selectedDevice.aqiValue,
            percent: selectedDevice.aqiPercent,
            percentText: '${(selectedDevice.aqiPercent * 100).round()}%',
            ringColor: selectedDevice.aqiRingColor,
          ),

          const SizedBox(height: 16),
          Text('Current Devices', style: sectionTitleStyle),
          const SizedBox(height: 10),

          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: devices.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final device = devices[index];
                return DeviceChip(
                  device: device,
                  selected: index == safeIndex,
                  color: deviceChipBaseColor,
                  onSelect: () => onSelectDevice(index),
                  onTogglePower: () {
                    onUpdateDevice(device.copyWith(isOn: !device.isOn));
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          SectionCard(
            cardColor: cardColor,
            borderColor: borderColor,
            child: Column(
              children: [
                ToggleRow(
                  label: 'Smart Mode',
                  value: selectedDevice.smartMode,
                  labelStyle: bodyMedium.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (value) =>
                      onUpdateDevice(selectedDevice.copyWith(smartMode: value)),
                ),
                Divider(color: borderColor, height: 18),
                if (selectedDevice.smartMode) ...[
                  ToggleRow(
                    label: 'Auto adjust fan speed',
                    value: selectedDevice.autoAdjustFanSpeed,
                    labelStyle: bodyMedium.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: (value) => onUpdateDevice(
                      selectedDevice.copyWith(autoAdjustFanSpeed: value),
                    ),
                  ),
                  Divider(color: borderColor, height: 18),
                  ToggleRow(
                    label: 'Turn off automatically',
                    value: selectedDevice.turnOffAutomatically,
                    labelStyle: bodyMedium.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: (value) => onUpdateDevice(
                      selectedDevice.copyWith(turnOffAutomatically: value),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),
          Text('Fan Speed', style: sectionTitleStyle),
          const SizedBox(height: 10),

          SectionCard(
            cardColor: cardColor,
            borderColor: borderColor,
            child: FanSpeedSelector(
              value: selectedDevice.fanSpeed,
              onChanged: (value) =>
                  onUpdateDevice(selectedDevice.copyWith(fanSpeed: value)),
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              activeColor: fanActiveColor,
              inactiveFill: fanInactiveFill,
              inactiveTextColor: fanInactiveTextColor,
              activeTextColor: Colors.white,
              textStyle: bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
