//
//  KitoPermissionsDashboard.swift
//  KitoPermissions
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// Every permission your app uses on one screen: a summary ring, then a row each with why you
/// need it and the one action that makes sense — Allow when it hasn't been asked, Settings when
/// it's off. Statuses refresh when the app comes back from Settings.
///
/// It doesn't scroll by itself; put it in a `ScrollView` (or a `List` row) of your own.
public struct KitoPermissionsDashboard: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let kinds: [KitoPermissionKind]
    let reasons: [KitoPermissionKind: String]
    let title: String
    let requester: KitoPermissionRequester

    @State private var statuses: [KitoPermissionKind: KitoPermissionStatus] = [:]
    @State private var requesting: KitoPermissionKind?

    public init(
        _ kinds: [KitoPermissionKind],
        reasons: [KitoPermissionKind: String] = [:],
        title: String = "App permissions",
        requester: KitoPermissionRequester = .live
    ) {
        self.kinds = kinds
        self.reasons = reasons
        self.title = title
        self.requester = requester
    }

    private var grantedCount: Int { kinds.filter { statuses[$0] == .granted }.count }

    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            summary
            VStack(spacing: 0) {
                ForEach(Array(kinds.enumerated()), id: \.element) { index, kind in
                    row(kind)
                    if index < kinds.count - 1 { Divider().padding(.leading, 70) }
                }
            }
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(theme.colors.surface))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(theme.colors.border.opacity(0.6), lineWidth: 1))
        }
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.85), value: statuses)
        .task { await refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refresh() } }
        }
    }

    private func refresh() async {
        var next: [KitoPermissionKind: KitoPermissionStatus] = [:]
        for kind in kinds { next[kind] = await requester.status(kind) }
        statuses = next
    }

    // MARK: Summary

    private var summary: some View {
        HStack(spacing: theme.spacing.lg) {
            ZStack {
                Circle().stroke(theme.colors.onSurface.opacity(0.08), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: kinds.isEmpty ? 0 : CGFloat(grantedCount) / CGFloat(kinds.count))
                    .stroke(AngularGradient(colors: [theme.colors.success, theme.colors.primary, theme.colors.success], center: .center), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(grantedCount)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("of \(kinds.count)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(theme.colors.onSurface.opacity(0.55))
                }
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(theme.typography.titleMedium)
                    .foregroundStyle(theme.colors.onSurface)
                Text(summaryLine)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onSurface.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(theme.spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [theme.colors.primary.opacity(0.14), theme.colors.success.opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(grantedCount) of \(kinds.count) allowed. \(summaryLine)")
    }

    private var summaryLine: String {
        let off = kinds.filter { statuses[$0] == .denied }.count
        let unasked = kinds.filter { (statuses[$0] ?? .notDetermined) == .notDetermined }.count
        if off == 0 && unasked == 0 { return "Everything this app needs is on." }
        var parts: [String] = []
        if unasked > 0 { parts.append("\(unasked) not asked yet") }
        if off > 0 { parts.append("\(off) turned off") }
        return parts.joined(separator: " · ")
    }

    // MARK: Rows

    private func row(_ kind: KitoPermissionKind) -> some View {
        let status = statuses[kind] ?? .notDetermined
        return HStack(spacing: theme.spacing.md) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(colors: [kind.tint, kind.tint.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 42, height: 42)
                .overlay(Image(systemName: kind.systemImage).font(.system(size: 18, weight: .semibold)).foregroundStyle(.white))
                .saturation(status == .denied ? 0.15 : 1)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(kind.displayName)
                    .font(theme.typography.bodyEmphasized)
                    .foregroundStyle(theme.colors.onSurface)
                Text(reasons[kind] ?? KitoPermissionPrimingContent.standard(for: kind).message)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onSurface.opacity(0.6))
                    .lineLimit(2)
            }
            Spacer(minLength: theme.spacing.xs)
            action(for: kind, status: status)
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, theme.spacing.md)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func action(for kind: KitoPermissionKind, status: KitoPermissionStatus) -> some View {
        if requesting == kind {
            ProgressView().controlSize(.small).frame(width: 64)
        } else {
            switch status {
            case .notDetermined:
                Button("Allow") {
                    requesting = kind
                    Task {
                        statuses[kind] = await requester.request(kind)
                        requesting = nil
                    }
                }
                .buttonStyle(KitoPermissionCapsuleStyle(fill: theme.colors.onSurface, label: theme.colors.surface, compact: true))
                .accessibilityLabel("Allow \(kind.displayName)")
            case .granted:
                KitoPermissionStatusBadge(status: status)
            case .denied:
                Button {
                    if let url = kind.settingsURL { openURL(url) }
                } label: {
                    HStack(spacing: 3) { Text("Settings"); Image(systemName: "arrow.up.forward").font(.system(size: 10, weight: .bold)) }
                }
                .buttonStyle(KitoPermissionCapsuleStyle(fill: theme.colors.danger.opacity(0.12), label: theme.colors.danger, compact: true))
                .accessibilityLabel("\(kind.displayName) is off. Open Settings")
            case .restricted:
                KitoPermissionStatusBadge(status: status)
            }
        }
    }
}

/// A coloured pill for a permission status: green Allowed, red Off, grey Not asked / Restricted.
public struct KitoPermissionStatusBadge: View {
    @Environment(\.kitoTheme) private var theme
    let status: KitoPermissionStatus

    public init(status: KitoPermissionStatus) {
        self.status = status
    }

    private var color: Color {
        switch status {
        case .granted: return theme.colors.success
        case .denied: return theme.colors.danger
        case .notDetermined, .restricted: return theme.colors.onSurface.opacity(0.55)
        }
    }

    private var symbol: String {
        switch status {
        case .granted: return "checkmark"
        case .denied: return "xmark"
        case .notDetermined: return "questionmark"
        case .restricted: return "lock.fill"
        }
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 9, weight: .heavy))
            Text(status.label).font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(color.opacity(0.12)))
        .accessibilityLabel(status.label)
    }
}
