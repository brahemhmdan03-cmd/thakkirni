import AppIntents
import Flutter
import UIKit
import UserNotifications

/// Holds a "start listening" request from Siri, a shortcut or a link until Flutter picks it up.
final class ListenRequest {
  static let shared = ListenRequest()
  private(set) var pending = false
  var channel: FlutterMethodChannel?

  func request() {
    pending = true
    // If Flutter is already running it opens listening now and clears the flag;
    // otherwise it picks the flag up when it starts.
    DispatchQueue.main.async {
      self.channel?.invokeMethod("listen", arguments: nil)
    }
  }

  func consume() -> Bool {
    let was = pending
    pending = false
    return was
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "thakkirni/launch",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { call, result in
      if call.method == "consumeListenRequest" {
        result(ListenRequest.shared.consume())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    ListenRequest.shared.channel = channel
  }
}

// MARK: - Siri: "Hey Siri, ذكرني"

struct StartListeningIntent: AppIntent {
  static var title: LocalizedStringResource = "Remind me"
  static var description = IntentDescription("Opens Thakkirni and asks what to remind you of.")
  static var openAppWhenRun: Bool = true

  @MainActor
  func perform() async throws -> some IntentResult {
    ListenRequest.shared.request()
    return .result()
  }
}

struct ThakkirniShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: StartListeningIntent(),
      phrases: [
        "\(.applicationName)",
        "Open \(.applicationName)",
        "Hey \(.applicationName)",
        "Remind me with \(.applicationName)",
      ],
      shortTitle: "Remind me",
      systemImageName: "mic.fill"
    )
  }

  static var shortcutTileColor: ShortcutTileColor = .purple
}
