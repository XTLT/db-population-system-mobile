import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../api/statistics_api.dart';
import '../statistics/trend_chart_page.dart';
import '../statistics/distribution_chart_page.dart';
import '../statistics/radar_chart_page.dart';
import '../report/custom_report_list_page.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _personStats;
  Map<String, dynamic>? _studentStats;
  Map<String, dynamic>? _landSubsidyStats;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStatistics();
  }
  
  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      
      final results = await Future.wait([
        StatisticsApi.getPersonStatistics(),
        StatisticsApi.getStudentStatistics(),
        StatisticsApi.getLandSubsidyStatistics(),
      ]);

      setState(() {
        _personStats = results[0];
        _studentStats = results[1];
        _landSubsidyStats = results[2];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载统计数据失败: $e')),
        );
      }
    }
  }

  void _showChartOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.show_chart),
                title: const Text('趋势分析'),
                subtitle: const Text('查看人员增减趋势'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrendChartPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.pie_chart),
                title: const Text('分布分析'),
                subtitle: const Text('查看人口分布情况'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DistributionChartPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.radar),
                title: const Text('多维对比'),
                subtitle: const Text('多维度数据对比分析'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RadarChartPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('自定义报表'),
                subtitle: const Text('创建和管理自定义报表'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomReportListPage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据统计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showChartOptions,
            tooltip: '图表分析',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStatistics,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '人口统计'),
            Tab(text: '学生统计'),
            Tab(text: '补贴统计'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _PersonStatsTab(stats: _personStats),
                _StudentStatsTab(stats: _studentStats),
                _SubsidyStatsTab(personStats: _personStats, landSubsidyStats: _landSubsidyStats),
              ],
            ),
    );
  }
}


class _PersonStatsTab extends StatelessWidget {
  final Map<String, dynamic>? stats;
  
