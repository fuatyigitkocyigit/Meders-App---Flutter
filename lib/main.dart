/*
    ========================================================================
    **Meders App**
    Flutter App (works in both IOS and Android) for Meders Medikal A.Ş.
    Created By: Fuat Yiğit Koçyiğit
    Finalization Date: 05.05.2023
    Contact: fuatkocyigit0706@gmail.com
    Description: Read product QR codes, find them from the Excel product list
    and check if they are in the order package list. Update the order package
    after each scan. App aimed to be used in Meders Medikal A.Ş. warehouse.
    ========================================================================
 */

import 'dart:io';
import 'package:flutter_excel/excel.dart' show ByteData, rootBundle;
import 'package:excel/excel.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:vibration/vibration.dart';

void main() => runApp(MaterialApp(home: MyApp(),),);

class MyApp extends StatefulWidget {
  const MyApp({Key? key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _scanBarcode = '';
  String _foundData = 'test';
  String bCellValue = '';
  List<String> columnAValues = [];
  List<String> columnBValues = [];
  List<String> scannedQRs = [];
  //final List<String> testQRs = ['A', 'B', 'C'];
  List<String> packageList = ['10147417', '10147385', '10936812'];
  //First 3 products for Test:
  //0104025515218487, 0104025515218517, 0104038953847218

  get floatingActionButton => null; // List to store scanned QR codes


  Future<void> startBarcodeScanStream() async {
    FlutterBarcodeScanner.getBarcodeStreamReceiver(
        '#ff6666', 'Cancel', true, ScanMode.BARCODE)!
        .listen((barcode) => debugPrint(barcode));
  }

  Future<void> scanQR() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.QR);
      debugPrint(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _scanBarcode = barcodeScanRes;
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.DEFAULT);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    if (!mounted) return;

    readExcelFile(barcodeScanRes);
    sleep(Duration(seconds: 1));
    Vibration.vibrate(duration: 100);

    setState(() {
      _scanBarcode = barcodeScanRes;
      // Add scanned QR code to the list
      scannedQRs.add(_scanBarcode);
    });

    sleep(Duration(seconds: 1));
    //scanBarcodeNormal();
  }

  Future<void> readExcelFile(String searchString) async {
    // Load Excel file from assets
    ByteData data = await rootBundle.load('assets/products.xlsx');
    var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    // Parse Excel file
    var excel = Excel.decodeBytes(bytes);
    var sheet = excel['Sheet1'];

    // Get the maximum number of rows in the sheet
    var maxRows = sheet.maxRows;

    // Iterate through the A column and compare values with the search string
    for (var i = 0; i < maxRows - 1; i++) { // Update loop condition
      var cellValue = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i))?.value.toString().trim(); // Update cell index

      print("The A value : $cellValue");
      print("The B value : $searchString");
      print("");

      HapticFeedback.vibrate();

      // Compare the cell value with the search string
      if (cellValue == searchString.trim()) {
        // Get the value in the corresponding B column cell
        var bCellValue = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i))?.value.toString().trim(); // Update cell index

        i++;
        // Print the B column cell value to console
        print("Match found in row $i. B column value: $bCellValue");

        //set _foundData to bCellValue
        setState(() {
          _foundData = bCellValue!;
        });
        //print('test: $bCellValue');

        //Search the found product in packagaeList
        for(int j = 0; j < packageList.length; j++){
          if(packageList[j] == bCellValue){
            print('The product in package is scanned');
            packageList.remove(bCellValue);
            break;
          }
          else{
            print('The product is not in package');
          }
        }

        break;
      }
      else {
        print("No match found in row $i");
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Meders Medikal QR App'),
          leading: Image.asset('assets/logo.png'),
          backgroundColor: Colors.redAccent,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton.icon(
                onPressed: () => scanBarcodeNormal(),
                icon: Icon(Icons.barcode_reader, color: Colors.white), // Barcode icon
                label: const Text('Automatic Barcode Scanner'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.redAccent, // Red background
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 30), // Increased padding for bigger button
                ),
              ),
              ElevatedButton.icon(
                //convert $_scanBarcode to string
                onPressed: () => scanBarcodeNormal(),
                icon: Icon(Icons.qr_code_scanner, color: Colors.white), // QR code icon
                label: const Text('Automatic QR Scanner'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.redAccent, // Red background
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 30), // Increased padding for bigger button
                ),
              ),
              Container(
                color: Colors.grey[300], // Gray background color
                padding: EdgeInsets.all(30), // Padding for text

                child: Text(
                  'Scan Result: $_scanBarcode',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]), // Updated style for simpler look
                ),
              ),
              Container(
                color: Colors.green[300], // Gray background color
                padding: EdgeInsets.all(30), // Padding for text

                child: Text(
                  'Found Product Code: $_foundData',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]), // Updated style for simpler look
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Packages Left (Malkod Values)"),
                    content: Column(
                      //if the packageList is empty, show the text. Else, show the list
                      children: packageList.isEmpty
                          ? [Text('No package left!')]
                          : List.generate(
                              packageList.length,
                              (index) => Text(packageList[index]),
                            ),
                    ),
    );
    },
    );
    },
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Show the Package'),
            backgroundColor: Colors.redAccent,
            splashColor: Colors.greenAccent,
      ),
      ),
    );
  }
}
