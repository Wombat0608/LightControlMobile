import 'package:flutter/material.dart';
import 'package:light_control/screens/device/device_page.dart';
import 'package:light_control/screens/device/devices_list_widget.dart';
import '../../core/models/device.dart';
import '../../core/models/relays.dart';
import '../../core/models/dimmers.dart';
import '../device/device_control_panel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Device? _selectedDevice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // Верхняя панель - список устройств (40% экрана)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    dense: true,
                    title: Text(
                      'Устройства',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      color: Colors.grey,
                      tooltip: 'Добавить устройство',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DevicePage()),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: DeviceList(
                      onDeviceSelected: (device) {
                        setState(() {
                          _selectedDevice = device;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Нижняя панель - управление выбранным устройством (60% экрана)
          Expanded(
            flex: 7,
            child: _selectedDevice == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_upward, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Выберите устройство из списка выше',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _buildControlPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Список реле и диммеров
        ListTile(
          dense: true,
          title: Text('Реле', style: Theme.of(context).textTheme.titleMedium),
        ),
        const Divider(height: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: ListView(
              children: [
                // Секция реле
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 колонки для компактности
                    childAspectRatio: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: _selectedDevice!.relays.length,
                  itemBuilder: (context, index) {
                    final relay = _selectedDevice!.relays[index];
                    return _buildRelayTile(relay);
                  },
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        ListTile(
          dense: true,
          title: Text(
            'Диммеры',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ListView(
              children: [
                ..._selectedDevice!.dimmers.map(
                  (dimmer) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _buildDimmerTile(dimmer),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRelayTile(Relay relay) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(),
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleRelayToggle(relay),
        borderRadius: BorderRadius.circular(0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Row(
            children: [

              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      relay.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '#${relay.index}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: relay.state,
                onChanged: (_) => _handleRelayToggle(relay),
                activeColor: Colors.green,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDimmerTile(Dimmer dimmer) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 8),
                Text(
                  dimmer.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${dimmer.index}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.brightness_low, size: 16),
                Expanded(
                  child: Slider(
                    value: dimmer.brightness.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${dimmer.brightness}%',
                    onChanged: (value) {
                      _handleDimmerChange(dimmer, value.round());
                    },
                  ),
                ),
                const Icon(Icons.brightness_high, size: 16),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${dimmer.brightness}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleRelayToggle(Relay relay) {
    setState(() {
      relay.state = !relay.state;
    });
    print('Toggle relay: ${relay.name} (index: ${relay.index})');
  }

  void _handleDimmerChange(Dimmer dimmer, int brightness) {
    setState(() {
      dimmer.brightness = brightness;
    });
    print('Dimmer: ${dimmer.name} set to $brightness%');
  }

  @override
  void dispose() {
    // Очистка ресурсов если нужно
    super.dispose();
  }
}
