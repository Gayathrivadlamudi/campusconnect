// import 'package:flutter/material.dart';
//
// import '../utils/constants.dart';
//
// class LoginnView extends StatefulWidget {
//   const LoginnView({super.key});
//   static const String routeName="/Loginnview";
//   @override
//   State<LoginnView> createState()=>_LoginnViewState();
// }
// class _LoginnViewState extends State<LoginnView>{
//   @override
//   void initState(){
//     super.initState();
//
//   }
//   @override
//   Widget build(BuildContext context){
//     return Scaffold(
//       body:SingleChildScrollView(
//         child: Column(
//           children: [
//             buildeHeader()
//           ],
//         ),
//       )
//
//     );
//   }
//   Widget buildHeader(){
//     return ClipPath(
//       clipper: WaveClipper(),
//       child: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Constants.deepBlue,
//                 Constants.primaryBlue,
//                 Constants.lightBlue,
//           ])
//         ),
//         child:Stack(
//           children: [
//             Positioned(top: -70, right: -30, child: bubble(160, 0.10)),
//             Positioned(top: 90, left: -50, child: bubble(120, 0.08)),
//           ],
//         )
//       ),
//     );
//   }
//   Widget bubble(double size,double opacity){
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: Colors.white.withValues(alpha: opacity),
//       ),
//     )
//   }
// }
//
// class WaveClipper extends CustomClipper<Path>{
//     @override
//     Path getClip(Size size){
//       final path = Path();
//       //Draw a straight line from the current position to the point (0, size.height - 50)
//       path.lineTo(0, size.height - 50);
//       path.quadraticBezierTo(  size.width * 0.25,
//         size.height,
//         size.width * 0.5,
//         size.height - 30,);
//       path.quadraticBezierTo(  size.width * 0.75,
//         size.height - 60,
//         size.width,
//         size.height - 20,);
//       path
//         ..lineTo(size.width, 0)
//         ..close();
//       return path;
//     }
//     @override
//     //We need shouldReclip() to tell Flutter whether it should create the shape again when the clipper changes.
//     bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
// }
//
//
