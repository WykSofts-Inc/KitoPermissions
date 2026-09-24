//
//  View+KitoPermissionPriming.swift
//  KitoPermissions
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

private struct KitoPermissionPrimingModifier: ViewModifier {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isPresented: Bool
    let kind: KitoPermissionKind
    let style: KitoPermissionPrimingStyle
    let content: KitoPermissionPrimingContent?
    let requester: KitoPermissionRequester
    let onResult: (KitoPermissionStatus) -> Void

    func body(content view: Content) -> some View {
        view.overlay {
            ZStack(alignment: style == .banner ? .top : .center) {
                if isPresented {
                    switch style {
                    case .card:
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture { isPresented = false }
                            .transition(.opacity)
                            .accessibilityHidden(true)
                        primer
                            .padding(.horizontal, theme.spacing.lg)
                            .transition(reduceMotion ? .opacity : .scale(scale: 0.9).combined(with: .opacity))
                    case .illustration:
                        primer.transition(reduceMotion ? .opacity : .move(edge: .bottom))
                    case .banner:
                        primer
                            .padding(.horizontal, theme.spacing.md)
                            .padding(.top, theme.spacing.sm)
                            .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.85), value: isPresented)
        }
    }

    private var primer: some View {
        KitoPermissionPrimer(kind: kind, style: style, content: content, requester: requester, onDismiss: { isPresented = false }, onResult: onResult)
            .accessibilityAddTraits(.isModal)
    }
}

public extension View {
    /// Shows a priming screen for `kind` over this view — a card on a dimmed backdrop, a
    /// full-screen illustration, or a banner at the top — and asks the system once the person
    /// taps Allow. Presented as an overlay, so it stays inside the view it's attached to.
    func kitoPermissionPriming(
        isPresented: Binding<Bool>,
        kind: KitoPermissionKind,
        style: KitoPermissionPrimingStyle = .card,
        content: KitoPermissionPrimingContent? = nil,
        requester: KitoPermissionRequester = .live,
        onResult: @escaping (KitoPermissionStatus) -> Void = { _ in }
    ) -> some View {
        modifier(KitoPermissionPrimingModifier(isPresented: isPresented, kind: kind, style: style, content: content, requester: requester, onResult: onResult))
    }
}
