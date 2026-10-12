import 'package:campusconnect/views/admin_home_view.dart';
import 'package:campusconnect/views/hackathon_detail_view.dart';
import 'package:campusconnect/views/hackathon_form_view.dart';
import 'package:campusconnect/views/hackathon_list_view.dart';
import 'package:campusconnect/views/login_view.dart';
import 'package:campusconnect/views/student_hackathon_list_view.dart';
import 'package:campusconnect/views/student_home_view.dart';
import 'package:get/get.dart';

List<GetPage> routes=[
GetPage(name: LoginView.routeName, page: ()=>const LoginView()),
GetPage(name: LoginView.adminRouteName, page: ()=>const LoginView(isAdmin: true)),
GetPage(name: AdminHomeView.routeName, page: ()=>const AdminHomeView()),
GetPage(name: HackathonFormView.routeName, page: ()=>const HackathonFormView()),
GetPage(name: HackathonListView.routeName, page: ()=>const HackathonListView()),
GetPage(name: StudentHomeView.routeName, page: ()=>const StudentHomeView()),
GetPage(name: StudentHackathonListView.routeName, page: ()=>const StudentHackathonListView()),
GetPage(name: HackathonDetailView.routeName, page: ()=>const HackathonDetailView()),
];
