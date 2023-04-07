import 'dart:io';
import 'package:excel/excel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p_dos_admin/constant.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';

class ExcelCsvReader extends StatefulWidget {
  @override
  _ExcelCsvReaderState createState() => _ExcelCsvReaderState();
}

class _ExcelCsvReaderState extends State<ExcelCsvReader> {
  List<List<dynamic>>? _data;
  bool _isLoading = false;

  Future<void> UploadData(Map<String, dynamic> data) async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      data["uid"] = uid;
      setState(() {
        _isLoading = true;
      });
      await FirebaseFirestore.instance.collection('excel').add(data);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error uploading data: $e");
      displayMessage("Error uploading data: $e");
      return;
    }
  }

  Future<List<List<dynamic>>> readExcel() async {
    try {
      // Check storage permission
      PermissionStatus permission = await Permission.storage.status;
      if (!permission.isGranted) {
        // Request storage permission
        permission = await Permission.storage.request();

        // Handle user's response
        if (permission.isGranted) {
          // Storage permission granted
          // Do something here
        } else {
          // Storage permission denied
          print("Storage permission not granted");
          return [];
        }
      }

      // Pick an Excel or CSV file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xls', 'xlsx'],
      );

      if (result == null) {
        // Handle case where file picker is cancelled
        displayMessage("No file selected");
        return [];
      }

      if (!['csv', 'xls', 'xlsx'].contains(result.files.single.extension)) {
        // Handle case where selected file is not an Excel or CSV file
        displayMessage("Please select an Excel or CSV file");
        return [];
      }

      // Read data from Excel file
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      setState(() {
        _isLoading = true; // show progress indicator
      });

      // Delete existing data from Firestore
      try {
        QuerySnapshot snapshot =
            await FirebaseFirestore.instance.collection("excel").get();
        List<QueryDocumentSnapshot> documents = snapshot.docs;
        for (var doc in documents) {
          await doc.reference.delete();
        }

        print("Existing data deleted successfully");
      } catch (e) {
        print("Error deleting existing data: $e");
        displayMessage("Error deleting existing data: $e");
        setState(() {
          _isLoading = false; // hide progress indicator
        });
        return [];
      }

      // Upload data to Firestore
      print("Uploading data...");
      final rows = <List<dynamic>>[];
      final headers = <String>[];
      for (var sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName]!;

        if (sheet.rows.length < 2) {
          // Handle case where selected sheet has no data
          displayMessage("Sheet \"$sheetName\" does not contain any data");
          continue;
        }

        for (var i = 0; i < sheet.rows.length; i++) {
          var row = sheet.row(i);
          if (i == 0) {
            for (var j = 0; j < row.length; j++) {
              headers.add(row[j]?.value?.toString() ?? "");
            }
          } else {
            final data = <String, dynamic>{};
            for (var j = 0; j < row.length; j++) {
              final header = headers[j];
              final value = row[j]?.value;
              if (value != null) {
                if (header == 'lat' || header == 'lng') {
                  data[header] = double.parse(value.toString());
                } else {
                  data[header] = value.toString();
                }
              } else {
                data[header] = '';
              }
            }

            await UploadData(data);
            rows.add(data.values.toList());
          }
        }
      }

      setState(() {
        _isLoading = false; // hide progress indicator
      });

      displayMessage("Data uploaded successfully");
      return rows;
    } catch (e) {
      print("Error reading Excel file: $e");
      displayMessage("Error reading Excel file: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Text(
          'P-DOS HOME',
          style: GoogleFonts.getFont(
            'Nunito',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: appColor,
          ),
        ),
      ),
      body: Container(
        child: Stack(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('excel').snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData) {
                  return Center(child: Text('Loading...'));
                }
                if (snapshot.data!.size == 0) {
                  return Center(child: Text('No data found.'));
                }
                // Rest of the code to display the DataTable when there is data
                List<DataRow> rows = [];
                int index = 1;
                snapshot.data!.docs.forEach((doc) {
                  Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;
                  DataRow row = DataRow(cells: [
                    DataCell(Text((index).toString())),
                    DataCell(
                      Text(
                        data['name'] ??
                            data['Name'] ??
                            data['Name (våldtäkt mot barn)'] ??
                            ''
                                .split(' ')
                                .where((element) => (element).isNotEmpty)
                                .toList()
                                .asMap()
                                .map(
                                  (index, word) => MapEntry(
                                    index,
                                    word + ((index + 1) % 3 == 0 ? '\n' : ' '),
                                  ),
                                )
                                .values
                                .join(),
                        style: columnStyle,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    DataCell(
                      Text(
                        (data['address']?.toString() ??
                                data['Adress'] ??
                                data['Address'] ??
                                '')
                            .split(' ')
                            .where((element) => (element as String).isNotEmpty)
                            .toList()
                            .asMap()
                            .map((index, word) => MapEntry(index,
                                word + ((index + 1) % 3 == 0 ? '\n' : ' ')))
                            .values
                            .join(),
                        style: columnStyle,
                        maxLines: 5,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    DataCell(
                      Text(
                        data['personal number'] ??
                            data['Personal Number'] ??
                            data['Personnummer: (NY) '] ??
                            '',
                        style: columnStyle,
                        maxLines: 5,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    DataCell(
                      Text(
                        data['category'] ??
                            data['Category'] ??
                            data['Conviction '] ??
                            '',
                        style: columnStyle,
                        maxLines: 5,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    DataCell(
                      Text(
                        data['convcted'] ??
                            data['Convicted yes/no'] ??
                            data['convictec'] ??
                            data['Conicted'] ??
                            '',
                        style: columnStyle,
                        maxLines: 5,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]);
                  rows.add(row);
                  index++;
                });
                return SingleChildScrollView(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    // width: MediaQuery.of(context).size.width,
                    // height: MediaQuery.of(context).size.height,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: InteractiveViewer(
                        minScale: 0.1,
                        maxScale: 2.0,
                        child: DataTable(
                          decoration: BoxDecoration(
                            color: Color(0xffA7C8E5).withOpacity(0.20),
                          ),
                          headingTextStyle: rowStyle,
                          border: TableBorder.all(
                              color: Colors.black.withOpacity(0.20)),
                          columns: [
                            DataColumn(
                              label: Container(
                                child: Text(
                                  'index',
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                child: Text(
                                  'Name',
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                child: Text(
                                  'Address',
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                child: Text(
                                  'personal number',
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                child: Text(
                                  'Category',
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                child: Text(
                                  'Convicted',
                                ),
                              ),
                            ),
                          ],
                          rows: rows,
                          columnSpacing: 5,
                          dividerThickness: 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  color: appColor,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: appColor,
        onPressed: () {
          readExcel().then((data) {
            setState(() {
              _data = data;
            });
          });
        },
        label: Icon(
          Icons.add,
          color: Colors.white,
        ),
        icon: Text(
          'Add New Excel File',
          style: buttonText,
        ),
      ),
    );
  }
}

// Future<List<List<dynamic>>> readExcel() async {
//   PermissionStatus permission = await Permission.storage.status;
//   if (!permission.isGranted) {
//   } else {}
//   FilePickerResult? result = await FilePicker.platform.pickFiles(
//     type: FileType.custom,
//     allowedExtensions: ['csv', 'xls', 'xlsx'],
//   );
//
//   if (result == null) {
//     return [];
//   }
//
//   final file = File(result.files.single.path!);
//
//   if (!['csv', 'xls', 'xlsx'].contains(file.path.split('.').last)) {
//     displayMessage("Please select an Excel or CSV file.");
//     return [];
//   }
//
//   final bytes = await file.readAsBytes();
//   final excel = Excel.decodeBytes(bytes);
//
//   final sheet = excel.tables[excel.tables.keys.first];
//
//   if (sheet!.rows.length < 2) {
//     displayMessage("Selected file does not contain any data");
//     return [];
//   }
//   try {
//     QuerySnapshot snapshot =
//         await FirebaseFirestore.instance.collection("excel").get();
//     List<QueryDocumentSnapshot> documents = snapshot.docs;
//     for (var doc in documents) {
//       await doc.reference.delete();
//     }
//
//     print("Existing data deleted successfully");
//   } catch (e) {
//     print("Error deleting existing data: $e");
//     displayMessage("Error deleting existing data: $e");
//   }
//   final rows = <List<dynamic>>[];
//   final headers = <String>[];
//   for (var i = 0; i < sheet.rows.length; i++) {
//     var row = sheet.row(i);
//     if (i == 0) {
//       for (var j = 0; j < row.length; j++) {
//         headers.add(row[j]!.value.toString());
//       }
//     } else {
//       final data = <String, dynamic>{};
//       for (var j = 0; j < row.length; j++) {
//         final header = headers[j];
//         final value = row[j]!.value;
//         if (value != null) {
//           if (header == 'lat' || header == 'lng') {
//             data[header] = double.parse(value.toString());
//           } else {
//             data[header] = value.toString();
//           }
//         } else {
//           data[header] = '';
//         }
//       }
//
//       await UploadData(data);
//       rows.add(data.values.toList());
//     }
//   }
//
//   print("New data uploaded successfully");
//   return rows;
// }

// Future<void> UploadData(Map<String, dynamic> data) async {
//   try {
//     String uid = FirebaseAuth.instance.currentUser!.uid;
//     data["uid"] = uid;
//     await FirebaseFirestore.instance
//         .collection('excel')
//         .add(data)
//         .whenComplete(() {
//       displayMessage("Data uploaded successfully");
//     });
//   } catch (e) {
//     print("Error uploading data: $e");
//     displayMessage("Error uploading data: $e");
//     return;
//   }
// }

// Future<void> UploadData(Map<String, dynamic> data) async {
//   try {
//     String uid = FirebaseAuth.instance.currentUser!.uid;
//     data["uid"] = uid;
//     await FirebaseFirestore.instance.collection('excel').add(data);
//     displayMessage("Data uploaded successfully");
//   } catch (e) {
//     print("Error uploading data: $e");
//     displayMessage("Error uploading data: $e");
//   }
// }

// Future<List<List<dynamic>>> readExcel() async {
//   // Pick the file
//   FilePickerResult? result = await FilePicker.platform.pickFiles(
//     type: FileType.custom,
//     allowedExtensions: ['csv', 'xls', 'xlsx'],
//   );
//
//   if (result == null) {
//     // User canceled file picker
//     return [];
//   }
//
//   // Get the selected file
//   final file = File(result.files.single.path!);
//
//   // Check if the file extension is allowed
//   if (!['csv', 'xls', 'xlsx'].contains(file.path.split('.').last)) {
//     displayMessage("Please select an Excel or CSV file.");
//     return [];
//   }
//
//   final bytes = await file.readAsBytes();
//   final excel = Excel.decodeBytes(bytes);
//
//   // Get the first worksheet
//   final sheet = excel.tables[excel.tables.keys.first];
//
//   // Check that the file contains at least one row of data
//   if (sheet!.rows.length < 2) {
//     displayMessage("Selected file does not contain any data");
//     return [];
//   }
//
//   // Delete the existing data in the "excel" collection
//   try {
//     QuerySnapshot snapshot =
//         await FirebaseFirestore.instance.collection("excel").get();
//     List<QueryDocumentSnapshot> documents = snapshot.docs;
//     for (var doc in documents) {
//       await doc.reference.delete();
//     }
//     print("Existing data deleted successfully");
//   } catch (e) {
//     print("Error deleting existing data: $e");
//     displayMessage("Error deleting existing data: $e");
//   }
//
//   // Upload the new data from the file
//   final rows = <List<dynamic>>[];
//   final headers = <String>[];
//   for (var i = 0; i < sheet.rows.length; i++) {
//     var row = sheet.row(i);
//     if (i == 0) {
//       // This is the header row, extract column names
//       for (var j = 0; j < row.length; j++) {
//         headers.add(row[j]!.value.toString());
//       }
//     } else {
//       final data = <String, dynamic>{};
//       for (var j = 0; j < row.length; j++) {
//         final header = headers[j];
//         final value = row[j]!.value;
//         if (value != null) {
//           // Check if the header is lat/lng and parse the values accordingly
//           if (header == 'lat' || header == 'lng') {
//             data[header] = double.parse(value.toString());
//           } else {
//             data[header] = value.toString();
//           }
//         } else {
//           data[header] = '';
//         }
//       }
//
//       await UploadData(data);
//       rows.add(data.values.toList());
//     }
//   }
//
//   print("New data uploaded successfully");
//   return rows;
// }
// Future<void> UploadData(Map<String, dynamic> data) async {
//   try {
//     String uid = FirebaseAuth.instance.currentUser!.uid;
//     data["uid"] = uid;
//     await FirebaseFirestore.instance.collection('excel').add(data);
//     displayMessage("Data uploaded successfully");
//   } catch (e) {
//     print("Error uploading data: $e");
//     displayMessage("Error uploading data: $e");
//   }
// }

// Future<void> UploadData(Map<String, dynamic> data) async {
//   try {
//     await FirebaseFirestore.instance.collection('excel').add(data);
//     displayMessage("Data uploaded successfully");
//   } catch (e) {
//     print("Error uploading data: $e");
//     displayMessage("Error uploading data: $e");
//   }
// }

// Future<List<List<dynamic>>> readExcel() async {
//   // Pick the file
//   FilePickerResult? result = await FilePicker.platform.pickFiles(
//     type: FileType.custom,
//     allowedExtensions: ['csv', 'xls', 'xlsx'],
//   );
//
//   if (result == null) {
//     // User canceled file picker
//     return [];
//   }
//
//   // Get the selected file
//   final file = File(result.files.single.path!);
//
//   // Check if the file extension is allowed
//   if (!['csv', 'xls', 'xlsx'].contains(file.path.split('.').last)) {
//     displayMessage("Please select an Excel or CSV file.");
//     return [];
//   }
//
//   final bytes = await file.readAsBytes();
//   final excel = Excel.decodeBytes(bytes);
//
//   // Get the first worksheet
//   final sheet = excel.tables[excel.tables.keys.first];
//
//   // Check that the file contains at least one row of data
//   if (sheet!.rows.length < 2) {
//     displayMessage("Selected file does not contain any data");
//     return [];
//   }
//
//   // Delete the existing data in the "excel" collection
//   try {
//     QuerySnapshot snapshot =
//         await FirebaseFirestore.instance.collection("excel").get();
//     List<QueryDocumentSnapshot> documents = snapshot.docs;
//     for (var doc in documents) {
//       await doc.reference.delete();
//     }
//     print("Existing data deleted successfully");
//   } catch (e) {
//     print("Error deleting existing data: $e");
//     displayMessage("Error deleting existing data: $e");
//   }
//
//   // Upload the new data from the file
//   final rows = <List<dynamic>>[];
//   final headers = <String>[];
//   for (var i = 0; i < sheet.rows.length; i++) {
//     var row = sheet.row(i);
//     if (i == 0) {
//       // This is the header row, extract column names
//       for (var j = 0; j < row.length; j++) {
//         headers.add(row[j]!.value.toString());
//       }
//     } else {
//       final data = <String, dynamic>{};
//       for (var j = 0; j < row.length; j++) {
//         final header = headers[j];
//         final value = row[j]!.value;
//         if (value != null) {
//           data[header] = value.toString();
//           // print()
//         } else {
//           data[header] = '';
//         }
//         // print('object   $data');
//       }
//
//       // print('object$data');
//       await UploadData(data);
//       rows.add(data.values.toList());
//     }
//   }
//
//   print("New data uploaded successfully");
//   return rows;
// }

// Future<List<List<dynamic>>> readExcel() async {
//   FilePickerResult? result = await FilePicker.platform.pickFiles(
//     type: FileType.custom,
//     allowedExtensions: ['csv', 'xls', 'xlsx'],
//   );
//   if (result != null) {
//     File file = File(result.files.single.path!);
//     final bytes = await file.readAsBytes();
//     final excel = Excel.decodeBytes(bytes);
//
//     // Get the first worksheet
//     final sheet = excel.tables[excel.tables.keys.first];
//
//     // Get all rows
//     final rows = <List<dynamic>>[];
//     final headers = <String>[];
//     for (var i = 0; i < sheet!.rows.length; i++) {
//       final row = sheet.row(i);
//       if (i == 0) {
//         // This is the header row, extract column names
//         for (var j = 0; j < row.length; j++) {
//           headers.add(row[j]!.value.toString());
//         }
//       } else {
//         // This is a data row
//         final data = <String, dynamic>{};
//         for (var j = 0; j < row.length; j++) {
//           final header = headers[j];
//           final value = row[j]!.value;
//           if (value != null) {
//             data[header] = value.toString();
//           } else {
//             data[header] = '';
//           }
//         }
//         await UploadData(data);
//         rows.add(data.values.toList());
//       }
//     }
//
//     return rows;
//   } else {
//     displayMessage("Just use Excel/csv file");
//     return [];
//   }
// }
//
// Future<void> UploadData(Map<String, dynamic> data) async {
//   try {
//     await FirebaseFirestore.instance
//         .collection('excel')
//         .add(data);
//     displayMessage("Data uploaded successfully");
//   } catch (e) {
//     print("Error uploading data: $e");
//     displayMessage("Error uploading data: $e");
//   }
// }

// List<List<dynamic>>? _data;
// Future<List<List<dynamic>>> readExcel() async {
//   FilePickerResult? result = await FilePicker.platform.pickFiles(
//     type: FileType.custom,
//     allowedExtensions: ['csv', 'xls', 'xlsx'],
//   );
//   if (result != null) {
//     File file = File(result.files.single.path!);
//     final bytes = await file.readAsBytes();
//     final excel = Excel.decodeBytes(bytes);
//
//     // Get the first worksheet
//     final sheet = excel.tables[excel.tables.keys.first];
//
//     // Get all rows
//     final rows = <List<dynamic>>[];
//     for (var i = 1; i < sheet!.rows.length; i++) {
//       final row = sheet.row(i);
//       String? name,
//           address,
//           pNomber,
//           category,
//           convicted,
//           lat,
//           lng,
//           region,
//           conviction;
//       if (row.length > 0) name = row[0]?.value?.toString() ?? '';
//       if (row.length > 1) address = row[1]?.value?.toString() ?? '';
//       if (row.length > 2) pNomber = row[2]?.value?.toString() ?? '';
//       if (row.length > 3) category = row[3]?.value?.toString() ?? '';
//       if (row.length > 4) convicted = row[4]?.value?.toString() ?? '';
//       if (row.length > 5) lat = row[5]?.value?.toString() ?? '';
//       if (row.length > 6) lng = row[6]?.value?.toString() ?? '';
//       if (row.length > 7) region = row[7]?.value?.toString() ?? '';
//       if (row.length > 8) conviction = row[8]?.value?.toString() ?? '';
//       await UploadData(
//         i.toString(),
//         name ?? '',
//         address ?? '',
//         pNomber ?? "",
//         category ?? "",
//         convicted ?? "",
//         lat ?? "",
//         lng ?? "",
//         region ?? "",
//         conviction ?? "",
//       );
//       rows.add(row);
//     }
//
//     return rows;
//   } else {
//     displayMessage("This file Doesn't sported");
//     return [];
//   }
// }
//
// Future<void> UploadData(
//   String documentId,
//   String name,
//   String address,
//   String pNomber,
//   String category,
//   String convicted,
//   String lat,
//   String lng,
//   String region,
//   String conviction,
// ) async {
//   try {
//     await FirebaseFirestore.instance.collection('excel').doc(documentId).set({
//       'name': name,
//       'address': address,
//       "pNomber": pNomber,
//       "category": category,
//       "convicted": convicted,
//       "lat": lat,
//       "lng": lng,
//       "region": region,
//       "conviction": conviction,
//     });
//     displayMessage("Data uploaded successfully");
//   } catch (e) {
//     print("Error uploading data: $e");
//     displayMessage("Error uploading data: $e");
//   }
// }

// class _ExcelCsvReaderState extends State<ExcelCsvReader> {
//   List<List<dynamic>>? _data;
//
//   Future<List<List<dynamic>>> readExcel(File file) async {
//     final bytes = await file.readAsBytes();
//     final excel = Excel.decodeBytes(bytes);
//
//     // Get the first worksheet
//     final sheet = excel.tables[excel.tables.keys.first];
//
//     // Get all rows
//     final rows = <List<dynamic>>[];
//     for (var i = 1; i < sheet!.rows.length; i++) {
//       final row = sheet.row(i);
//       var row1 = row[0];
//       var row2 = row[1];
//       var row3 = row[2];
//       String? name = row1?.value.toString();
//       String? address = row2?.value.toString();
//       String? lat = row3?.value.toString();
//       UploadData(name!, address!, lat!);
//       rows.add(row);
//     }
//     return rows;
//   }
//
//   Future<void> UploadData(String name, String address, String lat) async {
//     FirebaseFirestore.instance.collection('excel').doc().set({
//       'name': name,
//       'address': address,
//       'lat': lat,
//     }).then((value) {
//       displayMessage("DataUpload Successfully");
//     });
//   }
//
//   void displayMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Excel Reader'),
//       ),
//       body: _data == null
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         itemCount: _data!.length,
//         itemBuilder: (context, index) {
//           final row = _data![index];
//           return ListTile(
//             title: Text(row[0].toString()),
//             subtitle: Text('${row[1]}, ${row[2]}'),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           final result = await FilePicker.platform.pickFiles(
//             type: FileType.custom,
//             allowedExtensions: ['csv', 'xlsx'],
//           );
//           if (result == null) {
//             // User canceled the picker
//             return;
//           }
//           final file = File(result.files.single.path!);
//           readExcel(file).then((data) {
//             setState(() {
//               _data = data;
//             });
//           });
//         },
//         child: const Icon(Icons.upload_file),
//       ),
//     );
//   }
// }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:excel/excel.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:p_dos_admin/main.dart';
//
// class ExcelCsvReader extends StatefulWidget {
//   @override
//   _ExcelCsvReaderState createState() => _ExcelCsvReaderState();
// }
//
// class _ExcelCsvReaderState extends State<ExcelCsvReader> {
//   List<List<dynamic>>? _data;
//
//   Future<List<List<dynamic>>> readExcel() async {
//     final bytes = await rootBundle.load('assets/P-dos.xlsx');
//     final excel = Excel.decodeBytes(bytes.buffer.asUint8List());
//
//     // Get the first worksheet
//     final sheet = excel.tables['sheet'];
//
//     // Get all rows
//     final rows = <List<dynamic>>[];
//     for (var i = 1; i < sheet!.rows.length; i++) {
//       final row = sheet.row(i);
//       var row1 = row[0];
//       var row2 = row[1];
//       var row3 = row[2];
//       String? name = row1?.value.toString();
//       String? address = row2?.value.toString();
//       String? lat = row3?.value.toString();
//       UploadData(name!,address!,lat!);
//       rows.add(row);
//     }
//     return rows;
//   }
//   Future<void> UploadData(String name, String address, String lat) async {
//     FirebaseFirestore.instance.collection('excel').doc().set({
//       'name': name,
//       'address': address,
//       'lat': lat,
//     }).then((value) {
//       displayMessage("DataUpload Successfully");
//     });
// }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Excel Reader'),
//       ),
//       // body: _data == null
//       //     ? const Center(child: CircularProgressIndicator())
//       //     : ListView.builder(
//       //   itemCount: _data!.length,
//       //   itemBuilder: (context, index) {
//       //     final row = _data![index];
//       //     return ListTile(
//       //       title: Text(row[0].toString()),
//       //       subtitle: Text('${row[1]}, ${row[2]}'),
//       //     );
//       //   },
//       // ),
//       floatingActionButton: FloatingActionButton(onPressed: () {
//         readExcel().then((data) {
//           setState(() {
//             _data = data;
//           });
//         });
//       },
//
//       ),
//     );
//   }
// }
//

// body: StreamBuilder<QuerySnapshot>(
//   stream: FirebaseFirestore.instance.collection('excel').snapshots(),
//   builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
//     if (!snapshot.hasData) {
//       return Center(
//         child: CircularProgressIndicator(),
//       );
//     }
//
//     final List<DocumentSnapshot> documents = snapshot.data!.docs;
//
//     return DataTable(
//       columns: [
//         DataColumn(label: Text('Name')),
//         DataColumn(label: Text('Email')),
//         DataColumn(label: Text('Phone')),
//       ],
//       rows: documents.map((doc) {
//         return DataRow(cells: [
//           DataCell(Text(doc['name'])),
//           DataCell(Text(doc['email'])),
//           DataCell(Text(doc['phone'])),
//         ]);
//       }).toList(),
//     );
//   },
// ),
