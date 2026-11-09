import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var storagePolicyBridge: StoragePolicyBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let bridge = StoragePolicyBridge(
        messenger: controller.binaryMessenger
      )
      bridge.register()
      storagePolicyBridge = bridge
    }

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }
}
