import 'package:flutter/material.dart';
import 'package:impact_app/screens/setting/provider/sync_provider.dart';
import 'package:provider/provider.dart';

class SyncMainScreen extends StatefulWidget {
  const SyncMainScreen({super.key});

  @override
  State<SyncMainScreen> createState() => _SyncMainScreenState();
}

class _SyncMainScreenState extends State<SyncMainScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      // Tidak perlu cek mounted di sini karena listener akan di-remove di dispose
      Provider.of<SyncProvider>(context, listen: false)
          .setSearchQuery(_searchController.text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<SyncProvider>(context, listen: false);
        // Sinkronisasi controller dengan provider.searchQuery saat init
        // Hanya set jika memang berbeda untuk menghindari loop atau cursor jump
        if (_searchController.text != provider.searchQuery) {
          _searchController.text = provider.searchQuery;
          // Pindahkan cursor ke akhir teks
           if (_searchController.text.isNotEmpty) {
            _searchController.selection = TextSelection.fromPosition(
                TextPosition(offset: _searchController.text.length));
          }
        }
        //provider.clearSearch();
        // Menampilkan pesan error/sukses awal jika ada dari provider
        _handleProviderMessages(provider);
      }
    });

    //_searchController.clear(); 
  }

  void _handleProviderMessages(SyncProvider provider) {
    if (provider.errorMessage.isNotEmpty) {
      _showSnackbar(provider.errorMessage, Colors.red, provider);
    } else if (provider.successMessage.isNotEmpty) {
      _showSnackbar(provider.successMessage, Colors.green, provider);
    }
  }

  void _showSnackbar(String message, Color backgroundColor, SyncProvider providerInstance) {
    if (mounted && message.isNotEmpty) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Hapus snackbar sebelumnya jika ada
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: Duration(seconds: 3)),
      );
      providerInstance.clearMessages();
    }
  }

  @override
  void dispose() {
    _searchController.dispose(); // dispose controller akan otomatis remove listeners
    super.dispose();
  }

  Widget _buildSyncCard(BuildContext context, String title, double progress, int localCount, int totalApiCount, IconData icon) {
    String percentText = "${(progress * 100).toStringAsFixed(1)}%";
    String countText = "($localCount/$totalApiCount)";
    Color progressColor = progress >= 1.0 ? Colors.green : Colors.blueAccent;

    if (totalApiCount == 0 && localCount > 0) {
        percentText = "N/A";
    } else if (totalApiCount == 0 && localCount == 0 && progress == 0.0) {
        percentText = "0.0%";
    }

    return Container(
      width: (MediaQuery.of(context).size.width / 2) - 22, // Agar 2 card per baris
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: progressColor, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(percentText, style: TextStyle(color: progressColor, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(countText, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider SEHARUSNYA SUDAH ADA DI ATAS WIDGET INI (MISALNYA DI MAIN.DART)
    // JANGAN BUAT INSTANCE BARU PROVIDER DI SINI.

    return Consumer<SyncProvider>(
      builder: (context, provider, child) {
        // --- DEBUG PRINT PENTING ---
        print('----------------------------------------------------');
        print('[CONSUMER BUILD] searchQuery: "${provider.searchQuery}"');
        print('[CONSUMER BUILD] provider.filteredAreas.length: ${provider.filteredAreas.length}'); // <<< NILAI INI KRUSIAL
        print('[CONSUMER BUILD] provider.areaStatus: ${provider.areaStatus}');
        print('[CONSUMER BUILD] provider.hasFailedToFetchAreas: ${provider.hasFailedToFetchAreas}'); // Jika getter ini ada
        print('----------------------------------------------------');
        // --- AKHIR DEBUG PRINT ---

        // Sinkronkan _searchController.text jika provider.searchQuery berubah (misal saat area dipilih oleh provider)
        // Ini penting agar TextField di UI selalu konsisten dengan state di provider
        // Dilakukan dalam addPostFrameCallback untuk menghindari error setState selama build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) { // Selalu cek mounted dalam callback post-frame
            if (_searchController.text != provider.searchQuery) {
              _searchController.text = provider.searchQuery;
              if (_searchController.text.isNotEmpty) {
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _searchController.text.length),
                );
              }
            }
            // Handle snackbar juga bisa di sini, tapi pastikan tidak terpanggil berlebihan
             _handleProviderMessages(provider); // Panggil setelah UI stabil
          }
        });

        return Scaffold(
          backgroundColor: Colors.grey[100],
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: const Text('Sync Data Local'),
            backgroundColor: Colors.white,
            elevation: 1,
            foregroundColor: Colors.black87,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Pilih Area", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                      hintText: 'Cari Nama Area atau Kode Area...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: provider.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear(); // Listener akan memanggil provider.setSearchQuery("")
                                provider.clearSearch();    // Memastikan state di provider juga bersih
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16)
                  ),
                ),

                // BLOK KONDISIONAL UNTUK MENAMPILKAN HASIL PENCARIAN / PESAN
                if (provider.areaStatus == SyncStatus.loadingAreas)
                  const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                else if (provider.hasFailedToFetchAreas && provider.searchQuery.isNotEmpty) // Gunakan getter dari provider
                   Padding(
                     padding: const EdgeInsets.all(8.0),
                     child: Center(child: Text("Gagal memuat data area. Error: ${provider.errorMessage}")),
                   )
                else if (provider.searchQuery.isNotEmpty && provider.filteredAreas.isNotEmpty)
                  Container(
                    // color: Colors.amber.withOpacity(0.3), // Hapus warna debug jika sudah OK
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 200, minHeight: 50), // minHeight untuk debug bisa dihapus
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.white, // Kembalikan warna asli
                        // border: Border.all(color: Colors.red, width: 2), // Hapus border debug
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                        ]
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: provider.filteredAreas.length, // INI HARUS > 0 AGAR ITEMBUILDER DIPANGGIL
                      itemBuilder: (context, index) {
                        // JIKA ITEMCOUNT > 0, PRINT INI HARUS MUNCUL
                        final area = provider.filteredAreas[index];
                        print('[UI ListView inside itemBuilder] Index: $index, Area: ${area.nama}');
                        return ListTile(
                          // tileColor: Colors.lightGreen.withOpacity(0.3), // Hapus warna debug jika sudah OK
                          title: Text(area.nama, style: TextStyle(color: Colors.black)),
                          subtitle: Text(area.kodeArea, style: TextStyle(color: Colors.black87)),
                          onTap: () {
                            provider.selectArea(area);
                            _searchController.clear(); // Listener akan memanggil provider.setSearchQuery("")
                            provider.clearSearch();  
                            FocusScope.of(context).unfocus();
                          },
                        );
                      },
                    ),
                  )
                else if (provider.searchQuery.isNotEmpty && provider.filteredAreas.isEmpty && provider.areaStatus != SyncStatus.loadingAreas /*&& !provider.hasFailedToFetchAreas*/)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: Text("Area tidak ditemukan.")),
                  )
                else
                  const SizedBox(height: 4.0), // Placeholder jika tidak ada kondisi di atas terpenuhi (misal saat search query kosong)

                if (provider.selectedArea != null)
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: Text("Area Yang Dipilih: ${provider.selectedArea!.nama}")),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: Text("Tidak ada area yang dipilih. ")),
                  ),  


                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildSyncCard(context,'Data Outlet', provider.outletProgress, provider.localOutletCount, provider.totalOutletApiCount, Icons.store),
                    _buildSyncCard(context,'Data Product', provider.productProgress, provider.localProductCount, provider.totalProductApiCount, Icons.inventory_2),
                    _buildSyncCard(context,'Data Kecamatan', provider.kecamatanProgress, provider.localKecamatanCount, provider.totalKecamatanApiCount, Icons.location_city),
                    _buildSyncCard(context,'Data Kelurahan', provider.kelurahanProgress, provider.localKelurahanCount, provider.totalKelurahanApiCount, Icons.holiday_village),
                  ],
                ),
                const Spacer(),
                Center(child: Text("Cadangan Terakhir: ${provider.lastSyncTime}", style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: provider.syncProcessStatus == SyncStatus.syncing || provider.selectedArea == null
                            ? Colors.grey
                            : Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: (provider.syncProcessStatus == SyncStatus.syncing || provider.selectedArea == null)
                        ? null
                        : () {
                            provider.startSync();
                          },
                    icon: provider.syncProcessStatus == SyncStatus.syncing
                        ? Container(width: 20, height: 20, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                        : const Icon(Icons.sync),
                    label: Text(
                        provider.syncProcessStatus == SyncStatus.syncing ? "Sinkronisasi..." : "Sync Data",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}