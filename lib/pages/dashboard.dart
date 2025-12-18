import 'package:flutter/material.dart';
import '../components/aqi_card.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final List<_Device> _devices = [
    _Device(
      id: 'AV501',
      name: 'Room 301',
      isOn: true,
      aqiLabel: 'Good',
      aqiValue: 75,
      aqiPercent: 0.75,
      aqiRingColor: Color(0xFF3AB54A),
      smartMode: true,
      autoAdjustFanSpeed: true,
      turnOffAutomatically: false,
      fanSpeed: FanSpeed.moderate,
    ),
    _Device(
      id: 'AV502',
      name: 'Room 302',
      isOn: false,
      aqiLabel: 'Moderate',
      aqiValue: 61,
      aqiPercent: 0.61,
      aqiRingColor: Color(0xFFFFC107),
      smartMode: false,
      autoAdjustFanSpeed: false,
      turnOffAutomatically: true,
      fanSpeed: FanSpeed.slow,
    ),
    _Device(
      id: 'AV503',
      name: 'Room 303',
      isOn: true,
      aqiLabel: 'Good',
      aqiValue: 90,
      aqiPercent: 0.90,
      aqiRingColor: Color(0xFF3AB54A),
      smartMode: true,
      autoAdjustFanSpeed: false,
      turnOffAutomatically: true,
      fanSpeed: FanSpeed.fast,
    ),
  ];

  int _selectedDeviceIndex = 0;

  _Device get _selectedDevice => _devices[_selectedDeviceIndex];

  void _updateSelectedDevice(_Device Function(_Device current) update) {
    setState(() {
      _devices[_selectedDeviceIndex] = update(_devices[_selectedDeviceIndex]);
    });
  }

  void _showAqiInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => const _AqiInfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1F2228) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF1F2228) : const Color(0xFFF3F4F6);
    final borderColor = isDark ? const Color(0xFF2B2F36) : const Color(0xFFE5E7EB);
    final titleColor = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final bodyColor = isDark ? const Color(0xFFB9C0CB) : const Color(0xFF4B5563);
    final primary = isDark ? const Color(0xFF415A77) : const Color(0xFF1B263B);
    final deviceChipBaseColor = isDark ? const Color(0xFF1B263B) : primary;
    final fanInactiveFill =
        isDark ? const Color(0xFF1B263B) : const Color(0xFF415A77);
    final fanActiveColor =
        isDark ? const Color(0xFF415A77) : const Color(0xFF1B263B);
    final fanInactiveTextColor =
        isDark ? bodyColor : Colors.white.withValues(alpha: 0.95);

    final titleMedium = theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final bodyMedium = theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
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
      // Parent (Home header) already provides horizontal padding; avoid double padding.
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AqiCard(
            background: primary,
            titleStyle: cardTitleStyle,
            bodyStyle: bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)),
            onInfo: _showAqiInfo,
            valueLabel: _selectedDevice.aqiLabel,
            aqiValue: _selectedDevice.aqiValue,
            percent: _selectedDevice.aqiPercent,
            percentText: '${(_selectedDevice.aqiPercent * 100).round()}%',
            ringColor: _selectedDevice.aqiRingColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Current Devices',
            style: sectionTitleStyle,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 74,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                for (int index = 0; index < _devices.length; index++) ...[
                  _DeviceChip(
                    device: _devices[index],
                    selected: index == _selectedDeviceIndex,
                    color: deviceChipBaseColor,
                    onSelect: () => setState(() => _selectedDeviceIndex = index),
                    onTogglePower: () {
                      setState(() {
                        _devices[index] = _devices[index].copyWith(
                          isOn: !_devices[index].isOn,
                        );
                      });
                    },
                  ),
                  if (index != _devices.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: null,
            cardColor: cardColor,
            borderColor: borderColor,
            titleStyle: null,
            child: Column(
              children: [
                _ToggleRow(
                  label: 'Smart Mode',
                  value: _selectedDevice.smartMode,
                  onChanged: (value) =>
                      _updateSelectedDevice((d) => d.copyWith(smartMode: value)),
                  labelStyle: bodyMedium.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Divider(color: borderColor, height: 18),
                if (_selectedDevice.smartMode) ...[
                  _ToggleRow(
                    label: 'Auto adjust fan speed',
                    value: _selectedDevice.autoAdjustFanSpeed,
                    onChanged: (value) => _updateSelectedDevice(
                      (d) => d.copyWith(autoAdjustFanSpeed: value),
                    ),
                    labelStyle: bodyMedium.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Divider(color: borderColor, height: 18),
                  _ToggleRow(
                    label: 'Turn off automatically',
                    value: _selectedDevice.turnOffAutomatically,
                    onChanged: (value) => _updateSelectedDevice(
                      (d) => d.copyWith(turnOffAutomatically: value),
                    ),
                    labelStyle: bodyMedium.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('Fan Speed', style: sectionTitleStyle),
          const SizedBox(height: 10),
          _SectionCard(
            title: null,
            cardColor: cardColor,
            borderColor: borderColor,
            titleStyle: null,
            child: _FanSpeedSelector(
              value: _selectedDevice.fanSpeed,
              onChanged: (value) =>
                  _updateSelectedDevice((d) => d.copyWith(fanSpeed: value)),
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              activeColor: fanActiveColor,
              inactiveFill: fanInactiveFill,
              textStyle: bodyMedium.copyWith(
                fontSize: (bodyMedium.fontSize ?? 14),
                fontWeight: FontWeight.w600,
              ),
              inactiveTextColor: fanInactiveTextColor,
              activeTextColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

enum FanSpeed { slow, moderate, fast }

class _DeviceChip extends StatelessWidget {
  final _Device device;
  final Color color;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onTogglePower;

  const _DeviceChip({
    required this.device,
    required this.color,
    required this.selected,
    required this.onSelect,
    required this.onTogglePower,
  });

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFF415A77);
    final bg = selected ? selectedColor : color;
    final borderColor =
        selected ? Colors.white.withValues(alpha: 0.7) : Colors.transparent;
    final textColor = Colors.white;
    final powerColor = device.isOn ? const Color(0xFF3AB54A) : textColor;

    return Container(
      width: 186,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: InkWell(
                onTap: onTogglePower,
                borderRadius: BorderRadius.circular(12),
                child: Icon(
                  Icons.power_settings_new,
                  color: powerColor,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${device.id}\n${device.name}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final Color cardColor;
  final Color borderColor;
  final TextStyle? titleStyle;

  const _SectionCard({
    required this.title,
    required this.child,
    required this.cardColor,
    required this.borderColor,
    required this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title!.isNotEmpty) ...[
            Text(title!, style: titleStyle),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _AqiInfoDialog extends StatelessWidget {
  const _AqiInfoDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1F2228) : Colors.white;
    final titleColor = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final bodyColor = isDark ? const Color(0xFFB9C0CB) : const Color(0xFF4B5563);
    final primary = isDark ? const Color(0xFF415A77) : const Color(0xFF1B263B);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SizedBox(
          width: 340,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    textAlign: TextAlign.left,
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: bodyColor,
                        height: 1.4,
                        fontSize:
                            (theme.textTheme.bodyMedium?.fontSize ?? 14) - 1,
                      ),
                      children: [
                        TextSpan(
                          text: 'Air Quality Index (AQI)\n\n',
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(
                          text:
                              'Indicates air quality on a 0–200 AQI scale, where 0 is excellent and 200 is very unhealthy. Higher values mean cleaner air.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 140,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Device {
  final String id;
  final String name;
  final bool isOn;
  final String aqiLabel;
  final int aqiValue;
  final double aqiPercent;
  final Color aqiRingColor;
  final bool smartMode;
  final bool autoAdjustFanSpeed;
  final bool turnOffAutomatically;
  final FanSpeed fanSpeed;

  const _Device({
    required this.id,
    required this.name,
    required this.isOn,
    required this.aqiLabel,
    required this.aqiValue,
    required this.aqiPercent,
    required this.aqiRingColor,
    required this.smartMode,
    required this.autoAdjustFanSpeed,
    required this.turnOffAutomatically,
    required this.fanSpeed,
  });

  _Device copyWith({
    String? id,
    String? name,
    bool? isOn,
    String? aqiLabel,
    int? aqiValue,
    double? aqiPercent,
    Color? aqiRingColor,
    bool? smartMode,
    bool? autoAdjustFanSpeed,
    bool? turnOffAutomatically,
    FanSpeed? fanSpeed,
  }) =>
      _Device(
        id: id ?? this.id,
        name: name ?? this.name,
        isOn: isOn ?? this.isOn,
        aqiLabel: aqiLabel ?? this.aqiLabel,
        aqiValue: aqiValue ?? this.aqiValue,
        aqiPercent: aqiPercent ?? this.aqiPercent,
        aqiRingColor: aqiRingColor ?? this.aqiRingColor,
        smartMode: smartMode ?? this.smartMode,
        autoAdjustFanSpeed: autoAdjustFanSpeed ?? this.autoAdjustFanSpeed,
        turnOffAutomatically: turnOffAutomatically ?? this.turnOffAutomatically,
        fanSpeed: fanSpeed ?? this.fanSpeed,
      );
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final TextStyle labelStyle;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        Transform.scale(
          scale: 1.05,
          child: Switch.adaptive(value: value, onChanged: onChanged),
        ),
      ],
    );
  }
}

class _FanSpeedSelector extends StatelessWidget {
  final FanSpeed value;
  final ValueChanged<FanSpeed> onChanged;
  final Color surfaceColor;
  final Color borderColor;
  final Color activeColor;
  final Color inactiveFill;
  final TextStyle textStyle;
  final Color inactiveTextColor;
  final Color activeTextColor;

  const _FanSpeedSelector({
    required this.value,
    required this.onChanged,
    required this.surfaceColor,
    required this.borderColor,
    required this.activeColor,
    required this.inactiveFill,
    required this.textStyle,
    required this.inactiveTextColor,
    required this.activeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'Slow',
              selected: value == FanSpeed.slow,
              onTap: () => onChanged(FanSpeed.slow),
              activeColor: activeColor,
              inactiveFill: inactiveFill,
              inactiveTextColor: inactiveTextColor,
              activeTextColor: activeTextColor,
              textStyle: textStyle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _Segment(
              label: 'Moderate',
              selected: value == FanSpeed.moderate,
              onTap: () => onChanged(FanSpeed.moderate),
              activeColor: activeColor,
              inactiveFill: inactiveFill,
              inactiveTextColor: inactiveTextColor,
              activeTextColor: activeTextColor,
              textStyle: textStyle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _Segment(
              label: 'Fast',
              selected: value == FanSpeed.fast,
              onTap: () => onChanged(FanSpeed.fast),
              activeColor: activeColor,
              inactiveFill: inactiveFill,
              inactiveTextColor: inactiveTextColor,
              activeTextColor: activeTextColor,
              textStyle: textStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveFill;
  final Color inactiveTextColor;
  final Color activeTextColor;
  final TextStyle textStyle;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.activeColor,
    required this.inactiveFill,
    required this.inactiveTextColor,
    required this.activeTextColor,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: selected ? activeColor : inactiveFill,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: textStyle.copyWith(
            color: selected ? activeTextColor : inactiveTextColor,
          ),
        ),
      ),
    );
  }
}
