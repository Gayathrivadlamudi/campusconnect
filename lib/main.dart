import 'package:campusconnect/firebase_options.dart';
import 'package:campusconnect/utils/constants.dart';
import 'package:campusconnect/utils/init_routes.dart';
import 'package:campusconnect/views/login_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("🔥 Firebase initialized successfully");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      getPages: routes,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState(){
    super.initState();
    Future.delayed(const Duration(seconds: 1)).then((value){
print("ji");
Get.toNamed(LoginView.routeName);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  Container(
        color: Colors.grey,
        child: SafeArea(child:
        Image.asset(Constants.ImagePath+'splashscreen.png',fit: BoxFit.fill,width: Get.width,height: Get.height,)),
      )
    );
  }
}
