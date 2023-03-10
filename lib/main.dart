import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Remove the debug banner
      debugShowCheckedModeBanner: false,
      title: 'Người Đọc',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // text fields' controllers

  final TextEditingController _maLopHocController = TextEditingController();
  final TextEditingController _tenLopController = TextEditingController();
  final TextEditingController _soLuongSinhVienController =
      TextEditingController();
  final TextEditingController _maGiangVienController = TextEditingController();
  final TextEditingController _soDienThoaiController = TextEditingController();

  final CollectionReference _productss =
      FirebaseFirestore.instance.collection('readers');

  // This function is triggered when the floatting button or one of the edit buttons is pressed
  // Adding a product if no documentSnapshot is passed
  // If documentSnapshot != null then update an existing product
  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _maLopHocController.text = documentSnapshot['maLopHoc'];
      _soLuongSinhVienController.text = documentSnapshot['soLuongSinhVien'];
      _tenLopController.text = documentSnapshot['tenLop'];
      _maGiangVienController.text = documentSnapshot['maGiangVien'];
      _soDienThoaiController.text = documentSnapshot['soDienThoai'].toString();
    }

    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                // prevent the soft keyboard from covering text fields
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _maLopHocController,
                  decoration: const InputDecoration(labelText: 'Mã Người Đọc'),
                ),
                TextField(
                  controller: _tenLopController,
                  decoration: const InputDecoration(labelText: 'Tên'),
                ),
                TextField(
                  controller: _soLuongSinhVienController,
                  decoration: const InputDecoration(labelText: 'Ngày Sinh'),
                ),
                TextField(
                  controller: _maGiangVienController,
                  decoration: const InputDecoration(labelText: 'Địa Chỉ'),
                ),
                TextField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  controller: _soDienThoaiController,
                  decoration: const InputDecoration(
                    labelText: 'Số Điện Thoại',
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: Text(action == 'create' ? 'Create' : 'Update'),
                  onPressed: () async {
                    final String? maLopHoc = _maLopHocController.text;
                    final String? tenLop = _tenLopController.text;
                    final String? soLuongSinhVien =
                        _soLuongSinhVienController.text;
                    final String? maGiangVien = _maGiangVienController.text;
                    final double? soDienThoai =
                        double.tryParse(_soDienThoaiController.text);
                    if (tenLop != null && soDienThoai != null) {
                      if (action == 'create') {
                        // Persist a new product to Firestore
                        await _productss.add({
                          "maLopHoc": maLopHoc,
                          "tenLop": tenLop,
                          "soLuongSinhVien": soLuongSinhVien,
                          "maGiangVien": maGiangVien,
                          "soDienThoai": soDienThoai
                        });
                      }

                      if (action == 'update') {
                        // Update the product
                        await _productss.doc(documentSnapshot!.id).update({
                          "maLopHoc": maLopHoc,
                          "tenLop": tenLop,
                          "soLuongSinhVien": soLuongSinhVien,
                          "maGiangVien": maGiangVien,
                          "soDienThoai": soDienThoai
                        });
                      }

                      // Clear the text fields
                      _maLopHocController.text = '';
                      _tenLopController.text = '';
                      _soLuongSinhVienController.text = '';
                      _maGiangVienController.text = '';
                      _soDienThoaiController.text = '';

                      // Hide the bottom sheet
                      Navigator.of(context).pop();
                    }
                  },
                )
              ],
            ),
          );
        });
  }

  // Deleteing a product by id
  Future<void> _deleteProduct(String productId) async {
    await _productss.doc(productId).delete();

    // Show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted a product')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('crud.com'),
      ),
      // Using StreamBuilder to display all products from Firestore in real-time
      body: StreamBuilder(
        stream: _productss.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                    streamSnapshot.data!.docs[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(documentSnapshot['ten']),
                    subtitle: Text(documentSnapshot['soDienThoai'].toString()),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          // Press this button to edit a single product
                          IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _createOrUpdate(documentSnapshot)),
                          // This icon button is used to delete a single product
                          IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteProduct(documentSnapshot.id)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      // Add new product
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
