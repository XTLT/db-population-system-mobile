import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../api/api_client.dart';
import '../../api/statistics_api.dart';
import '../statistics/trend_chart_page.dart';
import '../statistics/distribution_chart_page.dart';
import '../statistics/radar_chart_page.dart';
import '../report/custom_report_list_page.dart';
import '../person/filtered_person_list_page.dart';
import '../subsidy/monthly_payment_query_page.dart';
import '../subsidy/dibao_query_page.dart';
import '../subsidy/tekun_query_page.dart';

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

    Map<String, dynamic>? personStats;
    Map<String, dynamic>? studentStats;
    Map<String, dynamic>? landSubsidyStats;
    String? studentError;

    try {
      personStats = await StatisticsApi.getPersonStatistics();
    } catch (e) {
      debugPrint('Person stats failed: $e');
    }

    try {
      studentStats = await StatisticsApi.getStudentStatistics();
    } catch (e) {
      debugPrint('Student stats failed: $e');
      studentError = e.toString();
    }

    try {
      landSubsidyStats = await StatisticsApi.getLandSubsidyStatistics();
    } catch (e) {
      debugPrint('Land subsidy stats failed: $e');
    }

    if (mounted) {
      setState(() {
        _personStats = personStats;
        _studentStats = studentStats;
        _landSubsidyStats = landSubsidyStats;
        _isLoading = false;
      });

      if (studentError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('学生统计加载失败: $studentError'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
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
            onPressed: _isLoading ? null : () async {
              // 清除缓存后重新加载，确保获取最新数据
              await ApiClient().clearCache();
              _loadStatistics();
            },
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
          
          
          _buildSection('社会保障', _buildSocialSecurityStats(context)),
          const SizedBox(height: 24),

          _buildSection('脱贫户/监测户', _buildPoorStats(context)),
          const SizedBox(height: 24),

          _buildSection('残疾等级分布', _buildDisabilityLevelChart(context)),
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

  Widget _buildSocialSecurityStats(BuildContext context) {
    final disabilityCount = stats?['disability'] ?? 0;
    final dibaoCount = stats?['dibao'] ?? 0;
    final tekunCount = stats?['tekun'] ?? 0;
    final tekunTypeDistribution = stats?['tekun_type_distribution'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow('残疾人员', disabilityCount, Colors.red, onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const FilteredPersonListPage(title: '残疾人员', disability: '是'),
              ));
            }),
            const Divider(),
            _buildStatRow('低保人员', dibaoCount, Colors.orange, onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const FilteredPersonListPage(title: '低保人员', dibao: '最低生活保障家庭'),
              ));
            }),
            const Divider(),
            _buildStatRow('特困供养人员', tekunCount, Colors.purple, onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const FilteredPersonListPage(title: '特困供养人员', tekun: '是'),
              ));
            }),
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
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => FilteredPersonListPage(title: entry.key, tekun: '是', tekunType: entry.key),
                        ));
                      },
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
  
  Widget _buildStatRow(String label, int count, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
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
    ),
    );
  }

  Widget _buildPoorStats(BuildContext context) {
    final poorTypeDistribution = stats?['poor_type_distribution'] as Map<String, dynamic>? ?? {};
    final poorTypePersonCount = stats?['poor_type_person_count'] as Map<String, dynamic>? ?? {};

    if (poorTypeDistribution.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final colors = {
      '脱贫户': Colors.green,
      '脱贫不稳定户': Colors.teal,
      '边缘易致贫户': Colors.orange,
      '突发严重困难户': Colors.red,
      '监测户': Colors.orange,
      '其他': Colors.blue,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: poorTypeDistribution.entries.map((entry) {
            return InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => FilteredPersonListPage(
                    title: '${entry.key}户主',
                    poorType: entry.key,
                    relation: '户主',
                  ),
                ));
              },
              child: Padding(
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
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if ((poorTypePersonCount[entry.key] ?? 0) > 0)
                          Text(
                            '${poorTypePersonCount[entry.key]} 人',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDisabilityLevelChart(BuildContext context) {
    final disLevelDistribution = stats?['dis_level_distribution'] as Map<String, dynamic>? ?? {};

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

    final levelColors = [
      Colors.red.shade400,
      Colors.orange.shade400,
      Colors.amber.shade600,
      Colors.green.shade400,
    ];

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < sortedLabels.length; i++) {
      final count = (disLevelDistribution[sortedLabels[i]] ?? 0).toDouble();
      final colorIndex = order.indexOf(sortedLabels[i]);
      final color = levelColors[colorIndex >= 0 ? colorIndex : i % levelColors.length];

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count,
              color: color,
              width: 40,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: sortedLabels.map((k) => (disLevelDistribution[k] ?? 0).toDouble()).reduce((a, b) => a > b ? a : b) * 1.15,
                color: Colors.grey.shade100,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  maxY: sortedLabels.map((k) => (disLevelDistribution[k] ?? 0).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == value.roundToDouble()) {
                            return Text('${value.toInt()}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < sortedLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(sortedLabels[idx], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (() {
                      final maxVal = sortedLabels.map((k) => (disLevelDistribution[k] ?? 0).toDouble()).reduce((a, b) => a > b ? a : b);
                      return maxVal > 0 ? (maxVal / 4).ceilToDouble().clamp(1, double.infinity) : 1;
                    })(),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${sortedLabels[group.x]}\n',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          children: [
                            TextSpan(
                              text: '${rod.toY.toInt()} 人',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...sortedLabels.asMap().entries.map((e) {
              final colorIndex = order.indexOf(e.value);
              final color = levelColors[colorIndex >= 0 ? colorIndex : e.key % levelColors.length];
              final count = disLevelDistribution[e.value] ?? 0;
              final total = disLevelDistribution.values.fold<int>(0, (sum, v) => sum + (v as int));
              final pct = total > 0 ? (count as int) / total * 100 : 0;
              return InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => FilteredPersonListPage(
                      title: '残疾${e.value}',
                      disLevel: e.value,
                    ),
                  ));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(e.value, style: const TextStyle(fontSize: 14)),
                      ),
                      Text(
                        '$count 人',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
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
      if (key == 'GRADUATED') {
        typeCount['已毕业'] = (typeCount['已毕业'] ?? 0) + (value as int);
      } else if (key.startsWith('K')) {
        typeCount['幼儿园'] = (typeCount['幼儿园'] ?? 0) + (value as int);
      } else if (key.startsWith('G')) {
        final gradeNum = int.tryParse(key.substring(1)) ?? 99;
        if (gradeNum <= 6) {
          typeCount['小学'] = (typeCount['小学'] ?? 0) + (value as int);
        } else if (gradeNum <= 9) {
          typeCount['初中'] = (typeCount['初中'] ?? 0) + (value as int);
        } else {
          typeCount['高中'] = (typeCount['高中'] ?? 0) + (value as int);
        }
      } else if (key.startsWith('U')) {
        typeCount['大学'] = (typeCount['大学'] ?? 0) + (value as int);
      } else if (key.startsWith('V')) {
        typeCount['职业'] = (typeCount['职业'] ?? 0) + (value as int);
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
          _buildSection('打款查询', _buildPaymentQueryEntry(context)),
          const SizedBox(height: 24),

          _buildSection('地力补贴统计', _buildLandSubsidyStats()),
          const SizedBox(height: 24),

          _buildSection('土地面积统计', _buildLandAreaStats()),
          const SizedBox(height: 24),

          _buildSection('林地面积统计', _buildForestAreaStats()),
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

  Widget _buildPaymentQueryEntry(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade50,
                child: Icon(Icons.health_and_safety, color: Colors.orange.shade700),
              ),
              title: const Text('低保发放查询'),
              subtitle: const Text('按月查询低保打款金额和卡号'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DibaoQueryPage()),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.shade50,
                child: Icon(Icons.volunteer_activism, color: Colors.teal.shade700),
              ),
              title: const Text('特困发放查询'),
              subtitle: const Text('按月查询特困打款金额和卡号'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TekunQueryPage()),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade50,
                child: Icon(Icons.elderly, color: Colors.green.shade700),
              ),
              title: const Text('养老保险查询'),
              subtitle: const Text('按月查询打款金额和打款卡号'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MonthlyPaymentQueryPage()),
                );
              },
            ),
          ],
        ),
      ),
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

  Widget _buildForestAreaStats() {
    final totalForestArea = personStats?['total_forest_area'] ?? 0;
    final avgForestArea = personStats?['avg_forest_area'] ?? 0;

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
                      totalForestArea.toStringAsFixed(2),
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
                      avgForestArea.toStringAsFixed(2),
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
