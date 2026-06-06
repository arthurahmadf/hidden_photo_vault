// ignore_for_file: non_constant_identifier_names, constant_identifier_names

abstract class AppString {
  // DUMMIES
  static const String NO_IMAGE_URL =
      "https://as1.ftcdn.net/v2/jpg/04/34/72/82/1000_F_434728286_OWQQvAFoXZLdGHlObozsolNeuSxhpr84.jpg";
  static String DUMMY_IMAGE({int? width = 200, int? height = 200}) => "https://picsum.photos/$width/$height";
  static String DUMMY_PROFILE({int? size = 200}) => "https://i.pravatar.cc/$size";
  static String DUMMY_PDF({int? pageSize = 2}) => "https://lorempdf.com/140/85/$pageSize";

  // SYMBOL ANEH2
  static const String MIDDLE_DOT = "\u2022";
  static const String ARROW_RIGHT = "\u2192";

  // LOGGING MESSAGE
  static String REPO_ERROR({required String repoName, String? errorCode = "no_error_message/code"}) {
    return "REPO: $repoName $errorCode";
  }
}
