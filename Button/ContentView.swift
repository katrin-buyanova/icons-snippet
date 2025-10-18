//
//  ContentView.swift
//  Button
//
//  Created by Katerina Buyanova on 15/10/2025.
//

import SwiftUI
import CoreGraphics
import Foundation

// MARK: - Constants
private let BUTTON_SIZE: CGFloat = 120
private let ICON_SIZE: CGFloat   = 36

// MARK: - Math helpers
@inline(__always) private func Cos(_ x: CGFloat) -> CGFloat { CGFloat(cos(Double(x))) }
@inline(__always) private func Sin(_ x: CGFloat) -> CGFloat { CGFloat(sin(Double(x))) }

// MARK: - Helpers
private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let g = UIImpactFeedbackGenerator(style: style)
    g.impactOccurred()
}
private extension CGFloat {
    func clamped01() -> CGFloat { Swift.max(0, Swift.min(1, self)) }
    static func lerp(from a: CGFloat, to b: CGFloat, t: CGFloat) -> CGFloat { a + (b - a) * t }
}
private extension Color {
    static let glassStroke = LinearGradient(
        colors: [Color.white.opacity(0.8), Color.white.opacity(0.1)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static var instaGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.99, green: 0.27, blue: 0.37),
                Color(red: 0.99, green: 0.62, blue: 0.20),
                Color(red: 0.81, green: 0.28, blue: 0.99)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.glassStroke, lineWidth: 1)
                        .blendMode(.overlay)
                )
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 12)
                .shadow(color: .black.opacity(0.08), radius: 6,  x: 0, y: 2)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5)
                .blur(radius: 1.2)
                .padding(1.2)
                .blendMode(.plusLighter)

            content
        }
        .frame(width: BUTTON_SIZE, height: BUTTON_SIZE)
    }
}

// MARK: - Root
struct ContentView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.white, .white, Color(white: 0.97)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                .overlay(
                    ZStack {
                        Circle().fill(.blue.opacity(0.12)).frame(width: 300).offset(x: -120, y: -280).blur(radius: 60)
                        Circle().fill(.mint.opacity(0.14)).frame(width: 220).offset(x: 160, y: -120).blur(radius: 50)
                        Circle().fill(.purple.opacity(0.12)).frame(width: 260).offset(x: 120, y: 260).blur(radius: 70)
                    }
                )

            VStack(spacing: 40) {
                Text("Micro-Interactions (SwiftUI)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.gray.opacity(0.8))
                    .padding(.bottom, 20)

                LikeHeartButton()
                InstaReactionsButton()
                BookmarkLiquidProButton()
            }
            .padding(50)
        }
    }
}

// (1) ❤️ LIKE

private struct HeartSpark: Identifiable {
    let id = UUID()
    let angle: CGFloat
    let radius: CGFloat
    let size: CGFloat
    let color: Color
}

struct LikeHeartButton: View {
    @State private var isLiked = false
    @State private var pressed = false
    @State private var sparks: [HeartSpark] = []
    @State private var progress: CGFloat = 0 // 0..1

    var body: some View {
        GlassCard {
            ZStack {
                Button {
                    haptic(.light)
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        pressed = true
                        isLiked.toggle()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) { pressed = false }
                    }
                    makeSparks()
                    progress = 0
                    withAnimation(.easeOut(duration: 1.05)) { progress = 1 }
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: ICON_SIZE, weight: .regular))
                        .frame(width: ICON_SIZE, height: ICON_SIZE)
                        .foregroundStyle(isLiked ? .red : .gray)
                        .scaleEffect(pressed ? 0.92 : 1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)

                ZStack {
                    ForEach(sparks) { s in
                        let r = s.radius * easeOutCubic(progress)
                        let dx = Cos(s.angle) * r
                        let dy = Sin(s.angle) * r
                        Circle()
                            .fill(RadialGradient(colors: [s.color, s.color.opacity(0.15)],
                                                 center: .center, startRadius: 0,
                                                 endRadius: max(8, s.size*1.6)))
                            .frame(width: s.size, height: s.size)
                            .offset(x: dx, y: dy)
                            .opacity(1 - progress)
                            .blendMode(.plusLighter)
                    }
                }
                .allowsHitTesting(false)
            }
        }
    }

    private func makeSparks() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .mint, .blue, .purple, .pink]
        sparks = (0..<30).map { _ in
            HeartSpark(
                angle: .random(in: 0..<(2 * .pi)),
                radius: .random(in: 60...90),
                size: .random(in: 6.5...11.5),
                color: colors.randomElement()!
            )
        }
    }
    private func easeOutCubic(_ t: CGFloat) -> CGFloat {
        let inv = 1 - t; return 1 - inv*inv*inv
    }
}


// (2) ⭐️ REACTIONS

private struct EmojiParticle: Identifiable {
    let id = UUID()
    let emoji: String
    let xStart: CGFloat
    let sway: CGFloat
    let height: CGFloat
    let delay: Double
    var live: Bool = false
}

