import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../themes/app_theme.dart';


class ThemeCustomizePage extends StatefulWidget {
  const ThemeCustomizePage({super.key});

  @override
  State<ThemeCustomizePage> createState() => _ThemeCustomizePageState();
}

class _ThemeCustomizePageState extends State<ThemeCustomizePage> {
  late Color _selectedColor;
  late double _textScaleFactor;

  @override
  void initState() {
    super.initState();
    final themeProvider = context.read<ThemeProvider>();
    _selectedColor = themeProvider.seedColor;
    _textScaleFactor = themeProvider.textScaleFactor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主题定制'),
        actions: [
          TextButton(
            onPressed: _resetToDefault,
            child: const Text('重置'),
          ),
        ],
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              
              _buildSectionTitle('主题色'),
              const SizedBox(height: 12),
              _buildColorSelector(themeProvider),
              const SizedBox(height: 24),
              
              
              _buildSectionTitle('字体大小'),
              const SizedBox(height: 12),
              _buildTextScaleSlider(themeProvider),
              const SizedBox(height: 24),
              
              
              _buildSectionTitle('预览'),
              const SizedBox(height: 12),
              _buildPreview(themeProvider),
              const SizedBox(height: 24),
              
              
              ElevatedButton(
                onPressed: () => _applyChanges(themeProvider),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('应用设置'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildColorSelector(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppTheme.presetColors.map((color) {
            final isSelected = _selectedColor.value == color.value;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        
        
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          title: const Text('自定义颜色'),
          subtitle: Text(
            '当前: #${_selectedColor.value.toRadixString(16).toUpperCase().padLeft(8, '0')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.color_lens),
          onTap: _showColorPicker,
        ),
      ],
    );
  }

  Widget _buildTextScaleSlider(ThemeProvider themeProvider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('字体大小'),
            Text(
              '${(_textScaleFactor * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _textScaleFactor,
          min: 0.8,
          max: 1.4,
          divisions: 6,
          onChanged: (value) {
            setState(() {
              _textScaleFactor = value;
            });
          },
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('小', style: TextStyle(fontSize: 12)),
            Text('大', style: TextStyle(fontSize: 20)),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview(ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: _selectedColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '张三',
                        style: TextStyle(
                          fontSize: 16 * _textScaleFactor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '身份证: 110101199001011234',
                        style: TextStyle(
                          fontSize: 14 * _textScaleFactor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedColor,
              ),
              child: const Text('查看详情'),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择颜色'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _applyChanges(ThemeProvider themeProvider) async {
    await themeProvider.setSeedColor(_selectedColor);
    await themeProvider.setTextScaleFactor(_textScaleFactor);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('主题设置已应用')),
      );
    }
  }

  void _resetToDefault() async {
    setState(() {
      _selectedColor = Colors.blue;
      _textScaleFactor = 1.0;
    });
    
    final themeProvider = context.read<ThemeProvider>();
    await themeProvider.reset();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已重置为默认设置')),
      );
    }
  }
}


class ColorPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final double pickerAreaHeightPercent;

  const ColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
    this.pickerAreaHeightPercent = 0.8,
  });

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.pickerColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _currentColor,
                _currentColor.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            onPanUpdate: (details) {
              
              final hue = (details.localPosition.dx / 300 * 360).clamp(0.0, 360.0);
              final saturation = (1 - details.localPosition.dy / 200).clamp(0.0, 1.0);
              setState(() {
                _currentColor = HSVColor.fromAHSV(1.0, hue, saturation, 1.0).toColor();
              });
              widget.onColorChanged(_currentColor);
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickColor(Colors.red),
            _buildQuickColor(Colors.green),
            _buildQuickColor(Colors.blue),
            _buildQuickColor(Colors.yellow),
            _buildQuickColor(Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickColor(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentColor = color;
        });
        widget.onColorChanged(color);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      ),
    );
  }
}
