//
//  KitoPermissionPrimingContent.swift
//  KitoPermissions
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// How a priming screen presents itself.
public enum KitoPermissionPrimingStyle: String, CaseIterable, Sendable {
    /// A floating card over a dimmed screen.
    case card
    /// A full-screen page with an animated illustration.
    case illustration
    /// A compact banner that sits inline in your content.
    case banner
}

/// The words on a priming screen: why you're asking and what the person gets.
public struct KitoPermissionPrimingContent: Equatable, Sendable {
    public var title: String
    public var message: String
    /// Up to three short benefits, shown as a checklist.
    public var benefits: [String]
    public var allowTitle: String
    public var laterTitle: String

    public init(
        title: String,
        message: String,
        benefits: [String] = [],
        allowTitle: String = "Continue",
        laterTitle: String = "Not now"
    ) {
        self.title = title
        self.message = message
        self.benefits = benefits
        self.allowTitle = allowTitle
        self.laterTitle = laterTitle
    }

    /// Sensible, specific copy for each permission — replace it with your own reason when you can.
    public static func standard(for kind: KitoPermissionKind) -> KitoPermissionPrimingContent {
        switch kind {
        case .camera:
            return .init(title: "Scan in a snap", message: "Use your camera to scan receipts, QR codes and IDs. Nothing is saved unless you choose to.",
                         benefits: ["Scan QR codes to pay", "Snap receipts for expenses", "Photos stay on your phone"], allowTitle: "Allow camera")
        case .photoLibrary:
            return .init(title: "Pick your best shots", message: "Choose photos for your profile and posts. We only see the ones you pick.",
                         benefits: ["Share from your library", "Save edits back", "You choose what's shared"], allowTitle: "Allow photos")
        case .microphone:
            return .init(title: "Talk, don't type", message: "Send voice notes and make calls. We only listen while you hold the button.",
                         benefits: ["Voice notes in chats", "Crystal-clear calls", "Never recorded in the background"], allowTitle: "Allow microphone")
        case .locationWhenInUse:
            return .init(title: "Find what's near you", message: "Share your location to see nearby places and accurate delivery times.",
                         benefits: ["Faster delivery estimates", "Pickup points near you", "Only while you use the app"], allowTitle: "Share location")
        case .locationAlways:
            return .init(title: "Arrive without asking", message: "Let the app know when you're close so your rider can find you, even when it's closed.",
                         benefits: ["Hands-free arrival alerts", "Safer night rides", "Turn it off any time"], allowTitle: "Allow always")
        case .notifications:
            return .init(title: "Know the moment it ships", message: "Get updates about your orders, payments and messages. No spam, ever.",
                         benefits: ["Delivery and payment updates", "Replies from people you know", "Quiet hours you control"], allowTitle: "Turn on notifications")
        case .contacts:
            return .init(title: "Find your people", message: "See which friends are already here and send money to them in a tap.",
                         benefits: ["Send money by name", "Split bills faster", "We never message your contacts"], allowTitle: "Allow contacts")
        case .calendar:
            return .init(title: "Never miss a booking", message: "Add your bookings and trips straight to your calendar.",
                         benefits: ["One-tap add to calendar", "Travel times included", "We don't read other events"], allowTitle: "Allow calendar")
        case .reminders:
            return .init(title: "Remember to pay", message: "Create reminders for bills and subscriptions before they're due.",
                         benefits: ["Bill reminders", "Subscription renewals", "Stays in your Reminders"], allowTitle: "Allow reminders")
        case .speechRecognition:
            return .init(title: "Search by voice", message: "Turn what you say into text for search and dictation.",
                         benefits: ["Hands-free search", "Works in Swahili and English", "Audio isn't stored"], allowTitle: "Allow speech")
        case .mediaLibrary:
            return .init(title: "Play your music", message: "Add songs from your library to your workouts and stories.",
                         benefits: ["Soundtracks for stories", "Workout playlists", "Nothing leaves your phone"], allowTitle: "Allow music")
        case .bluetooth:
            return .init(title: "Connect your gear", message: "Pair headphones, speakers and trackers nearby.",
                         benefits: ["Pair in seconds", "Find lost accessories", "Only nearby devices"], allowTitle: "Allow Bluetooth")
        case .tracking:
            return .init(title: "Keep it relevant", message: "Allow tracking for offers that match what you like. Either way, the app works the same.",
                         benefits: ["Fewer irrelevant ads", "Deals you actually want", "Change it any time"], allowTitle: "Continue")
        }
    }
}
