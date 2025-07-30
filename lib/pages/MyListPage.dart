import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:heart_days/apis/plan.dart';
import 'package:heart_days/common/decode.dart';
import 'package:heart_days/components/RefreshList.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyListPage extends StatelessWidget {
  const MyListPage({super.key});

  Future<PaginatedData<Plan>> fetchData(int page, int size) async {
    final prefs = await SharedPreferences.getInstance();
    final authDataString = prefs.getString('auth_data');
    final Map<String, dynamic> authMap = jsonDecode(authDataString!);
    final authState = AuthState.fromJson(authMap);

    final response = await fetchPlanListByUserId({
      "page": page,
      "pageSize": size,
      "userId": authState.user?.id,
    });
    if (response.data == null) {
      return PaginatedData.empty();
    }
    return response.data!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('分页加载示例')),
      body: LoadMoreList<Plan>(
        fetchPage: fetchData,
        itemBuilder: (ctx, item, index) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListTile(
                title: Text(item.title),
                leading: const Icon(Icons.label_important_outline),
              ),
      ),
      useGrid: false,
      style: PaginatedListStyle(
        loadingColor: Colors.red,
        textStyle: const TextStyle(fontSize: 14, color: Colors.black87),
        spacing: 16,
      ),
    ),
    );
  }
}
