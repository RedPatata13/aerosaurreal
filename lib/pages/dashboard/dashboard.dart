import 'package:flutter/material.dart';
import '/../components/aqi_card.dart';
import '../home/dialogs/info_dialog.dart';
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
  final Future<void> Function() onRefresh;

  const Dashboard({
    super.key,
    required this.devices,
    required this.selectedDeviceIndex,
    required this.onSelectDevice,
    required this.onUpdateDevice,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) return const SizedBox.shrink();

    final selectedDevice =
        devices[selectedDeviceIndex.clamp(0, devices.length - 1)];
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AQI Card
            AqiCard(
              background: theme.colorScheme.primary,
              titleStyle: (theme.textTheme.titleMedium ?? const TextStyle())
                  .copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) + 1,
                    color: theme.colorScheme.onPrimary,
                  ),
              bodyStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
                  .copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.9),
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
            Text(
              'Current Devices',
              style: (theme.textTheme.titleMedium ?? const TextStyle())
                  .copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) + 1,
                    color: theme.colorScheme.onSurface,
                  ),
            ),
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
                    selected: index == selectedDeviceIndex,
                    color: theme.colorScheme.primary,
                    onSelect: () => onSelectDevice(index),
                    onTogglePower: () =>
                        onUpdateDevice(device.copyWith(isOn: !device.isOn)),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            SectionCard(
              cardColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: theme.dividerColor,
              child: Column(
                children: [
                  ToggleRow(
                    label: 'Smart Mode',
                    value: selectedDevice.smartMode,
                    labelStyle:
                        (theme.textTheme.bodyMedium ?? const TextStyle())
                            .copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                    onChanged: (value) => onUpdateDevice(
                      selectedDevice.copyWith(smartMode: value),
                    ),
                  ),
                  Divider(color: theme.dividerColor, height: 18),
                  if (selectedDevice.smartMode) ...[
                    ToggleRow(
                      label: 'Auto adjust fan speed',
                      value: selectedDevice.autoAdjustFanSpeed,
                      labelStyle:
                          (theme.textTheme.bodyMedium ?? const TextStyle())
                              .copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                      onChanged: (value) => onUpdateDevice(
                        selectedDevice.copyWith(autoAdjustFanSpeed: value),
                      ),
                    ),
                    Divider(color: theme.dividerColor, height: 18),
                    ToggleRow(
                      label: 'Turn off automatically',
                      value: selectedDevice.turnOffAutomatically,
                      labelStyle:
                          (theme.textTheme.bodyMedium ?? const TextStyle())
                              .copyWith(
                                color: theme.colorScheme.onSurface,
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
            Text(
              'Fan Speed',
              style: (theme.textTheme.titleMedium ?? const TextStyle())
                  .copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) + 1,
                    color: theme.colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 10),

            SectionCard(
              cardColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: theme.dividerColor,
              child: FanSpeedSelector(
                value: selectedDevice.fanSpeed,
                onChanged: (value) =>
                    onUpdateDevice(selectedDevice.copyWith(fanSpeed: value)),
                surfaceColor: theme.colorScheme.surface,
                borderColor: theme.dividerColor,
                activeColor: theme.colorScheme.primary,
                inactiveFill: theme.colorScheme.primary.withOpacity(0.1),
                inactiveTextColor:
                    (theme.textTheme.bodyMedium ?? const TextStyle()).color
                        ?.withOpacity(0.7) ??
                    theme.colorScheme.onSurface.withOpacity(0.7),
                activeTextColor: theme.colorScheme.onPrimary,
                textStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
