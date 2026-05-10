//
//  MysticalFogView.swift
//  Oracle of Self
//
//  Ethereal vapor backdrop. Hundreds of oversized, soft circles drift upward
//  from a constantly replenished pool at the bottom. Fog is dense and opaque
//  at the base, fades rapidly through a narrow transition zone, and leaves
//  the text area clear. A few ghost bubbles pierce the fade zone as faint
//  traces above the title.
//
//  Performance: a single ~60fps `Timer` mutates the particle array; the
//  `Canvas` redraws whenever `@State` changes.
//

import SwiftUI

// MARK: - Particle Model

struct FogParticle: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var size: Double
    var baseOpacity: Double
    var drift: Double
    var speed: Double
    var phase: Double
    /// When true, this bubble renders faintly above the fade zone like a ghost.
    var isGhost: Bool
}

// MARK: - Mystical Fog View

struct MysticalFogView: View {
    @State private var particles: [FogParticle] = []
    @State private var timer: Timer? = nil

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let h = size.height
                guard h > 0 else { return }

                for p in particles {
                    let rect = CGRect(
                        x: p.x - p.size / 2,
                        y: p.y - p.size / 2,
                        width: p.size,
                        height: p.size
                    )
                    let path = Path(ellipseIn: rect)

                    let t = p.y / h
                    let fadeStart: Double = 0.62
                    let fadeEnd: Double = 0.35
                    let raw = (t - fadeEnd) / (fadeStart - fadeEnd)
                    let normalized = max(0, min(1, raw))
                    let zoneFade = pow(normalized, 3.0)

                    // Ghost bubbles pierce the fade zone at reduced opacity.
                    let alpha = p.isGhost
                        ? p.baseOpacity * 0.5 * 0.6
                        : p.baseOpacity * zoneFade * 0.6

                    let color = Color(
                        red: 0.75,
                        green: 0.82,
                        blue: 0.92,
                        opacity: alpha
                    )

                    context.fill(path, with: .color(color))
                }
            }
            .onAppear {
                let w = geometry.size.width
                let h = geometry.size.height
                particles = (0..<200).map { _ in spawn(width: w, height: h) }
                startAnimation(size: geometry.size)
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
    }

    // MARK: - Spawn

    private func spawn(width: Double, height: Double) -> FogParticle {
        let isGhost = Double.random(in: 0...1) < 0.08
        return FogParticle(
            x: Double.random(in: -50...width + 50),
            y: Double.random(in: height * 0.88...height + 250),
            size: Double.random(in: 100...280),
            baseOpacity: Double.random(in: 0.3...0.8),
            drift: Double.random(in: -3.0...3.0),
            speed: Double.random(in: 0.15...0.7),
            phase: Double.random(in: 0...Double.pi * 2),
            isGhost: isGhost
        )
    }

    // MARK: - Animation

    private func startAnimation(size: CGSize) {
        let h = size.height
        let w = size.width

        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            for index in particles.indices {
                var p = particles[index]

                p.y -= p.speed
                p.x += sin(p.y * 0.004 + p.phase) * p.drift * 0.9
                p.size -= 0.1

                let t = p.y / h
                let fadeStart: Double = 0.62
                let fadeEnd: Double = 0.35
                let raw = (t - fadeEnd) / (fadeStart - fadeEnd)
                let normalized = max(0, min(1, raw))
                let zoneFade = pow(normalized, 3.0)

                let fadedOut = !p.isGhost && p.baseOpacity * zoneFade <= 0.01
                let tiny = p.size <= 15
                let offScreen = p.y < -p.size

                if offScreen || fadedOut || tiny {
                    p = spawn(width: w, height: h)
                }

                particles[index] = p
            }
        }
    }
}
