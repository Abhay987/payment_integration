import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Payment Integration',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final _razorpay = Razorpay();

  String userName = "***************";    /// Api Key Of Razorpay
  String password = "***************";    /// Secret Key Of Razorpay

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("\n\n$response\n\n");
    // Do something when payment succeeds

    verifySignature(signature: response.signature, paymentId: response.paymentId, orderId: response.orderId);

  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Do something when payment fails
    debugPrint("\n\n$response\n\n");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message ?? '')));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Do something when an external wallet is selected
    debugPrint("\n\n$response\n\n");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.walletName ?? '')));
  }

  Future<void> createOrder()async {

    String basicAuth = "Basic ${base64Encode(utf8.encode("$userName:$password"))}";

    Map<String,dynamic> body = {
      "amount" : "100",
      "currency" : "INR",
      "receipt" : "rcptId_01"
    };

    var response = await http.post(Uri.https("api.razorpay.com","v1/orders"),
    headers: <String,String>{
      "Content-Type" : "application/json",
      "authorization" : basicAuth,
    },
      body: jsonEncode(body),
    );

    if(response.statusCode == 200) {
      openGateway(jsonDecode(response.body)['id']);
    }

    debugPrint("\n\n The response body is : ${response.body}\n\n");

  }

  verifySignature({required String? signature,required String? paymentId,required String? orderId}) async{

    Map<String,dynamic> body = {
      "razorpay_signature" : signature,
      "razorpay_payment_id" : paymentId,
      "razorpay_order_id" : orderId,
    };

    var parts = [];
    body.forEach((key, value) {
      parts.add("${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}");
    });

    var formData = parts.join('&');

    var response = await http.post(Uri.https("10.0.2.2","razorpay_signature_verify.php"),
    headers: {
      "Content_Type" : "application/x-www-form-urlencoded",
    },
      body: formData,
    );

  }

  openGateway(String orderId) {
    var options = {
      "key" : userName,
      "amount" : 100,
      "name" : "Manish Rajput",
      "order_id" : orderId,
      "description" : "Testing Purpose",
      "timeout" : 500,
      "prefill" : {
        "contact" : "7027600605",
        "email" : "abhay@gmail.com",
      },
    };

    _razorpay.open(options);

  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async{
           await createOrder();
          },
          child: const Text('Pay'),
        ),
      ),
    ));
  }
}


