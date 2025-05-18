import 'package:flutter/material.dart';
import '../controllers/history_controller.dart';

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

  List<dynamic> _allRecords = [];
  List<dynamic> _searchResult = [];
  bool _loading = false;
  String? _error;

  // TODO: 請根據實際情況取得 token
  final String _token = '請填入token';

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final records = await HistoryController.fetchLabelRecords();
      setState(() {
        _allRecords = records;
        _searchResult = records;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '獲取資料失敗';
        _loading = false;
      });
    }
  }

  void _doSearch() {
    setState(() {
      if (_searchMode == 'orderId') {
        final keyword = _orderIdController.text.trim();
        _searchResult = _allRecords.where((item) =>
          (item['apply_form']?['apply_id']?.toString() ?? '').contains(keyword)
        ).toList();
      } else {
        final keyword = _farmNameController.text.trim();
        _searchResult = _allRecords.where((item) =>
          (item['account']?['apiray_name'] ?? '').contains(keyword)
        ).toList();
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
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                        ? Center(child: Text(_error!, style: const TextStyle(fontSize: 20, color: Colors.red)))
                        : (_searchResult.isEmpty
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
                                final applyForm = item['apply_form'] ?? {};
                                final account = item['account'] ?? {};
                                final orderId = applyForm['apply_id']?.toString() ?? '';
                                final farmName = account['apiray_name'] ?? '';
                                final result = item['result']?.toString() ?? '';
                                final date = applyForm['detection_time']?.toString()?.split('T').first ?? '';
                                // 可根據實際API資料調整細節
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: Colors.yellow[100],
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                    title: Text(
                                      "$orderId - $farmName",
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
                                            date,
                                            style: const TextStyle(fontSize: 15, color: Colors.black87),
                                          ),
                                          const SizedBox(width: 18),
                                          const Icon(Icons.emoji_food_beverage, size: 18, color: Colors.orange),
                                          const SizedBox(width: 6),
                                          Text(
                                            result,
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
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.assignment_turned_in, color: Colors.orange, size: 28),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        "$orderId - $farmName",
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 22,
                                                          color: Colors.brown,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange[50],
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.emoji_food_beverage, color: Colors.orange, size: 24),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          "分析結果：",
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 18,
                                                            color: Colors.brown,
                                                          ),
                                                        ),
                                                        Text(
                                                          result,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 20,
                                                            color: Colors.deepOrange,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.category, color: Colors.orange, size: 22),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        "蜂蜜種類：${applyForm['honey_type'] ?? ''}",
                                                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.scale, color: Colors.orange, size: 22),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        "容量：${applyForm['capacity'] ?? ''}",
                                                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.calendar_today, color: Colors.orange, size: 22),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        "檢測日期：$date",
                                                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.person, color: Colors.orange, size: 22),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        "申請人：${account['name'] ?? ''}",
                                                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.phone, color: Colors.orange, size: 22),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        "電話：${account['phone'] ?? ''}",
                                                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.home, color: Colors.orange, size: 22),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        "蜂場名稱：$farmName",
                                                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.location_on, color: Colors.orange, size: 22),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          "蜂場地址：${account['apiray_address'] ?? ''}",
                                                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
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
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            )
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
