import 'package:flutter/material.dart';
import 'package:heart_days/apis/plan.dart';
import 'package:heart_days/utils/dateUtils.dart';
import 'plan_edit_page.dart';

class PlanDetailPage extends StatelessWidget {
  final Plan plan;

  const PlanDetailPage({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          '计划详情',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF007AFF)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlanEditPage(plan: plan),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 16),
            if (plan.reminderAt != null || plan.completedAt != null)
              _buildTimeCard(),
            if (plan.reminderAt != null || plan.completedAt != null)
              const SizedBox(height: 16),
            if (plan.remarks != null && plan.remarks!.isNotEmpty)
              _buildRemarksCard(),
            if (plan.remarks != null && plan.remarks!.isNotEmpty)
              const SizedBox(height: 16),
            // _buildActionCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: _getPriorityColor(
                    intToPriority(plan.priority) as PlanPriority,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  plan.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    intToStatus(plan.status) as PlanStatus,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(intToStatus(plan.status) as PlanStatus),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(
                      intToStatus(plan.status) as PlanStatus,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (plan.description != null && plan.description!.isNotEmpty)
            Text(
              plan.description!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '基本信息',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            '状态',
            _getStatusText(intToStatus(plan.status) as PlanStatus),
            _getStatusColor(intToStatus(plan.status) as PlanStatus),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            '优先级',
            _getPriorityText(intToPriority(plan.priority) as PlanPriority),
            _getPriorityColor(intToPriority(plan.priority) as PlanPriority),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            '分类',
            plan.category as String,
            _getCategoryColor(plan.category as String),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            '计划日期',
            _formatDate(plan.date),
            const Color(0xFF34C759),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            '创建时间',
            formatDateTime(plan.createdAt),
            const Color(0xFF8E8E93),
          ),
          ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              '更新时间',
              formatDateTime(plan.updatedAt!),
              const Color(0xFF8E8E93),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '时间设置',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          if (plan.reminderAt != null) ...[
            _buildInfoRow(
              '提醒时间',
              formatDateTime(plan.reminderAt!),
              const Color(0xFFFF9500),
            ),
            if (plan.completedAt != null) const SizedBox(height: 16),
          ],
          if (plan.completedAt != null)
            _buildInfoRow(
              '完成时间',
              formatDateTime(plan.completedAt!),
              const Color(0xFF34C759),
            ),
        ],
      ),
    );
  }

  Widget _buildRemarksCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '备注信息',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
            ),
            child: Text(
              plan.remarks!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildActionCard(BuildContext context) {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(24),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.04),
  //           blurRadius: 20,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           '操作',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.w600,
  //             color: Color(0xFF1A1A1A),
  //           ),
  //         ),
  //         const SizedBox(height: 20),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: _buildActionButton(
  //                 context,
  //                 icon: Icons.edit_outlined,
  //                 title: '编辑',
  //                 color: const Color(0xFF007AFF),
  //                 onTap: () {
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (context) => PlanEditPage(plan: plan),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: _buildActionButton(
  //                 context,
  //                 icon: Icons.delete_outline,
  //                 title: '删除',
  //                 color: const Color(0xFFFF3B30),
  //                 onTap: () => _showDeleteDialog(context),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
  //
  // Widget _buildActionButton(
  //   BuildContext context, {
  //   required IconData icon,
  //   required String title,
  //   required Color color,
  //   required VoidCallback onTap,
  // }) {
  //   return Material(
  //     color: Colors.transparent,
  //     child: InkWell(
  //       onTap: onTap,
  //       borderRadius: BorderRadius.circular(12),
  //       child: Container(
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           color: color.withOpacity(0.05),
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(color: color.withOpacity(0.1), width: 1),
  //         ),
  //         child: Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(8),
  //               decoration: BoxDecoration(
  //                 color: color.withOpacity(0.1),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: Icon(icon, color: color, size: 20),
  //             ),
  //             const SizedBox(width: 16),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     title,
  //                     style: TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.w600,
  //                       color: color,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Color _getPriorityColor(PlanPriority priority) {
    switch (priority) {
      case PlanPriority.high:
        return const Color(0xFFFF3B30);
      case PlanPriority.medium:
        return const Color(0xFFFF9500);
      case PlanPriority.low:
        return const Color(0xFF34C759);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  Color _getStatusColor(PlanStatus status) {
    switch (status) {
      case PlanStatus.pending:
        return const Color(0xFFFF9500);
      case PlanStatus.inProgress:
        return const Color(0xFF007AFF);
      case PlanStatus.completed:
        return const Color(0xFF34C759);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  Color _getCategoryColor(String category) {
    final categoryMap = {
      '工作': const Color(0xFFFF3B30),
      '学习': const Color(0xFF007AFF),
      '健身': const Color(0xFF34C759),
      '生活': const Color(0xFFFF2D92),
      '娱乐': const Color(0xFFFF9500),
      '购物': const Color(0xFF5856D6),
      '旅行': const Color(0xFF32D74B),
      '其他': const Color(0xFF8E8E93),
    };
    return categoryMap[category] ?? const Color(0xFF8E8E93);
  }

  String _getPriorityText(PlanPriority priority) {
    switch (priority) {
      case PlanPriority.high:
        return '高优先级';
      case PlanPriority.medium:
        return '中优先级';
      case PlanPriority.low:
        return '低优先级';
      default:
        return '未知';
    }
  }

  String _getStatusText(PlanStatus status) {
    switch (status) {
      case PlanStatus.pending:
        return '待开始';
      case PlanStatus.inProgress:
        return '进行中';
      case PlanStatus.completed:
        return '已完成';
      default:
        return '未知';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
