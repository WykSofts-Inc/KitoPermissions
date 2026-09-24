//
//  KitoPermissionPrimer.swift
//  KitoPermissions
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// Explains a permission before the one-shot system prompt, then asks, then follows through:
/// "allowed" celebrates, "denied" turns into a short Settings recovery with a button that opens
/// the right page. Three looks — a floating card, a full-screen illustration and an inline banner.
///
/// ```swift
/// KitoPermissionPrimer(kind: .camera, style: .card) { status in … }
/// ```
public struct KitoPermissionPrimer: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    let kind: KitoPermissionKind
    let style: KitoPermissionPrimingStyle
    let content: KitoPermissionPrimingContent
    let accent: Color
    let requester: KitoPermissionRequester
    let onResult: (KitoPermissionStatus) -> Void
    let onDismiss: (() -> Void)?

    @State private var phase: KitoPermissionPrimerPhase = .priming
    @State private var pulse = false

    public init(
        kind: KitoPermissionKind,
        style: KitoPermissionPrimingStyle = .card,
        content: KitoPermissionPrimingContent? = nil,
        accent: Color? = nil,
        requester: KitoPermissionRequester = .live,
        onDismiss: (() -> Void)? = nil,
        onResult: @escaping (KitoPermissionStatus) -> Void = { _ in }
    ) {
        self.kind = kind
        self.style = style
        self.content = content ?? .standard(for: kind)
        self.accent = accent ?? kind.tint
        self.requester = requester
        self.onDismiss = onDismiss
        self.onResult = onResult
    }

    public var body: some View {
        Group {
            switch style {
            case .card: card
            case .illustration: illustration
            case .banner: banner
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.82), value: phase)
        .task {
            let status = await requester.status(kind)
            if status != .notDetermined { phase = KitoPermissionPrimerPhase(status: status) }
        }
        .onAppear { if !reduceMotion { pulse = true } }
    }

    // MARK: Actions

    private func allow() {
        guard phase == .priming else { return }
        phase = .requesting
        Task {
            let status = await requester.request(kind)
            phase = KitoPermissionPrimerPhase(status: status)
            onResult(status)
        }
    }

    private func openSettings() {
        if let url = kind.settingsURL { openURL(url) }
    }

    // MARK: Card

    private var card: some View {
        VStack(spacing: theme.spacing.lg) {
            KitoPermissionBadge(kind: kind, phase: phase, accent: accent, size: 74, pulse: pulse)
                .padding(.top, theme.spacing.sm)
            textBlock(alignment: .center)
            if phase == .priming || phase == .requesting {
                benefitList.padding(.horizontal, theme.spacing.xs)
            } else if phase == .denied {
                KitoPermissionRecoverySteps(kind: kind, accent: accent)
            }
            buttons
        }
        .padding(theme.spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(theme.colors.surface)
                .shadow(color: .black.opacity(0.18), radius: 30, y: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(LinearGradient(colors: [accent.opacity(0.35), theme.colors.border.opacity(0.4)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }

    // MARK: Illustration

    private var illustration: some View {
        VStack(spacing: 0) {
            KitoPermissionIllustration(kind: kind, phase: phase, accent: accent, animated: !reduceMotion)
                .frame(maxWidth: .infinity)
                .frame(height: 300)
            VStack(spacing: theme.spacing.lg) {
                textBlock(alignment: .center)
                if phase == .denied {
                    KitoPermissionRecoverySteps(kind: kind, accent: accent)
                } else if phase != .granted {
                    benefitList
                }
            }
            .padding(.horizontal, theme.spacing.xl)
            Spacer(minLength: theme.spacing.lg)
            buttons.padding(.horizontal, theme.spacing.xl).padding(.bottom, theme.spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [accent.opacity(0.22), theme.colors.background, theme.colors.background], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    // MARK: Banner

    private var banner: some View {
        HStack(alignment: .center, spacing: theme.spacing.md) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: [accent, accent.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 46, height: 46)
                    .overlay(Image(systemName: kind.systemImage).font(.system(size: 20, weight: .semibold)).foregroundStyle(.white))
                KitoPermissionPhaseDot(phase: phase)
                    .offset(x: 5, y: 5)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(bannerTitle)
                    .font(theme.typography.bodyEmphasized)
                    .foregroundStyle(theme.colors.onSurface)
                Text(bannerMessage)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onSurface.opacity(0.65))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            bannerAction
            if let onDismiss, phase != .requesting {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.colors.onSurface.opacity(0.5))
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(theme.colors.surfaceMuted))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }
        }
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(theme.colors.surface)
                .shadow(color: accent.opacity(0.18), radius: 18, y: 8)
        )
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(accent.opacity(0.25), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private var bannerTitle: String {
        switch phase {
        case .priming, .requesting: return content.title
        case .granted: return "\(kind.displayName) is on"
        case .denied: return "\(kind.displayName) is off"
        }
    }

    private var bannerMessage: String {
        switch phase {
        case .priming, .requesting: return content.message
        case .granted: return "Thanks — you can change this in Settings any time."
        case .denied: return "Turn it on in Settings to use this feature."
        }
    }

    @ViewBuilder
    private var bannerAction: some View {
        switch phase {
        case .priming:
            Button("Allow", action: allow)
                .buttonStyle(KitoPermissionCapsuleStyle(fill: theme.colors.onSurface, label: theme.colors.surface, compact: true))
        case .requesting:
            ProgressView().controlSize(.small).frame(width: 60)
        case .granted:
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(theme.colors.success)
                .symbolEffect(.bounce, value: phase)
        case .denied:
            Button("Settings", action: openSettings)
                .buttonStyle(KitoPermissionCapsuleStyle(fill: accent.opacity(0.14), label: accent, compact: true))
        }
    }

    // MARK: Shared pieces

    private func textBlock(alignment: TextAlignment) -> some View {
        VStack(spacing: theme.spacing.sm) {
            Text(headline)
                .font(theme.typography.titleLarge.weight(.bold))
                .foregroundStyle(theme.colors.onSurface)
                .contentTransition(.opacity)
            Text(subheadline)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.onSurface.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(alignment)
    }

    private var headline: String {
        switch phase {
        case .priming, .requesting: return content.title
        case .granted: return "You're all set"
        case .denied: return "\(kind.displayName) is turned off"
        }
    }

    private var subheadline: String {
        switch phase {
        case .priming, .requesting: return content.message
        case .granted: return "\(kind.displayName) access is on. You can change it in Settings whenever you like."
        case .denied: return "No problem. If you change your mind, it takes three taps in Settings."
        }
    }

    private var benefitList: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            ForEach(content.benefits, id: \.self) { benefit in
                HStack(spacing: theme.spacing.sm) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(accent)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(accent.opacity(0.14)))
                    Text(benefit)
                        .font(theme.typography.label)
                        .foregroundStyle(theme.colors.onSurface.opacity(0.85))
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var buttons: some View {
        VStack(spacing: theme.spacing.xs) {
            switch phase {
            case .priming, .requesting:
                Button(action: allow) {
                    ZStack {
                        Text(content.allowTitle).opacity(phase == .requesting ? 0 : 1)
                        if phase == .requesting { ProgressView().tint(theme.colors.surface) }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(KitoPermissionCapsuleStyle(fill: theme.colors.onSurface, label: theme.colors.surface))
                .disabled(phase == .requesting)
                if let onDismiss {
                    Button(content.laterTitle, action: onDismiss)
                        .font(theme.typography.label)
                        .foregroundStyle(theme.colors.onSurface.opacity(0.6))
                        .frame(minHeight: 40)
                }
            case .granted:
                Button { onDismiss?() } label: { Text("Continue").frame(maxWidth: .infinity) }
                    .buttonStyle(KitoPermissionCapsuleStyle(fill: theme.colors.onSurface, label: theme.colors.surface))
            case .denied:
                Button(action: openSettings) {
                    Label("Open Settings", systemImage: "gearshape.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(KitoPermissionCapsuleStyle(fill: theme.colors.onSurface, label: theme.colors.surface))
                if let onDismiss {
                    Button("Maybe later", action: onDismiss)
                        .font(theme.typography.label)
                        .foregroundStyle(theme.colors.onSurface.opacity(0.6))
                        .frame(minHeight: 40)
                }
            }
        }
    }
}

// MARK: - Pieces

/// The permission's icon in a gradient disc with a soft pulse, badged with the phase.
struct KitoPermissionBadge: View {
    let kind: KitoPermissionKind
    let phase: KitoPermissionPrimerPhase
    let accent: Color
    let size: CGFloat
    let pulse: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.12))
                .frame(width: size * 1.55, height: size * 1.55)
                .scaleEffect(pulse ? 1.08 : 0.94)
                .opacity(pulse ? 0.6 : 1)
                .animation(pulse ? .easeInOut(duration: 1.6).repeatForever(autoreverses: true) : nil, value: pulse)
            Circle()
                .fill(LinearGradient(colors: [accent, accent.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
                .shadow(color: accent.opacity(0.45), radius: 14, y: 8)
            Image(systemName: phase == .granted ? "checkmark" : kind.systemImage)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
                .contentTransition(.symbolEffect(.replace))
            KitoPermissionPhaseDot(phase: phase, size: size * 0.32)
                .offset(x: size * 0.36, y: size * 0.36)
        }
        .accessibilityHidden(true)
    }
}

/// A small corner badge: a red slash when denied, nothing otherwise.
struct KitoPermissionPhaseDot: View {
    @Environment(\.kitoTheme) private var theme
    let phase: KitoPermissionPrimerPhase
    var size: CGFloat = 20

    var body: some View {
        if phase == .denied {
            Image(systemName: "xmark")
                .font(.system(size: size * 0.45, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(theme.colors.danger))
                .overlay(Circle().stroke(theme.colors.surface, lineWidth: 2.5))
                .transition(.scale.combined(with: .opacity))
        }
    }
}

/// Three numbered steps to turn a permission back on in Settings.
public struct KitoPermissionRecoverySteps: View {
    @Environment(\.kitoTheme) private var theme
    let kind: KitoPermissionKind
    let accent: Color

    public init(kind: KitoPermissionKind, accent: Color? = nil) {
        self.kind = kind
        self.accent = accent ?? kind.tint
    }

    private var appName: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? "this app"
    }

    private var steps: [(symbol: String, text: String)] {
        [
            ("gearshape.fill", "Open Settings"),
            (kind == .notifications ? "bell.fill" : "app.fill", kind == .notifications ? "Tap Notifications" : "Find \(appName)"),
            ("switch.2", "Turn on \(kind.displayName)"),
        ]
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: theme.spacing.md) {
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(accent.opacity(0.14)))
                    Text(step.text)
                        .font(theme.typography.label)
                        .foregroundStyle(theme.colors.onSurface)
                    Spacer()
                    Image(systemName: step.symbol)
                        .foregroundStyle(theme.colors.onSurface.opacity(0.35))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, theme.spacing.md)
                if index < steps.count - 1 {
                    Divider().padding(.leading, 54)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.colors.surfaceMuted))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("To turn on \(kind.displayName): open Settings, find \(appName), and turn on \(kind.displayName).")
    }
}

/// Rings, orbiting companion symbols and a big central badge.
struct KitoPermissionIllustration: View {
    @Environment(\.kitoTheme) private var theme
    let kind: KitoPermissionKind
    let phase: KitoPermissionPrimerPhase
    let accent: Color
    let animated: Bool

    @State private var spin = false
    @State private var breathe = false

    var body: some View {
        ZStack {
            ForEach(0..<3) { ring in
                Circle()
                    .stroke(accent.opacity(0.16 - Double(ring) * 0.04), lineWidth: 1.2)
                    .frame(width: 150 + CGFloat(ring) * 70, height: 150 + CGFloat(ring) * 70)
                    .scaleEffect(breathe ? 1.03 : 0.98)
            }
            ZStack {
                ForEach(Array(kind.companionSymbols.enumerated()), id: \.offset) { index, symbol in
                    let angle = Double(index) / Double(max(kind.companionSymbols.count, 1)) * 2 * .pi - .pi / 2
                    Image(systemName: symbol)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(accent)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(theme.colors.surface).shadow(color: .black.opacity(0.12), radius: 8, y: 4))
                        .rotationEffect(.degrees(spin ? -360 : 0))
                        .offset(x: cos(angle) * 110, y: sin(angle) * 110)
                }
            }
            .rotationEffect(.degrees(spin ? 360 : 0))

            KitoPermissionBadge(kind: kind, phase: phase, accent: accent, size: 96, pulse: animated)
        }
        .saturation(phase == .denied ? 0.2 : 1)
        .onAppear {
            guard animated else { return }
            withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) { spin = true }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { breathe = true }
        }
        .accessibilityHidden(true)
    }
}

/// A full-width or compact capsule button.
struct KitoPermissionCapsuleStyle: ButtonStyle {
    let fill: Color
    let label: Color
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 14 : 16, weight: .semibold))
            .foregroundStyle(label)
            .padding(.horizontal, compact ? 14 : 20)
            .frame(minHeight: compact ? 34 : 52)
            .background(Capsule().fill(fill))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
