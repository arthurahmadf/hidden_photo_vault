import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/media_viewer_controller.dart';

class MediaViewerView extends GetView<MediaViewerController> {
  const MediaViewerView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediaViewerView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'MediaViewerView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
