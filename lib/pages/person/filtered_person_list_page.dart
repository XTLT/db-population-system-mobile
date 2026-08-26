import 'package:flutter/material.dart';
import '../../models/person.dart';
import '../../api/person_api.dart';
import '../person/person_detail_page.dart';

class FilteredPersonListPage extends StatefulWidget {
  final String title;
  final String? disability;
  final String? disLevel;
  final String? dibao;
  final String? tekun;
  final String? tekunType;
  final String? poorType;
  final String? relation;

  const FilteredPersonListPage({
    super.key,
    required this.title,
    this.disability,
    this.disLevel,
    this.dibao,
    this.tekun,
    this.tekunType,
    this.poorType,
    this.relation,
  });

  @override
  State<FilteredPersonListPage> createState() => _FilteredPersonListPageState();
}

class _FilteredPersonListPageState extends State<FilteredPersonListPage> {
  List<Person> _persons = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final persons = await PersonApi.searchAdvanced(
        disability: widget.disability,
        disLevel: widget.disLevel,
        dibao: widget.dibao,
        tekun: widget.tekun,
        tekunType: widget.tekunType,
        poorType: widget.poorType,
        relation: widget.relation,
        limit: 500,
      );
      setState(() {
        _persons = persons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} (${_persons.length})'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadData, child: const Text('重试')),
                    ],
                  ),
                )
              : _persons.isEmpty
                  ? const Center(child: Text('暂无数据'))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.separated(
                        itemCount: _persons.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = _persons[index];
                          return ListTile(
                            title: Text(p.name ?? ''),
                            subtitle: Text(
                              '${p.idCard ?? ''}  ${p.address ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: p.isDead == '是'
                                ? const Chip(
                                    label: Text('已故', style: TextStyle(fontSize: 11, color: Colors.white)),
                                    backgroundColor: Colors.grey,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  )
                                : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PersonDetailPage(idCard: p.idCard ?? ''),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
