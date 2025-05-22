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

  List<dynamic> _searchResult = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 預設不載入全部資料
  }

  Future<void> _doSearch() async {
    setState(() {
      _loading = true;
      _error = null;
      _searchResult = [];
    });
    try {
      if (_searchMode == 'orderId') {
        final keyword = _orderIdController.text.trim();
        if (keyword.isEmpty) {
          setState(() {
            _loading = false;
            _searchResult = [];
          });
          return;
        }
        final int? applyId = int.tryParse(keyword);
        if (applyId == null) {
          setState(() {
            _loading = false;
            _error = '請輸入正確的檢測單編號';
          });
          return;
        }
        final result = await HistoryController.fetchLabelByApplyId(applyId);
        setState(() {
          _loading = false;
          if (result != null) {
            _searchResult = [result];
          } else {
            _searchResult = [];
          }
        });
      } else {
        final keyword = _farmNameController.text.trim();
        if (keyword.isEmpty) {
          setState(() {
            _loading = false;
            _searchResult = [];
          });
          return;
        }
        final result = await HistoryController.fetchLabelByApirayName(keyword);
        setState(() {
          _loading = false;
          _searchResult = result;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '查詢失敗';
      });
    }
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
                                // 依據 API 結構調整
                                final orderId = item['apply_id']?.toString() ?? '';
                                final result = item['result']?.toString() ?? '';
                                final labelIdStart = item['label_id_start']?.toString() ?? '';
                                final labelIdEnd = item['label_id_end']?.toString() ?? '';
                                
                                final honeyType = item['honey_type']?.toString() ?? '';
                                final apirayName = item['apiray_name']?.toString() ?? '';
                                final dectionTimeRaw = item['dection_time']?.toString() ?? '';
                                String dectionTime = '';
                                if (dectionTimeRaw.isNotEmpty) {
                                  try {
                                    final dateTime = DateTime.parse(dectionTimeRaw);
                                    dectionTime = "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
                                  } catch (e) {
                                    // Handle parsing error if needed, or leave dectionTime as empty
                                  }
                                }
                                
                                // 純度直接用 result
                                final purity = result.isNotEmpty
                                    ? result.replaceAll(RegExp(r'\.0$'), '') + '%'
                                    : "未知";
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: Colors.yellow[100],
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                    title: Text(
                                      "檢測單號: $orderId",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.brown,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // 新增蜂場名稱
                                          if (apirayName.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 2),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.home, size: 18, color: Colors.orange),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "蜂場名稱: $apirayName",
                                                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          // 新增蜂蜜種類
                                          if (honeyType.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 2),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.local_florist, size: 18, color: Colors.orange),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "蜂蜜種類: $honeyType",
                                                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          // 新增檢測時間
                                          if (dectionTime.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 2),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.timer_outlined, size: 18, color: Colors.orange),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "檢測時間: $dectionTime",
                                                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          Row(
                                            children: [
                                              const Icon(Icons.confirmation_number, size: 18, color: Colors.orange),
                                              const SizedBox(width: 6),
                                              const Text(
                                                "標章:",
                                                style: TextStyle(fontSize: 15, color: Colors.black87),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 28.0, top: 2, bottom: 2),
                                            child: Text(
                                              "$labelIdStart",
                                              style: const TextStyle(fontSize: 15, color: Colors.black87),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 28.0, bottom: 2),
                                            child: Text(
                                              "$labelIdEnd",
                                              style: const TextStyle(fontSize: 15, color: Colors.black87),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // 不再顯示 result 行
                                          // 純度顯示區塊（設計感）
                                          const SizedBox(height: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.orange[200],
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.orange.withOpacity(0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.percent, color: Colors.deepOrange, size: 20),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  "純度",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.brown,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  purity,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.deepOrange,
                                                    fontSize: 20,
                                                    letterSpacing: 2,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.orangeAccent,
                                                        offset: Offset(0, 1),
                                                        blurRadius: 4,
                                                      ),
                                                    ],
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
