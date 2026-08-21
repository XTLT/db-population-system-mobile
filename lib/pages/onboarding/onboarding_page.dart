import 'package:flutter/material.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/onboarding_step_widget.dart';
import '../login/login_page.dart';


class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingStep> _steps = const [
    OnboardingStep(
      title: '欢迎使用人口信息管理系统',
      description: '高效管理人口信息，随时随地查询和编辑',
      icon: Icons.people,
    ),
    OnboardingStep(
      title: '搜索人员',
      description: '支持姓名、身份证号、户号等多种搜索方式',
      icon: Icons.search,
    ),
    OnboardingStep(
      title: '离线使用',
      description: '支持离线编辑和查看，网络恢复后自动同步',
      icon: Icons.offline_bolt,
    ),
    OnboardingStep(
      title: '数据统计',
      description: '多维度数据分析，自定义报表生成',
      icon: Icons.bar_chart,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return OnboardingStepWidget(
                    title: _steps[index].title,
                    description: _steps[index].description,
                    icon: _steps[index].icon,
                    demo: _steps[index].demo,
                  );
                },
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          
          TextButton(
            onPressed: _skip,
            child: const Text('跳过'),
          ),
          const Spacer(),
          
          Row(
            children: List.generate(
              _steps.length,
              (index) => _buildDot(index),
            ),
          ),
          const Spacer(),
          
          ElevatedButton(
            onPressed: _nextOrFinish,
            child: Text(_currentPage == _steps.length - 1 ? '开始使用' : '下一步'),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _skip() async {
    await OnboardingService.markCompleted();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _nextOrFinish() async {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await OnboardingService.markCompleted();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }
}
