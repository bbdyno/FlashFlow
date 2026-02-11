// swiftlint:disable:this file_name
// swiftlint:disable all
// swift-format-ignore-file
// swiftformat:disable all
// Generated using tuist — https://github.com/tuist/tuist

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
public enum FlashFlowStrings: Sendable {

  public enum Error: Sendable {
  /// An error occurred.
    public static let generic = FlashFlowStrings.tr("Localizable", "error.generic")
  }

  public enum Home: Sendable {
  /// Reload
    public static let reload = FlashFlowStrings.tr("Localizable", "home.reload")
    /// Show Answer
    public static let reveal = FlashFlowStrings.tr("Localizable", "home.reveal")
    /// FlashFlow
    public static let title = FlashFlowStrings.tr("Localizable", "home.title")

    public enum Deck: Sendable {
    /// Select Deck
      public static let select = FlashFlowStrings.tr("Localizable", "home.deck.select")
    }

    public enum Due: Sendable {
    /// No cards due today
      public static let `none` = FlashFlowStrings.tr("Localizable", "home.due.none")
      /// Today %d cards · New %d / Review %d
      public static func summary(_ p1: Int, _ p2: Int, _ p3: Int) -> String {
        return FlashFlowStrings.tr("Localizable", "home.due.summary",p1, p2, p3)
      }
    }

    public enum Error: Sendable {
    /// Close
      public static let close = FlashFlowStrings.tr("Localizable", "home.error.close")
      /// Retry
      public static let retry = FlashFlowStrings.tr("Localizable", "home.error.retry")
      /// Error
      public static let title = FlashFlowStrings.tr("Localizable", "home.error.title")
    }

    public enum Grade: Sendable {
    /// How well did you remember it?
      public static let prompt = FlashFlowStrings.tr("Localizable", "home.grade.prompt")

      public enum Again: Sendable {
      /// Forgot
        public static let subtitle = FlashFlowStrings.tr("Localizable", "home.grade.again.subtitle")
        /// Again
        public static let title = FlashFlowStrings.tr("Localizable", "home.grade.again.title")
      }

      public enum Easy: Sendable {
      /// Very easy
        public static let subtitle = FlashFlowStrings.tr("Localizable", "home.grade.easy.subtitle")
        /// Easy
        public static let title = FlashFlowStrings.tr("Localizable", "home.grade.easy.title")
      }

      public enum Good: Sendable {
      /// Remembered
        public static let subtitle = FlashFlowStrings.tr("Localizable", "home.grade.good.subtitle")
        /// Good
        public static let title = FlashFlowStrings.tr("Localizable", "home.grade.good.title")
      }

      public enum Hard: Sendable {
      /// Barely
        public static let subtitle = FlashFlowStrings.tr("Localizable", "home.grade.hard.subtitle")
        /// Hard
        public static let title = FlashFlowStrings.tr("Localizable", "home.grade.hard.title")
      }
    }
  }

  public enum More: Sendable {
  /// If reminders do not arrive, check iOS Settings > Notifications > FlashFlow.
    public static let footer = FlashFlowStrings.tr("Localizable", "more.footer")
    /// More
    public static let title = FlashFlowStrings.tr("Localizable", "more.title")

    public enum Appinfo: Sendable {
    /// Version: %@ (%@)\nNotifications: Local Push
      public static func body(_ p1: Any, _ p2: Any) -> String {
        return FlashFlowStrings.tr("Localizable", "more.appinfo.body",String(describing: p1), String(describing: p2))
      }
      /// App Info
      public static let title = FlashFlowStrings.tr("Localizable", "more.appinfo.title")
    }

    public enum Common: Sendable {
    /// Cancel
      public static let cancel = FlashFlowStrings.tr("Localizable", "more.common.cancel")
      /// Open Settings
      public static let openSettings = FlashFlowStrings.tr("Localizable", "more.common.open_settings")
    }

    public enum Data: Sendable {
    /// Backup or reset decks, cards, and review history.
      public static let description = FlashFlowStrings.tr("Localizable", "more.data.description")
      /// Export Backup
      public static let export = FlashFlowStrings.tr("Localizable", "more.data.export")
      /// Import Backup
      public static let `import` = FlashFlowStrings.tr("Localizable", "more.data.import")
      /// Reset All Data
      public static let reset = FlashFlowStrings.tr("Localizable", "more.data.reset")
      /// Data
      public static let title = FlashFlowStrings.tr("Localizable", "more.data.title")

      public enum Export: Sendable {
      /// Backup file created. Choose a location from Share.
        public static let done = FlashFlowStrings.tr("Localizable", "more.data.export.done")
      }

      public enum Import: Sendable {
      /// Backup import was cancelled.
        public static let cancelled = FlashFlowStrings.tr("Localizable", "more.data.import.cancelled")
        /// Backup imported.
        public static let done = FlashFlowStrings.tr("Localizable", "more.data.import.done")
        /// Unable to read selected file.
        public static let invalidSelection = FlashFlowStrings.tr("Localizable", "more.data.import.invalid_selection")
        /// %d decks, %d cards, %d reviews
        public static func preview(_ p1: Int, _ p2: Int, _ p3: Int) -> String {
          return FlashFlowStrings.tr("Localizable", "more.data.import.preview",p1, p2, p3)
        }

        public enum Confirm: Sendable {
        /// Import
          public static let action = FlashFlowStrings.tr("Localizable", "more.data.import.confirm.action")
          /// Importing a backup will overwrite current data.\n\nPreview:\n%@
          public static func message(_ p1: Any) -> String {
            return FlashFlowStrings.tr("Localizable", "more.data.import.confirm.message",String(describing: p1))
          }
          /// Import Backup
          public static let title = FlashFlowStrings.tr("Localizable", "more.data.import.confirm.title")
        }
      }

      public enum Reset: Sendable {
      /// All data has been reset.
        public static let done = FlashFlowStrings.tr("Localizable", "more.data.reset.done")

        public enum Confirm: Sendable {
        /// Reset
          public static let action = FlashFlowStrings.tr("Localizable", "more.data.reset.confirm.action")
          /// All decks, cards, and review history will be deleted. This cannot be undone.
          public static let message = FlashFlowStrings.tr("Localizable", "more.data.reset.confirm.message")
          /// Reset All Data
          public static let title = FlashFlowStrings.tr("Localizable", "more.data.reset.confirm.title")
        }
      }
    }

    public enum Reminder: Sendable {
    /// Send a daily reminder at your chosen time.
      public static let description = FlashFlowStrings.tr("Localizable", "more.reminder.description")
      /// Study Reminder
      public static let title = FlashFlowStrings.tr("Localizable", "more.reminder.title")

      public enum Permission: Sendable {
      /// Please allow notifications to use reminders.
        public static let message = FlashFlowStrings.tr("Localizable", "more.reminder.permission.message")
        /// Notification Permission Required
        public static let title = FlashFlowStrings.tr("Localizable", "more.reminder.permission.title")
      }

      public enum Status: Sendable {
      /// Reminder is turned off.
        public static let off = FlashFlowStrings.tr("Localizable", "more.reminder.status.off")
        /// Reminder is set for %02d:%02d every day.
        public static func on(_ p1: Int, _ p2: Int) -> String {
          return FlashFlowStrings.tr("Localizable", "more.reminder.status.on",p1, p2)
        }
      }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension FlashFlowStrings {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = Bundle.module.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
// swiftformat:enable all
// swiftlint:enable all