struct InstaReactionsButton: View {
    @State private var pressed = false
    @State private var showTray = false
    @State private var particles: [EmojiParticle] = []
    @State private var trayScale: CGFloat = 0.7
    @State private var accentFlash = false

    private let emojis = ["❤️","🔥","👏","✨","😍"]

    var body: some View {
        GlassCard {
            ZStack {
                if showTray {
                    ReactionsTray(emojis: emojis, onPick: pick)
                        .offset(y: -62)
                        .scaleEffect(trayScale)
                        .allowsHitTesting(false)
                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity),
                                                removal: .scale.combined(with: .opacity)))
                        .onAppear {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) { trayScale = 1 }
                        }
                }
                
                ZStack {
                    ForEach(particles) { p in
                        EmojiFlight(p: p)
                    }
                }
                .allowsHitTesting(false)
                
                let active = showTray || accentFlash

                Button {
                    haptic(.soft)
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.85)) { pressed = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.9)) { pressed = false }
                    }
                    if showTray {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showTray = false
                            trayScale = 0.7
                        }
                    } else {
                        trayScale = 0.7
                        withAnimation(.easeInOut(duration: 0.2)) { showTray = true }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .fill(Color.instaGradient)
                                    .opacity(active ? 1 : 0)
                                    .animation(.easeInOut(duration: 0.2), value: active)
                            )
                            .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 1))
                            .shadow(color: .black.opacity(0.08), radius: 10, y: 2)
                            .shadow(color: active ? .pink.opacity(0.25) : .clear, radius: 14, y: 4)

                        Image(systemName: "paperplane.fill")
                            .font(.system(size: ICON_SIZE, weight: .regular))
                            .frame(width: ICON_SIZE, height: ICON_SIZE)
                            .foregroundStyle(active ? .white : .gray)
                            .shadow(radius: active ? 4 : 0)
                            .animation(.easeInOut(duration: 0.2), value: active)
                    }
                    .frame(width: 64, height: 64)
                    .scaleEffect(pressed ? 0.94 : 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func pick(_ emoji: String) {
        haptic(.light)
        accentFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { accentFlash = false }

        let batch = (0..<12).map { i -> EmojiParticle in
            EmojiParticle(
                emoji: emoji,
                xStart: .random(in: -0.35...0.35),
                sway: .random(in: 8...16),
                height: .random(in: 90...130),
                delay: Double(i) * 0.04,
                live: false
            )
        }
        particles = batch

        for idx in particles.indices {
            let d = particles[idx].delay
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                withAnimation(.easeOut(duration: 1.6)) { particles[idx].live = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + d + 1.7) {
                    if idx < particles.count { particles.remove(at: idx) }
                }
            }
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            showTray = false
            trayScale = 0.7
        }
    }
}

private struct ReactionsTray: View {
    let emojis: [String]
    var onPick: (String) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(emojis.enumerated()), id: \.offset) { i, e in
                Button {
                    onPick(e)
                } label: {
                    Text(e)
                        .font(.system(size: 20))
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 0.8))
                        .shadow(radius: 4, y: 2)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(i) * 0.04), value: UUID())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .overlay(Capsule().stroke(.white.opacity(0.7), lineWidth: 0.8))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
}

private struct EmojiFlight: View {
    @State var p: EmojiParticle
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let startX = (w/2) + p.xStart * (w * 0.5)

            Text(p.emoji)
                .font(.system(size: 18))
                .shadow(radius: 2)
                .offset(x: p.live ? startX + p.sway : startX,
                        y: p.live ? -(p.height) : 0)
                .opacity(p.live ? 0 : 1)
                .animation(.easeInOut(duration: 1.6), value: p.live)
        }
    }
}

// (3) 🔖 BOOKMARK

struct BookmarkLiquidProButton: View {
    @State private var saved = false
    @State private var pressed = false

    @State private var targetLevel: CGFloat = 0
    @State private var level: CGFloat = 0

    @State private var phase1: CGFloat = 0
    @State private var phase2: CGFloat = .pi
    @State private var bubblePhase: CGFloat = 0
    @State private var shimmerPhase: CGFloat = 0
    @State private var ripple: CGFloat = 1 // 0..1

