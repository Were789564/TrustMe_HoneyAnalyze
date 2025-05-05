import 'package:flutter/material.dart';

/// 檢測歷史紀錄顯示畫面
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchMode = 'orderId'; // 'orderId' or 'farmName'
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _farmNameController = TextEditingController();

  // 假資料
  final List<Map<String, String>> _mockHistory = [
    {
      'orderId': 'A123',
      'farmName': '蜂場一號',
      'result': '80% 蜂蜜',
      'date': '2024-06-01',
      'detail': '分析結果：80% 蜂蜜\nKBr濃度：1.2 mg/mL\n蜂蜜種類：龍眼蜜\n奈米製備日期：2024-05-20'
    },
    {
      'orderId': 'B456',
      'farmName': '蜂場二號',
      'result': '90% 蜂蜜',
      'date': '2024-05-28',
      'detail': '分析結果：90% 蜂蜜\nKBr濃度：1.0 mg/mL\n蜂蜜種類：荔枝蜜\n奈米製備日期：2024-05-10'
    },
    {
      'orderId': 'C789',
      'farmName': '蜂場三號',
      'result': '70% 蜂蜜',
      'date': '2024-05-15',
      'detail': '分析結果：70% 蜂蜜\nKBr濃度：0.8 mg/mL\n蜂蜜種類：百花蜜\n奈米製備日期：2024-04-30'
    },
  ];

  List<Map<String, String>> _searchResult = [];

  void _doSearch() {
    setState(() {
      if (_searchMode == 'orderId') {
        final keyword = _orderIdController.text.trim();
        _searchResult = _mockHistory
            .where((item) => item['orderId']!.contains(keyword))
            .toList();
      } else {
        final keyword = _farmNameController.text.trim();
        _searchResult = _mockHistory
            .where((item) => item['farmName']!.contains(keyword))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _farmNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // 背景漸層（與 video_analyze 相同）
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF176), Color(0xFFFFF9C4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // AppBar 樣式（與 video_analyze 相同，無白色底）
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "檢測歷史紀錄",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 4,
                          shadows: [
                            Shadow(
                              color: Colors.yellow,
                              offset: Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // 搜尋區塊
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 8),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.yellow[100],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text("檢測單編號"),
                                  value: 'orderId',
                                  groupValue: _searchMode,
                                  onChanged: (val) => setState(() => _searchMode = val!),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text("蜂場名稱"),
                                  value: 'farmName',
                                  groupValue: _searchMode,
                                  onChanged: (val) => setState(() => _searchMode = val!),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _searchMode == 'orderId'
                                    ? TextFormField(
                                        controller: _orderIdController,
                                        decoration: InputDecoration(
                                          labelText: "檢測單編號",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.yellow[50],
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                        ),
                                      )
                                    : TextFormField(
                                        controller: _farmNameController,
                                        decoration: InputDecoration(
                                          labelText: "蜂場名稱",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.yellow[50],
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.search, color: Colors.black),
                                  label: const Text(
                                    "搜尋",
                                    style: TextStyle(color: Colors.black, fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.yellow[700],
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _doSearch,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 搜尋結果區塊
                Expanded(
                  child: _searchResult.isEmpty
                      ? const Center(
                          child: Text(
                            "請輸入條件搜尋或無資料",
                            style: TextStyle(fontSize: 20, color: Colors.black54),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 8),
                          itemCount: _searchResult.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final item = _searchResult[idx];
                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: Colors.yellow[100],
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                title: Text(
                                  "${item['orderId']} - ${item['farmName']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.brown,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 18, color: Colors.orange),
                                      const SizedBox(width: 6),
                                      Text(
                                        item['date'] ?? '',
                                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                                      ),
                                      const SizedBox(width: 18),
                                      const Icon(Icons.emoji_food_beverage, size: 18, color: Colors.orange),
                                      const SizedBox(width: 6),
                                      Text(
                                        item['result'] ?? '',
                                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.brown, size: 32),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      backgroundColor: Colors.yellow[50],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${item['orderId']} - ${item['farmName']}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22,
                                                color: Colors.brown,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              item['detail'] ?? '',
                                              style: const TextStyle(fontSize: 18, color: Colors.black87, height: 1.5),
                                            ),
                                            const SizedBox(height: 18),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.yellow[700],
                                                  foregroundColor: Colors.black,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                onPressed: () => Navigator.of(context).pop(),
                                                child: const Text("關閉"),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
