import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Use a nullable Future to handle the case where the user might log out 
  // immediately or the Future can't be initialized (though less likely here).
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userDocFuture;

  @override
  void initState() {
    super.initState();
    
    final currentUser = FirebaseAuth.instance.currentUser;

    // Check 1: Ensure the user is authenticated before proceeding.
    if (currentUser == null) {
      print('Current user is not authenticated. Redirecting to login.');
      _handleLogoutAndRedirect();
      return; 
    }
    
    final uid = currentUser.uid; 
    
    _userDocFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(uid) // Use UID here
        .get();
  }
  
  // Refactored logout function to handle the sign out and navigation safely.
  void _handleLogoutAndRedirect() async {
    // 1. Log out the user
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.disconnect();
    // if(GoogleSignIn.instance.currentUser != null)
    // await GoogleSignIn.instance.signOut();
    // 2. Safely redirect to /login
    // Must check if the widget is still mounted before navigating.
    if (!mounted) return; 

    // Use pushReplacementNamed to prevent the user from navigating back
    Navigator.of(context).pushReplacementNamed('/login');
  } 

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userDocFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          // Immediately log out the user and redirect if there's an error fetching data
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleLogoutAndRedirect();
          });
          
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'Error fetching user data: ${snapshot.error}. Logging out...',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleLogoutAndRedirect();
          });
          
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'User data not found in database. Logging out...',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }


        final data = snapshot.data!.data()!;
        final username = data['username'] ?? 'Unknown User'; 

        return Scaffold(
          appBar: AppBar(
            title: Text(username),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _handleLogoutAndRedirect,
              
              ),
              
            ],
            automaticallyImplyLeading: false,
          ),
          body: Center(
            child: Text('Welcome, $username!'),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: 0,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.grade),
                label: 'Monitoring',
              ),
              NavigationDestination(
                icon: Icon(Icons.person),
                label: 'Insights',
              ),
            ],
          ),
        );
      },
    );
  }
}