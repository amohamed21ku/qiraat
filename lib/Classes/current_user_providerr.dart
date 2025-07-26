import 'package:flutter/material.dart';

import 'myUser.dart';

class CurrentUserProvider with ChangeNotifier {
  myUser? _currentUser;

  myUser? get currentUser => _currentUser;

  void setCurrentUser(myUser user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearCurrentUser() {
    _currentUser = null;
    notifyListeners();
  }
}
