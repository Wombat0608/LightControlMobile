import 'package:flutter/material.dart';
import '../../core/models/device.dart';
import '../../core/models/relays.dart';
import '../../core/models/dimmers.dart';

class DeviceControlPage extends StatefulWidget {
  final Device device;

  const DeviceControlPage({super.key, required this.device});

  @override
  State<DeviceControlPage> createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage> {
  late Device _device;

  @override
  void initState() {
    super.initState();
    _device = widget.device;
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: Text(_device.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: настройки устройства
            },
          ),
        ],
      ),
      body: isLandscape
          ? Row(
              children: [
                Expanded(flex: 1, child: _buildRelaysSection()),
                VerticalDivider(color: Colors.grey.shade300),
                Expanded(flex: 1, child: _buildDimmersSection()),
              ],
            )
          : Column(
              children: [
                Expanded(flex: 4, child: _buildRelaysSection()),
                const Divider(height: 1),
                Expanded(flex: 4, child: _buildDimmersSection()),
              ],
            ),
    );
  }

  Widget _buildRelaysSection() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          title: Text(
            'Реле (${_device.relays.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(4),
            itemCount: _device.relays.length,
            itemBuilder: (context, index) {
              final relay = _device.relays[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildRelayTile(relay),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelayTile(Relay relay) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    relay.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '#${relay.index}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditRelayNameDialog(relay);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Редактировать имя'),
                    ],
                  ),
                ),
              ],
            ),
            Switch(
              value: relay.state,
              onChanged: (_) {
                setState(() {
                  relay.state = !relay.state;
                });
              },
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimmersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          title: Text(
            'Диммеры (${_device.dimmers.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(4),
            itemCount: _device.dimmers.length,
            itemBuilder: (context, index) {
              final dimmer = _device.dimmers[index];
              return _buildDimmerTile(dimmer);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDimmerTile(Dimmer dimmer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dimmer.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                // Меню для диммера
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditDimmerNameDialog(dimmer);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Редактировать имя'),
                        ],
                      ),
                    ),
                  ],
                ),
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
                    onChanged: (value) {
                      setState(() {
                        dimmer.brightness = value.round();
                      });
                    },
                  ),
                ),
                const Icon(Icons.brightness_high, size: 16),
                const SizedBox(width: 8),
                Text('${dimmer.brightness}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Диалог редактирования имени реле
  void _showEditRelayNameDialog(Relay relay) {
    final controller = TextEditingController(text: relay.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Обязательно для клавиатуры
      enableDrag: false, // Отключаем свайп, чтобы случайно не закрыть
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  reverse:
                      true, // Позволяет видеть ввод при появлении клавиатуры
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ручка для свайпа (опционально)
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Редактировать реле',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Имя реле',
                          hintText: 'Введите новое имя',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.edit),
                        ),
                        onSubmitted: (_) {
                          if (controller.text.isNotEmpty) {
                            setState(() {
                              relay.name = controller.text;
                            });
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Отмена'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (controller.text.isNotEmpty) {
                                  setState(() {
                                    relay.name = controller.text;
                                  });
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Сохранить'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Диалог редактирования имени диммера
  void _showEditDimmerNameDialog(Dimmer dimmer) {
    final controller = TextEditingController(text: dimmer.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Обязательно для клавиатуры
      enableDrag: false, // Отключаем свайп, чтобы случайно не закрыть
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  reverse:
                      true, // Позволяет видеть ввод при появлении клавиатуры
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ручка для свайпа (опционально)
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Редактировать реле',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Имя реле',
                          hintText: 'Введите новое имя',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.edit),
                        ),
                        onSubmitted: (_) {
                          if (controller.text.isNotEmpty) {
                            setState(() {
                              dimmer.name = controller.text;
                            });
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Отмена'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (controller.text.isNotEmpty) {
                                  setState(() {
                                    dimmer.name = controller.text;
                                  });
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Сохранить'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
