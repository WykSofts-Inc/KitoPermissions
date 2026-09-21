//
//  KitoPermissionRationaleView.swift
//  KitoPermissions
//
//  Created by Wycliff on 8/28/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A themed "why we need this" sheet to show *before* the system prompt
/// (which you get exactly one chance to trigger per permission per install)
/// — explaining first measurably improves grant rates versus prompting cold.
public struct KitoPermissionRationaleView: View {
    @Environment(\.kitoTheme) private var theme
    let icon: String
    let title: String
    let message: String
    let onContinue: () -> Void
    let onSkip: (() -> Void)?

    public init(
        icon: String,
        title: String,
        message: String,
        onContinue: @escaping () -> Void,
        onSkip: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.onContinue = onContinue
        self.onSkip = onSkip
    }

    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(theme.colors.primary)
            Text(title)
                .font(theme.typography.titleLarge)
                .foregroundStyle(theme.colors.onBackground)
            Text(message)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.onBackground.opacity(0.7))
                .multilineTextAlignment(.center)

            Button(action: onContinue) {
                Text("Continue")
                    .font(theme.typography.button)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.spacing.sm)
            }
            .background(theme.colors.primary, in: Capsule())
            .foregroundStyle(theme.colors.onPrimary)

            if let onSkip {
                Button("Not now", action: onSkip)
                    .font(theme.typography.label)
                    .foregroundStyle(theme.colors.onBackground.opacity(0.6))
            }
        }
        .padding(theme.spacing.xl)
    }
}
