import 'package:flutter/material.dart';

class ScreenToModal {
  static bool isModalOpen = false;
  static int modalDepth = 0;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double height = 0.9,
    bool replaceCurrent = false,
  }) {
    if (replaceCurrent && modalDepth > 0) {
      Navigator.of(context, rootNavigator: true).pop();
      modalDepth--;
    }
    
    modalDepth++;
    isModalOpen = true;
    
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * height,
          margin: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Scaffold(
              body: WillPopScope(
                onWillPop: () async {
                  modalDepth--;
                  if (modalDepth <= 0) {
                    isModalOpen = false;
                    modalDepth = 0;
                  }
                  return true;
                },
                child: child,
              ),
            ),
          ),
        );
      },
    ).then((value) {
      modalDepth--;
      if (modalDepth <= 0) {
        isModalOpen = false;
        modalDepth = 0;
      }
      return value;
    });
  }
  
  static Future<T?> showNested<T>({
    required BuildContext context,
    required Widget child,
    double height = 0.85,
  }) {
    modalDepth++;
    isModalOpen = true;
    
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * height,
          margin: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Scaffold(
              body: WillPopScope(
                onWillPop: () async {
                  modalDepth--;
                  if (modalDepth <= 0) {
                    isModalOpen = false;
                    modalDepth = 0;
                  }
                  return true;
                },
                child: child,
              ),
            ),
          ),
        );
      },
    ).then((value) {
      modalDepth--;
      if (modalDepth <= 0) {
        isModalOpen = false;
        modalDepth = 0;
      }
      return value;
    });
  }
  
  static void closeAllModals(BuildContext context) {
    Navigator.of(context, rootNavigator: true).popUntil((route) => !route.isFirst);
    modalDepth = 0;
    isModalOpen = false;
  }
  
  static void closeCurrentModal(BuildContext context) {
    if (modalDepth > 0) {
      Navigator.of(context, rootNavigator: true).pop();
      modalDepth--;
      if (modalDepth <= 0) {
        isModalOpen = false;
        modalDepth = 0;
      }
    }
  }
}