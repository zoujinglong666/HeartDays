import 'package:flutter/material.dart';
import 'package:heart_days/apis/plan.dart';
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
            _buildActionCard(context),
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
            ],
          ),
          const SizedBox(height: 16),
          if (plan.description != null && plan.description!.isNotEmpty)
            Text(
              plan.description,
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
            plan.category.toString(),
            const Color(0xFF007AFF),
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
            _formatDate(plan!.createdAt),
            const Color(0xFF8E8E93),
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

  Widget _buildActionCard(BuildContext context) {
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
            '操作',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.edit_outlined,
                  title: '编辑',
                  color: const Color(0xFF007AFF),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlanEditPage(plan: plan),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.delete_outline,
                  title: '删除',
                  color: const Color(0xFFFF3B30),
                  onTap: () => _showDeleteDialog(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.1), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      case 'pending':
        return const Color(0xFFFF9500);
      case 'in_progress':
        return const Color(0xFF007AFF);
      case 'completed':
        return const Color(0xFF34C759);
      case 'cancelled':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  String _getPriorityText(PlanPriority priority) {
    switch (priority) {
      case 'high':
        return '高优先级';
      case 'medium':
        return '中优先级';
      case 'low':
        return '低优先级';
      default:
        return '未知';
    }
  }

  String _getStatusText(PlanStatus status) {
    switch (status) {
      case 'pending':
        return '待开始';
      case 'in_progress':
        return '进行中';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      default:
        return '未知';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              '确认删除',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            content: Text(
              '确定要删除"${plan.title}"吗？此操作不可撤销。',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '取消',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, {
                    'action': 'delete',
                    'planId': plan.id,
                  });
                },
                child: const Text(
                  '删除',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFFF3B30),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
