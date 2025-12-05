import SwiftUI

struct EducationScreen: View {
    let level: ExperienceLevel   

    private var levelLabel: String {
        switch level {
        case .beginner:     return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced:     return "Advanced"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text("Training Tips – \(levelLabel)")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                Text("These guidelines are tailored to your current level. As you level up, more advanced content will unlock.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                EducationCard(
                    title: "Warm-Up",
                    systemImage: "flame",
                    subtitle: "What to do before every run.",
                    bullets: warmupTips(for: level)
                )

                EducationCard(
                    title: "Strength & Mobility",
                    systemImage: "dumbbell",
                    subtitle: "Simple routines to stay strong and injury-resistant.",
                    bullets: strengthTips(for: level)
                )

                EducationCard(
                    title: "Injury Prevention & Pain",
                    systemImage: "cross.case",
                    subtitle: "How to react when something hurts.",
                    bullets: injuryTips(for: level)
                )

                EducationCard(
                    title: "Cool-Down & Recovery",
                    systemImage: "wind",
                    subtitle: "What to do after you stop your watch.",
                    bullets: recoveryTips(for: level)
                )

                Spacer(minLength: 24)
            }
            .padding()
        }
        .navigationTitle("Training Tips")
    }
}

// MARK: - Content helpers

private func warmupTips(for level: ExperienceLevel) -> [String] {
    switch level {
    case .beginner:
        return [
            "5–10 minutes of easy walking.",
            "Dynamic leg swings (front-to-back and side-to-side, 10 each leg).",
            "10 bodyweight squats with slow, controlled movement.",
            "2 x 10 calf raises and toe raises"
        ]
    case .intermediate:
        return [
            "5 minutes easy jog, gradually working up to your normal easy pace.",
            "Dynamic drills: high knees, butt kicks, and A-skips (20–30 meters each).",
            "2 × 30-second strides at controlled fast pace with 60 seconds easy jog.",
            "Focus on tall posture, relaxed shoulders, and smooth breathing."
        ]
    case .advanced:
        return [
            "10 minutes easy running with a few short pick-ups.",
            "Drills set: high knees, butt kicks, A-skips, B-skips, bounding (20–40 m each).",
            "4 × 20–30 second strides at 5K–10K effort with full recovery jog.",
            "Include workout-specific warm-up (e.g. 4–6 minutes at tempo before tempo work)."
        ]
    }
}

private func strengthTips(for level: ExperienceLevel) -> [String] {
    switch level {
    case .beginner:
        return [
            "2× per week, 10–15 minutes after an easy day.",
            "Key moves: glute bridges, calf raises, wall sits, side-lying leg lifts.",
            "Keep resistance light; stop if form breaks down.",
            "If you’re sore for more than 48 hours, reduce frequency until soreness is gone."
        ]
    case .intermediate:
        return [
            "2–3× per week, 15–20 minutes.",
            "Key moves: split squats, step-ups, single-leg deadlifts, planks.",
            "Add light dumbbells or bands once bodyweight feels easy.",
            "Avoid heavy leg strength the day before your hardest run."
        ]
    case .advanced:
        return [
            "2–3× per week in base, 1–2× in race phases.",
            "Key moves: heavy split squats, RDLs, calf raises, anti-rotation core.",
            "Emphasize single-leg strength.",
            "Deload strength every 4–6 weeks (reduce volume or weight)."
        ]
    }
}

private func injuryTips(for level: ExperienceLevel) -> [String] {
    switch level {
    case .beginner:
        return [
            "Mild muscle soreness after a new workout is normal and fades in 24–48 hours.",
            "Sharp, stabbing, or one-sided joint pain is a red flag stop the running until it heals.",
            "If pain forces you to limp or change your form, end the session.",
        ]
    case .intermediate:
        return [
            "Differentiate ‘tired muscles everywhere’ from sharp pain in one spot.",
            "Skip speed work when new pain shows up—keep it easy instead.",
            "Persistent pain lasting more than a week despite resting needs attention.",
            "Plan cut-back weeks (20–30% less volume) to stay ahead of overuse injuries."
        ]
    case .advanced:
        return [
            "High mileage + high intensity = higher injury risk. Don’t ignore new pain.",
            "If a workout pain worsens with each rep, shut it down and walk home.",
            "Avoid increasing volume and intensity at the same time.",
            "Long-lasting or escalating pain → talk to a medical professional."
        ]
    }
}

private func recoveryTips(for level: ExperienceLevel) -> [String] {
    switch level {
    case .beginner:
        return [
            "3–5 minutes of easy walking after every run",
            "Gentle calf and hamstring stretches (20–30 seconds each).",
            "Drink water and have a light carb + protein snack within an hour.",
        ]
    case .intermediate:
        return [
            "5–10 minutes very easy jog or walk to cool down.",
            "Short stretching routine: calves, quads, hamstrings, glutes, hip flexors.",
            "Keep 1–2 true rest or very easy days per week."
        ]
    case .advanced:
        return [
            "10 minutes very easy running or walking after hard sessions.",
            "Include 3–4 mobility sessions/week (ankle, hips, t-spine).",
            "Active recovery (easy cycling or walking)",
        ]
    }
}

// MARK: - Reusable card view

struct EducationCard: View {
    let title: String
    let systemImage: String
    let subtitle: String
    let bullets: [String]

    @State private var isExpanded: Bool = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(bullets, id: \.self) { tip in
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .padding(.top, 2)
                        Text(tip)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}
