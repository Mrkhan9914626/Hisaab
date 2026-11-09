import Flutter
import Foundation

final class StoragePolicyBridge {
  private static let channelName = "expense_tracker/storage_policy"
  private static let directoryName = "ExpenseTracker"
  private static let fileProtection = FileProtectionType.completeUntilFirstUserAuthentication

  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: messenger
    )
  }

  func register() {
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "prepareExpenseDirectory" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard let self = self else {
        result(
          FlutterError(
            code: "privacyPolicyUnavailable",
            message: "Protected storage is unavailable",
            details: nil
          )
        )
        return
      }
      self.prepareExpenseDirectory(result: result)
    }
  }

  private func prepareExpenseDirectory(result: @escaping FlutterResult) {
    do {
      let fileManager = FileManager.default
      guard let applicationSupport = fileManager.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
      ).first else {
        throw StoragePolicyError.unavailable
      }

      var directory = applicationSupport.appendingPathComponent(
        Self.directoryName,
        isDirectory: true
      )

      try fileManager.createDirectory(
        at: directory,
        withIntermediateDirectories: true,
        attributes: [.protectionKey: Self.fileProtection]
      )

      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      values.fileProtection = Self.fileProtection
      try directory.setResourceValues(values)

      let verified = try directory.resourceValues(forKeys: [
        URLResourceKey.isDirectoryKey,
        URLResourceKey.isExcludedFromBackupKey,
        URLResourceKey.fileProtectionKey,
      ])

      guard verified.isDirectory == true,
            verified.isExcludedFromBackup == true,
            verified.fileProtection == Self.fileProtection else {
        throw StoragePolicyError.unverified
      }

      let canonicalPath = directory.resolvingSymlinksInPath().path
      let documentsPath = fileManager.urls(
        for: .documentDirectory,
        in: .userDomainMask
      ).first?.resolvingSymlinksInPath().path
      let cachePath = fileManager.urls(
        for: .cachesDirectory,
        in: .userDomainMask
      ).first?.resolvingSymlinksInPath().path

      if canonicalPath == documentsPath || canonicalPath == cachePath {
        throw StoragePolicyError.unverified
      }

      result(canonicalPath)
    } catch {
      result(
        FlutterError(
          code: "privacyPolicyUnavailable",
          message: "Protected storage could not be verified",
          details: nil
        )
      )
    }
  }
}

private enum StoragePolicyError: Error {
  case unavailable
  case unverified
}
