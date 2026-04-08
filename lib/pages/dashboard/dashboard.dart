import 'package:flutter/material.dart';

import '../../components/offline_status_banner.dart';
import '../../components/tutorial_showcase.dart';
import '/../components/aqi_card.dart';
import '/../models/device.dart';
import '../home/dialogs/info_dialog.dart';
import 'widgets/device_chip.dart';
import 'widgets/fan_speed_selector.dart';
import 'widgets/section_card.dart';
import 'widgets/toggle_row.dart';

class Dashboard extends StatelessWidget {
  final List<Device> devices;
  final int selectedDeviceIndex;
  final ValueChanged<int> onSelectDevice;
  final ValueChanged<Device> onUpdateDevice;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String deviceId, bool isOn) onTogglePower;
  final Future<void> Function(String deviceId, Map<String, dynamic> patch)
  onControlChanged;
  final GlobalKey? airQualityKey;
  final GlobalKey? devicesKey;
  final GlobalKey? smartModeKey;
  final GlobalKey? fanSpeedKey;

  const Dashboard({
    super.key,
    required this.devices,
    required this.selectedDeviceIndex,
    required this.onSelectDevice,
    required this.onUpdateDevice,
    required this.onRefresh,
    required this.onTogglePower,
    required this.onControlChanged,
    this.airQualityKey,
    this.devicesKey,
    this.smartModeKey,
    this.fanSpeedKey,
  });

  Widget _wrapShowcase({
    required Widget child,
    required GlobalKey? showcaseKey,
    required String title,
    required String description,
  }) {
    return wrapTutorialShowcase(
      child: child,
      showcaseKey: showcaseKey,
      title: title,
      description: description,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) return const SizedBox.shrink();

    final selectedDevice =
        devices[selectedDeviceIndex.clamp(0, devices.length - 1)];
    final isSelectedDeviceOn = selectedDevice.isOn;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OfflineStatusBanner(device: selectedDevice),
            _wrapShowcase(
              showcaseKey: airQualityKey,
              title: 'Air Quality Summary',
              description:
                  'This card gives a quick view of the current AQI so you can see if the selected space is clean, moderate, or unhealthy.',
              child: AqiCard(
                background: theme.colorScheme.primary,
                titleStyle: (theme.textTheme.titleMedium ?? const TextStyle())
                    .copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize:
                          (theme.textTheme.titleMedium?.fontSize ?? 16) + 1,
                      color: theme.colorScheme.onPrimary,
                    ),
                bodyStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
                    .copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                onInfo: () {
                  showInfoDialog(
                    context,
                    title: 'AQI',
                    body:
                        'Air Quality Index (AQI) indicates overall air quality on a 0-200 scale, where 0 is excellent and 200 is very unhealthy.',
                  );
                },
                valueLabel: selectedDevice.aqiLabel,
                aqiValue: selectedDevice.aqiValue,
                percent: selectedDevice.aqiPercent,
                percentText: '${(selectedDevice.aqiPercent * 100).round()}%',
                ringColor: selectedDevice.aqiRingColor,
              ),
            ),
            const SizedBox(height: 16),
            _wrapShowcase(
              showcaseKey: devicesKey,
              title: 'Choose a device',
              description:
                  'Switch between your registered purifiers here. Tapping the power icon quickly turns the selected device on or off.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Devices',
                    style: (theme.textTheme.titleMedium ?? const TextStyle())
                        .copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize:
                              (theme.textTheme.titleMedium?.fontSize ?? 16) + 1,
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
                              onTogglePower(device.id, !device.isOn),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _wrapShowcase(
              showcaseKey: smartModeKey,
              title: 'Smart controls',
              description:
                  'Smart Mode helps automate purifier behavior. You can let the app adjust fan speed or turn the unit off automatically when conditions allow.',
              child: SectionCard(
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
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: isSelectedDeviceOn ? 1 : 0.55,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                      onChanged: isSelectedDeviceOn
                          ? (value) => onControlChanged(selectedDevice.id, {
                              "smartMode": value,
                            })
                          : null,
                    ),
                    Divider(color: theme.dividerColor),
                    if (selectedDevice.smartMode) ...[
                      ToggleRow(
                        label: 'Auto adjust fan speed',
                        value: selectedDevice.autoAdjustFanSpeed,
                        labelStyle:
                            (theme.textTheme.bodyMedium ?? const TextStyle())
                                .copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: isSelectedDeviceOn ? 1 : 0.55,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                        onChanged: isSelectedDeviceOn
                            ? (value) => onControlChanged(selectedDevice.id, {
                                "autoAdjust": value,
                              })
                            : null,
                      ),
                      Divider(color: theme.dividerColor),
                      ToggleRow(
                        label: 'Turn off automatically',
                        value: selectedDevice.turnOffAutomatically,
                        labelStyle:
                            (theme.textTheme.bodyMedium ?? const TextStyle())
                                .copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: isSelectedDeviceOn ? 1 : 0.55,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                        onChanged: isSelectedDeviceOn
                            ? (value) => onControlChanged(selectedDevice.id, {
                                "autoOff": value,
                              })
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _wrapShowcase(
              showcaseKey: fanSpeedKey,
              title: 'Manual fan speed',
              description:
                  'Choose Slow, Moderate, or Fast to control airflow yourself. When Smart Mode is on, the highlighted button shows the speed selected by the system.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fan Speed',
                    style: (theme.textTheme.titleMedium ?? const TextStyle())
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (!isSelectedDeviceOn) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Turn the device on to change smart mode and fan speed.',
                      style: (theme.textTheme.bodySmall ?? const TextStyle())
                          .copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ] else if (selectedDevice.smartMode) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Smart mode is active. The highlighted button shows the current fan speed.',
                      style: (theme.textTheme.bodySmall ?? const TextStyle())
                          .copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  SectionCard(
                    cardColor:
                        theme.cardTheme.color ?? theme.colorScheme.surface,
                    borderColor: theme.dividerColor,
                    child: FanSpeedSelector(
                      value: selectedDevice.fanSpeed,
                      onChanged: isSelectedDeviceOn
                          ? (value) => onControlChanged(selectedDevice.id, {
                              "fanSpeed": value.toApi(),
                            })
                          : null,
                      surfaceColor: theme.colorScheme.surface,
                      borderColor: theme.dividerColor,
                      activeColor: theme.colorScheme.primary,
                      inactiveFill: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      inactiveTextColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
                      activeTextColor: theme.colorScheme.onPrimary,
                      textStyle:
                          (theme.textTheme.bodyMedium ?? const TextStyle())
                              .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
