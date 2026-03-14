          import 'package:flutter/material.dart';

Widget buildUpdateModal(BuildContext context) {
  return StatefulBuilder(
    builder: (context, setModalState) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              ],
            ),
          ),
        ),
      );
    },
  );
}
