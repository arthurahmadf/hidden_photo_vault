import Flutter
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var privacyEnabled = false
  private var privacyCover: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      FlutterMethodChannel(
        name: "hidden_photo_vault/privacy",
        binaryMessenger: controller.binaryMessenger
      ).setMethodCallHandler { [weak self] call, response in
        guard call.method == "setSecure",
              let args = call.arguments as? [String: Any],
              let enabled = args["enabled"] as? Bool else {
          response(FlutterMethodNotImplemented)
          return
        }
        self?.privacyEnabled = enabled
        if !enabled { self?.hidePrivacyCover() }
        response(nil)
      }
    }
    return result
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    if privacyEnabled { showPrivacyCover() }
    super.applicationWillResignActive(application)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    hidePrivacyCover()
    super.applicationDidBecomeActive(application)
  }

  private func showPrivacyCover() {
    guard privacyCover == nil, let window = window else { return }
    let cover = UIView(frame: window.bounds)
    cover.backgroundColor = .black
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(cover)
    privacyCover = cover
  }

  private func hidePrivacyCover() {
    privacyCover?.removeFromSuperview()
    privacyCover = nil
  }
}
