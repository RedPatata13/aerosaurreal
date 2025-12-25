import '/../models/device.dart';

class DeviceManagementArgs {
  final String uid;
  final List<Device> devices;
  final void Function(List<Device>) onDevicesChanged;

  DeviceManagementArgs({
    required this.uid,
    required this.devices,
    required this.onDevicesChanged,
  });
}