  const _PersonStatsTab({this.stats});
  
  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const Center(child: Text('暂无数据'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          _buildSummaryCard(),
          const SizedBox(height: 24),
          
          
          _buildSection('社会保障', _buildSocialSecurityStats()),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard() {
    final totalCount = stats?['total'] ?? 0;
    final aliveCount = stats?['alive'] ?? 0;
    final deadCount = stats?['dead'] ?? 0;
    final migratedCount = stats?['migrated'] ?? 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('总人数', totalCount.toString(), Colors.blue),
                _buildStatItem('在世', aliveCount.toString(), Colors.green),
                _buildStatItem('已死亡', deadCount.toString(), Colors.grey),
                _buildStatItem('迁移', migratedCount.toString(), Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
  
  Widget _buildGenderChart() {
    final maleCount = (stats?['male_count'] ?? 0).toDouble();
    final femaleCount = (stats?['female_count'] ?? 0).toDouble();
    
    if (maleCount == 0 && femaleCount == 0) {
      return const Center(child: Text('暂无数据'));
    }
    
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              value: maleCount,
              title: '男\n${maleCount.toInt()}',
              color: Colors.lightBlue,
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              value: femaleCount,
              title: '女\n${femaleCount.toInt()}',
              color: Colors.pink,
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAgeChart() {
    final ageGroups = stats?['age_groups'] as Map<String, dynamic>? ?? {};
    
    if (ageGroups.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }
    
    final barGroups = <BarChartGroupData>[];
    final labels = <String>[];
    final colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.red.shade300,
      Colors.purple.shade300,
    ];
    
    final sortedKeys = ageGroups.keys.toList()..sort();
    
    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final count = (ageGroups[key] ?? 0).toDouble();
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count,
              color: colors[i % colors.length],
              width: 40,
            ),
          ],
        ),
      );
      
      labels.add(key);
    }
    
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= labels.length) {
                    return const Text('');
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[value.toInt()],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
          gridData: const FlGridData(show: true),
        ),
      ),
    );
  }
  
  Widget _buildSocialSecurityStats() {
    final disabilityCount = stats?['disability'] ?? 0;
    final dibaoCount = stats?['dibao'] ?? 0;
    final tekunCount = stats?['tekun'] ?? 0;
    final tekunTypeDistribution = stats?['tekun_type_distribution'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow('残疾人员', disabilityCount, Colors.red),
            const Divider(),
            _buildStatRow('低保人员', dibaoCount, Colors.orange),
            const Divider(),
            _buildStatRow('特困供养人员', tekunCount, Colors.purple),
            if (tekunTypeDistribution.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Column(
                  children: tekunTypeDistribution.entries.map((entry) {
                    final colors = {
                      '集中供养': Colors.indigo,
                      '散居特困': Colors.teal,
                    };
                    return _buildStatRow(
                      '  ${entry.key}',
                      entry.value as int,
                      colors[entry.key] ?? Colors.grey,
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


class _StudentStatsTab extends StatelessWidget {
  final Map<String, dynamic>? stats;
  
  const _StudentStatsTab({this.stats});
  
  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const Center(child: Text('暂无数据'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          _buildStudentSummaryCard(),
          const SizedBox(height: 24),
          
          
          _buildSection('年级分布', _buildGradeDistribution()),
          const SizedBox(height: 24),
          
          
          _buildSection('学生状态', _buildStudentStatus()),
        ],
      ),
    );
  }
  
  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
  
  Widget _buildStudentSummaryCard() {
    final totalCount = stats?['total'] ?? 0;
    final leftBehindCount = stats?['left_behind'] ?? 0;
    final graduatedCount = stats?['graduated'] ?? 0;
    final studyingCount = stats?['studying'] ?? 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('学生总数', totalCount.toString(), Colors.blue),
                _buildStatItem('在读学生', studyingCount.toString(), Colors.green),
                _buildStatItem('留守儿童', leftBehindCount.toString(), Colors.orange),
              ],
            ),
            if (graduatedCount > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('已毕业', graduatedCount.toString(), Colors.purple),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildGradeDistribution() {
    final gradeDistribution = stats?['grade_distribution'] as Map<String, dynamic>? ?? {};
    
    if (gradeDistribution.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }
    
    
    final typeCount = <String, int>{};
    gradeDistribution.forEach((key, value) {
      if (key.startsWith('K')) {
        typeCount['幼儿园'] = (typeCount['幼儿园'] ?? 0) + (value as int);
      } else if (key.startsWith('G') && int.parse(key.substring(1)) <= 6) {
        typeCount['小学'] = (typeCount['小学'] ?? 0) + (value as int);
      } else if (key.startsWith('G') && int.parse(key.substring(1)) > 6 && int.parse(key.substring(1)) <= 9) {
        typeCount['初中'] = (typeCount['初中'] ?? 0) + (value as int);
      } else if (key.startsWith('G') && int.parse(key.substring(1)) > 9) {
        typeCount['高中'] = (typeCount['高中'] ?? 0) + (value as int);
      } else if (key.startsWith('U')) {
        typeCount['大学'] = (typeCount['大学'] ?? 0) + (value as int);
      } else if (key == 'GRADUATED') {
        typeCount['已毕业'] = (typeCount['已毕业'] ?? 0) + (value as int);
      } else {
        typeCount['其他'] = (typeCount['其他'] ?? 0) + (value as int);
      }
    });
    
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: typeCount.entries.map((entry) {
            final colors = [
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.red,
              Colors.purple,
              Colors.teal,
              Colors.pink,
            ];
            final index = typeCount.keys.toList().indexOf(entry.key);
            
            return PieChartSectionData(
              value: entry.value.toDouble(),
              title: '${entry.key}\n${entry.value}',
              color: colors[index % colors.length],
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildStudentStatus() {
    final statusDistribution = stats?['status_distribution'] as Map<String, dynamic>? ?? {};
    
    if (statusDistribution.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: statusDistribution.entries.map((entry) {
            final colors = [
              Colors.blue,
              Colors.orange,
              Colors.green,
              Colors.red,
              Colors.purple,
              Colors.grey,
            ];
            final index = statusDistribution.keys.toList().indexOf(entry.key);
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(entry.key),
                    ],
                  ),
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}


class _SubsidyStatsTab extends StatelessWidget {
  final Map<String, dynamic>? personStats;
  final Map<String, dynamic>? landSubsidyStats;

  const _SubsidyStatsTab({this.personStats, this.landSubsidyStats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          _buildSection('地力补贴统计', _buildLandSubsidyStats()),
          const SizedBox(height: 24),

          
          _buildSection('脱贫户/监测户', _buildPoorStats()),
          const SizedBox(height: 24),

          
          _buildSection('残疾等级分布', _buildDisabilityLevelChart()),
          const SizedBox(height: 24),

          
          _buildSection('土地面积统计', _buildLandAreaStats()),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildLandSubsidyStats() {
    if (landSubsidyStats == null) {
      return const Center(child: Text('暂无数据'));
    }

    final totalCount = landSubsidyStats?['total_count'] ?? 0;
    final totalCertifiedArea = landSubsidyStats?['total_certified_area'] ?? 0;
    final totalSubsidyArea = landSubsidyStats?['total_subsidy_area'] ?? 0;
    final totalAmount = landSubsidyStats?['total_amount'] ?? 0;
    final avgSubsidyAmount = landSubsidyStats?['avg_subsidy_amount'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('记录数', totalCount.toString(), Colors.purple),
                _buildStatItem('认证面积(亩)', totalCertifiedArea.toString(), Colors.green),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('补贴面积(亩)', totalSubsidyArea.toString(), Colors.blue),
                _buildStatItem('补贴总额(元)', totalAmount.toString(), Colors.red),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem('人均补贴(元)', avgSubsidyAmount.toString(), Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPoorStats() {
    final poorTypeDistribution = personStats?['poor_type_distribution'] as Map<String, dynamic>? ?? {};
    final poorTypePersonCount = personStats?['poor_type_person_count'] as Map<String, dynamic>? ?? {};

    if (poorTypeDistribution.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: poorTypeDistribution.entries.map((entry) {
            final colors = {
              '脱贫户': Colors.green,
              '脱贫不稳定户': Colors.teal,
              '边缘易致贫户': Colors.orange,
              '突发严重困难户': Colors.red,
              '监测户': Colors.orange,
              '其他': Colors.blue,
            };

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colors[entry.key] ?? Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(entry.key),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${entry.value} 户',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if ((poorTypePersonCount[entry.key] ?? 0) > 0)
                        Text(
                          '${poorTypePersonCount[entry.key]} 人',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDisabilityLevelChart() {
    final disLevelDistribution = personStats?['dis_level_distribution'] as Map<String, dynamic>? ?? {};

    if (disLevelDistribution.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    
    final order = ['一级', '二级', '三级', '四级'];
    final sortedLabels = List<String>.from(disLevelDistribution.keys.toList());
    sortedLabels.sort((a, b) {
      final aIndex = order.indexOf(a);
      final bIndex = order.indexOf(b);
      if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });

    
    final gradientColors = [
      [Colors.red.shade400, Colors.red.shade600],      
      [Colors.orange.shade400, Colors.orange.shade600], 
      [Colors.amber.shade400, Colors.amber.shade600],   
      [Colors.green.shade400, Colors.green.shade600],   
    ];

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < sortedLabels.length; i++) {
      final count = (disLevelDistribution[sortedLabels[i]] ?? 0).toDouble();
      final colorIndex = order.indexOf(sortedLabels[i]);
      final colorPair = gradientColors[colorIndex >= 0 ? colorIndex : i % gradientColors.length];

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count,
              gradient: LinearGradient(
                colors: colorPair,
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: disLevelDistribution.values.map((v) => (v as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
                color: Colors.grey.shade200,
              ),
            ),
          ],
        ),
      );
    }

    
    final total = disLevelDistribution.values.fold<int>(0, (sum, v) => sum + (v as int));

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= sortedLabels.length) {
                        return const Text('');
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          sortedLabels[value.toInt()],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                    reservedSize: 36,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value % 10 != 0) {
                        return const Text('');
                      }
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 10,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  );
                },
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final label = sortedLabels[groupIndex];
                    final count = disLevelDistribution[label] ?? 0;
                    final percent = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
                    return BarTooltipItem(
                      '$label: $count人 ($percent%)',
                      TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: sortedLabels.asMap().entries.map((entry) {
            final colorIndex = order.indexOf(entry.value);
            final colorPair = gradientColors[colorIndex >= 0 ? colorIndex : entry.key % gradientColors.length];
            final count = disLevelDistribution[entry.value] ?? 0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colorPair,
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${entry.value}: $count人',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLandAreaStats() {
    final totalLandArea = personStats?['total_land_area'] ?? 0;
    final avgLandArea = personStats?['avg_land_area'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      totalLandArea.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '总面积（亩）',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      avgLandArea.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '人均（亩）',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
