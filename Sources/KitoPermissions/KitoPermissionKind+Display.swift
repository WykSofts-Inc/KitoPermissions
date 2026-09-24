//
//  KitoPermissionKind+Display.swift
//  KitoPermissions
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

public extension KitoPermissionKind {
    /// A short, user-facing name: "Camera", "Location (Always)".
    var displayName: String {
        switch self {
        case .camera: return "Camera"
        case .photoLibrary: return "Photos"
        case .microphone: return "Microphone"
        case .locationWhenInUse: return "Location"
        case .locationAlways: return "Location (Always)"
        case .notifications: return "Notifications"
        case .contacts: return "Contacts"
        case .calendar: return "Calendar"
        case .reminders: return "Reminders"
        case .speechRecognition: return "Speech Recognition"
        case .mediaLibrary: return "Apple Music"
        case .bluetooth: return "Bluetooth"
        case .tracking: return "Tracking"
        }
    }

    /// The SF Symbol that stands for this permission.
    var systemImage: String {
        switch self {
        case .camera: return "camera.fill"
        case .photoLibrary: return "photo.on.rectangle.angled"
        case .microphone: return "mic.fill"
        case .locationWhenInUse: return "location.fill"
        case .locationAlways: return "location.north.circle.fill"
        case .notifications: return "bell.badge.fill"
        case .contacts: return "person.crop.circle.fill"
        case .calendar: return "calendar"
        case .reminders: return "checklist"
        case .speechRecognition: return "waveform"
        case .mediaLibrary: return "music.note"
        case .bluetooth: return "dot.radiowaves.left.and.right"
        case .tracking: return "hand.raised.fill"
        }
    }

    /// Smaller symbols that orbit the main one in the illustrated primer.
    var companionSymbols: [String] {
        switch self {
        case .camera: return ["qrcode.viewfinder", "doc.viewfinder", "person.crop.square"]
        case .photoLibrary: return ["photo", "heart.fill", "square.and.arrow.up"]
        case .microphone: return ["waveform", "phone.fill", "music.mic"]
        case .locationWhenInUse, .locationAlways: return ["mappin", "car.fill", "bicycle"]
        case .notifications: return ["shippingbox.fill", "message.fill", "creditcard.fill"]
        case .contacts: return ["person.2.fill", "phone.fill", "gift.fill"]
        case .calendar: return ["clock.fill", "person.2.fill", "airplane"]
        case .reminders: return ["checkmark.circle.fill", "bell.fill", "list.bullet"]
        case .speechRecognition: return ["text.bubble.fill", "character.cursor.ibeam", "globe"]
        case .mediaLibrary: return ["music.note.list", "headphones", "radio.fill"]
        case .bluetooth: return ["headphones", "applewatch", "speaker.wave.2.fill"]
        case .tracking: return ["chart.bar.fill", "sparkles", "megaphone.fill"]
        }
    }

    /// The accent used for this permission's icon tile.
    var tint: Color {
        switch self {
        case .camera: return Color(red: 0.20, green: 0.22, blue: 0.28)
        case .photoLibrary: return Color(red: 0.95, green: 0.42, blue: 0.29)
        case .microphone: return Color(red: 0.93, green: 0.27, blue: 0.40)
        case .locationWhenInUse, .locationAlways: return Color(red: 0.10, green: 0.48, blue: 0.98)
        case .notifications: return Color(red: 0.96, green: 0.29, blue: 0.27)
        case .contacts: return Color(red: 0.45, green: 0.47, blue: 0.53)
        case .calendar: return Color(red: 0.93, green: 0.30, blue: 0.24)
        case .reminders: return Color(red: 0.98, green: 0.60, blue: 0.10)
        case .speechRecognition: return Color(red: 0.55, green: 0.33, blue: 0.95)
        case .mediaLibrary: return Color(red: 0.98, green: 0.24, blue: 0.40)
        case .bluetooth: return Color(red: 0.12, green: 0.45, blue: 0.95)
        case .tracking: return Color(red: 0.19, green: 0.70, blue: 0.55)
        }
    }

    /// The Settings page to send someone to when this permission is off. Notifications have
    /// their own page; everything else lives on the app's Settings page.
    var settingsURL: URL? {
        switch self {
        case .notifications: return URL(string: UIApplication.openNotificationSettingsURLString)
        default: return URL(string: UIApplication.openSettingsURLString)
        }
    }
}

public extension KitoPermissionStatus {
    /// Allowed, in any form (including limited or provisional).
    var isGranted: Bool { self == .granted }

    /// Whether the system will still show its prompt.
    var canPrompt: Bool { self == .notDetermined }

    /// A short, user-facing label: "Allowed", "Off", "Not asked", "Restricted".
    var label: String {
        switch self {
        case .granted: return "Allowed"
        case .denied: return "Off"
        case .notDetermined: return "Not asked"
        case .restricted: return "Restricted"
        }
    }
}

/// Opens the Settings page where a permission can be turned back on.
@MainActor
public enum KitoPermissionSettings {
    public static func open(for kind: KitoPermissionKind? = nil) {
        guard let url = kind?.settingsURL ?? URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
