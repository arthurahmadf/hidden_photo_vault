import 'package:get/get.dart';

void closeDialog() {
  Get.closeAllSnackbars();
  while (Get.isDialogOpen!) {
    Get.back();
  }
}

void closeDrawer() {
  Get.closeAllSnackbars();
  while (Get.isBottomSheetOpen!) {
    Get.back();
  }
}

void closeBottomSheet() {
  Get.closeAllSnackbars();
  closeDialog();
  if (Get.isBottomSheetOpen!) {
    Get.back();
  }
}

void getBack() {
  Get.closeAllSnackbars();
  if (Get.isDialogOpen!) {
    Get.back();
  }
  closeBottomSheet();
  Get.back();
}
