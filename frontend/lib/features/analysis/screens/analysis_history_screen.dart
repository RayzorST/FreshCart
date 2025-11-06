// analysis_history_screen.dart
import 'package:flutter/material.dart';
import 'package:client/api/client.dart';

class AnalysisHistoryScreen extends StatefulWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  State<AnalysisHistoryScreen> createState() => _AnalysisHistoryScreenState();
}

class _AnalysisHistoryScreenState extends State<AnalysisHistoryScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await ApiClient.getAnalysisHistory();
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки истории: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История анализов'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _history.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('История анализов пуста'),
                          SizedBox(height: 8),
                          Text(
                            'Проанализируйте ваше первое блюдо!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final analysis = _history[index];
                        return _buildHistoryItem(analysis);
                      },
                    ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> analysis) {
    final dishName = analysis['detected_dish'];
    final confidence = analysis['confidence'];
    final date = DateTime.parse(analysis['created_at']);
    final ingredients = analysis['ingredients'] ?? {};
    final basicIngredients = List<String>.from(ingredients['basic'] ?? []);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getConfidenceColor(confidence),
          child: Text(
            '${(confidence * 100).toInt()}%',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text(
          dishName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${basicIngredients.length} основных ингредиентов',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              _formatDate(date),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showAnalysisDetails(analysis);
        },
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.7) return Colors.green;
    if (confidence > 0.4) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} д. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else {
      return '${difference.inMinutes} мин. назад';
    }
  }

  void _showAnalysisDetails(Map<String, dynamic> analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(analysis['detected_dish']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Уверенность: ${(analysis['confidence'] * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 16),
              const Text(
                'Основные ингредиенты:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...List<String>.from(analysis['ingredients']?['basic'] ?? [])
                  .map((ingredient) => Text('• $ingredient')),
              if (analysis['ingredients']?['additional'] != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Дополнительные:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...List<String>.from(analysis['ingredients']?['additional'] ?? [])
                    .map((ingredient) => Text('• $ingredient')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}