    var body: some View {
        GlassCard {
            ZStack {
                Button {
                    haptic(.medium)
                    saved.toggle()
                    targetLevel = saved ? 1 : 0

                    withAnimation(.interpolatingSpring(stiffness: 140, damping: 12)) {
                        level = targetLevel
                    }

                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) { pressed = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) { pressed = false }
                    }

                    ripple = 0
                    withAnimation(.easeOut(duration: 0.6)) { ripple = 1 }
                } label: {
                    ZStack {
                        Image(systemName: "bookmark")
                            .font(.system(size: ICON_SIZE, weight: .regular))
                            .frame(width: ICON_SIZE, height: ICON_SIZE)
                            .foregroundStyle(.gray)

                        LiquidProFillView(level: level,
                                          phase1: phase1,
                                          phase2: phase2,
                                          bubblePhase: bubblePhase,
                                          shimmerPhase: shimmerPhase,
                                          ripple: ripple)
                            .frame(width: ICON_SIZE + 6, height: ICON_SIZE + 10)
                            .mask(
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: ICON_SIZE, weight: .regular))
                                    .frame(width: ICON_SIZE, height: ICON_SIZE)
                            )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(pressed ? 0.94 : 1)
                    .rotation3DEffect(.degrees(pressed ? 4 : 0), axis: (x: 1, y: 0, z: 0))
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) { phase1 = 2 * .pi }
            withAnimation(.linear(duration: 2.3).repeatForever(autoreverses: false)) { phase2 = phase2 + 2 * .pi }
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) { bubblePhase = 2 * .pi }
            withAnimation(.linear(duration: 2.8).repeatForever(autoreverses: false)) { shimmerPhase = 2 * .pi }
        }
    }
}

private struct LiquidProFillView: View {
    var level: CGFloat
    var phase1: CGFloat
    var phase2: CGFloat
    var bubblePhase: CGFloat
    var shimmerPhase: CGFloat
    var ripple: CGFloat

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let fillH = h * max(0, min(1, level))

            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom))
                    .frame(height: fillH)

                WaveShape(phase: phase2, amplitude: 5, wavelength: 14)
                    .fill(Color.black.opacity(0.13))
                    .frame(height: min(14, fillH))
                    .offset(y: -fillH + 3)

                WaveShape(phase: phase1, amplitude: 7, wavelength: 18)
                    .fill(Color.white.opacity(0.35))
                    .frame(height: min(18, fillH))
                    .offset(y: -fillH)

                FoamStrip(width: w, top: h - fillH, phase: phase1)

                ForEach(0..<10, id: \.self) { i in
                    let colX = w * (0.08 + 0.1 * CGFloat(i))
                    let phase = bubblePhase + CGFloat(i) * 0.5
                    let up: CGFloat = (Sin(phase) + 1) / 2
                    let y = (h - fillH) + (fillH * (1 - up))
                    Circle()
                        .fill(.white.opacity(0.25))
                        .frame(width: 3.5 + CGFloat(i % 3), height: 3.5 + CGFloat(i % 3))
                        .offset(x: colX - w/2 + Sin(phase * 1.6) * 2.2, y: -y)
                }

                ShimmerSweep(phase: shimmerPhase)
                    .frame(width: w, height: h)
                    .blendMode(.plusLighter)
                    .mask(Rectangle().frame(height: fillH))

                RippleLayer(progress: ripple)
                    .stroke(.white.opacity(0.35), lineWidth: 1.2)
                    .frame(width: w * 0.9, height: w * 0.9)
                    .opacity(1 - ripple)
                    .scaleEffect(0.7 + 0.5 * ripple)
                    .blendMode(.plusLighter)
                    .offset(y: -fillH + min(fillH, 10))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

private struct FoamStrip: View {
    let width: CGFloat
    let top: CGFloat
    let phase: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                let x = CGFloat(i) / 11 * width
                let k = (2 * CGFloat.pi) / 18.0
                let y = top + 7 * Sin(k * x + phase)
                Circle()
                    .fill(.white.opacity(0.6))
                    .frame(width: 2.2 + CGFloat(i % 3), height: 2.2 + CGFloat(i % 3))
                    .offset(x: x - width/2, y: -y)
            }
        }
    }
}

private struct ShimmerSweep: View {
    var phase: CGFloat
    var body: some View {
        let t = (Sin(phase) + 1) / 2
        let x = CGFloat.lerp(from: -1.0, to: 1.0, t: t)
        return Rectangle()
            .fill(
                LinearGradient(colors: [Color.white.opacity(0.0),
                                        Color.white.opacity(0.35),
                                        Color.white.opacity(0.0)],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
            )
            .rotationEffect(.degrees(18))
            .offset(x: x * 16, y: x * -6)
    }
}

private struct RippleLayer: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r1 = min(rect.width, rect.height) * 0.28 * progress
        let r2 = min(rect.width, rect.height) * 0.42 * progress
        p.addEllipse(in: CGRect(x: rect.midX - r1, y: rect.midY - r1, width: r1*2, height: r1*2))
        p.addEllipse(in: CGRect(x: rect.midX - r2, y: rect.midY - r2, width: r2*2, height: r2*2))
        return p
    }
}

private struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var wavelength: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.maxY))
        p.addLine(to: CGPoint(x: 0, y: rect.midY))
        let k = (2 * CGFloat.pi) / max(1.0, wavelength)
        let step: CGFloat = 1
        var x: CGFloat = 0
        while x <= rect.width {
            let y = rect.midY + amplitude * Sin(k * x + phase)
            p.addLine(to: CGPoint(x: x, y: y))
            x += step
        }
        p.addLine(to: CGPoint(x: rect.width, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Preview
#Preview { ContentView() }
