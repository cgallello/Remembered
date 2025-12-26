# Activation Rate Improvement Plan
## Remembered iOS App

### Current State Summary
- **No onboarding flow** - users land directly on empty list
- **Minimal empty state** - no guidance when list is empty
- **Modal-based capture** - requires tap on "+" button to add dates
- **No haptic feedback** - no tactile confirmation of actions
- **Widget exists** - but no guidance on setup
- **Strong date parsing** - this is the hidden superpower users don't discover
- **No analytics** - no visibility into activation funnel or user behavior

---

## Priority Framework

| Priority | Criteria |
|----------|----------|
| **P0** | Critical for first session activation - user must experience core value |
| **P1** | High impact on habit formation and retention |
| **P2** | Polish and delight - reinforces engagement |

---

## P0: First-Session Activation

### 1. Onboarding Flow (3 screens)
**Problem:** Users don't understand the natural language input magic or the value prop.

**Solution:** Lightweight onboarding that educates and gets first date captured. **No skip option** - users must complete onboarding and add first date.

| Screen | Content |
|--------|---------|
| **Welcome** | "Never forget an important date" - birthday cake illustration, quick value props (Natural language input, Smart reminders, Widget at a glance) |
| **How It Works** | Animated demo of typing "Mom's birthday March 15" → shows parsing result. Emphasize the magic of natural language. |
| **Your First Date** | Embedded capture field - "Try it now: Add someone's birthday" - they can't proceed without adding one date |

**Technical Notes:**
- Use `@AppStorage("hasCompletedOnboarding")` to track completion
- Show onboarding on first launch only
- Block progression until first date is saved

**Key Metrics:** % completing onboarding, % adding first date (should be 100%)

---

### 2. Empty State with CTA
**Problem:** Empty list is dead end - no guidance, no motivation.

**Solution:** Illustrated empty state with clear action.

```
[Birthday cake illustration]

"Your important dates live here"

Add birthdays, anniversaries, and dates
you never want to forget.

[Add your first date] ← Primary CTA button
         or
"Mom's birthday March 15" ← Tappable example that pre-fills capture
```

**Considerations:**
- Show 2-3 tappable example phrases users can tap to pre-fill
- Animate the illustration subtly
- This replaces blank List when items.isEmpty
- This is a fallback if user somehow gets to empty state post-onboarding

---

### 3. Persistent Capture Field (Always-On Input)
**Problem:** "+" button → modal is friction. Messaging apps prove inline input works.

**Solution:** Replace bottom toolbar with persistent text field. **This is the committed approach.**

```
┌─────────────────────────────────────┐
│ [list of dates...]                  │
│                                     │
├─────────────────────────────────────┤
│ 🎂 "Add a date..."          [Send] │
└─────────────────────────────────────┘
```

**Behavior:**
- Always visible at bottom (like iMessage composer)
- Tap to focus, keyboard appears
- Send button appears when text entered
- After submit: field clears, haptic fires, new item appears in list with subtle highlight animation
- Parsing preview appears inline above field as user types

**Technical Notes:**
- Replace current `.toolbar` with `VStack` containing List + input
- Keep sheet for complex editing (DetailView) accessible via list item tap
- Consider `.safeAreaInset(edge: .bottom)` for proper keyboard handling
- Remove existing CaptureView modal and "+" button

---

## P1: Habit Formation

### 4. Haptic Feedback System
**Problem:** No tactile confirmation = no dopamine hit = weak habit loop.

**Solution:** Strategic haptics throughout the app.

| Action | Haptic Type | Rationale |
|--------|-------------|-----------|
| Date saved successfully | `.success` (3 taps) | Reward completion |
| Date deleted | `.warning` (2 heavy taps) | Confirm destructive action |
| Type selected in capture | `.selection` (light tap) | Acknowledge input |
| Widget "+" tapped | `.light` | Confirm touch |
| Pro purchase completed | `.success` | Celebrate! |
| Date parsing recognized | `.light` | Subtle "I understood" signal |

**Implementation:**
```swift
import UIKit

enum HapticManager {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
```

---

### 5. Visual Save Confirmation
**Problem:** After capture, item just appears in list - easy to miss.

**Solution:** Multi-signal confirmation.

1. **Toast/snackbar:** "Added: Mom's Birthday - March 15" (auto-dismisses 2s)
2. **List highlight:** New item has subtle green pulse/glow for 1s
3. **Haptic:** `.success` fires simultaneously
4. **Sound (optional):** Subtle "ding" for users with sound enabled

---

### 6. Widget Setup Prompt
**Problem:** Widget is core value but users don't know it exists.

**Solution:** Contextual prompt after activation milestone with video walkthrough.

**Trigger:** User has added 3+ dates AND hasn't seen prompt before

**UI:** Bottom sheet or full-screen modal:
```
┌─────────────────────────────────────┐
│ 📱 See dates on your Lock Screen   │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │                                 │ │
│ │    [3:4 Screen Recording        │ │
│ │     Video showing widget        │ │
│ │     installation process]       │ │
│ │                                 │ │
│ │                                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Add the Remembered widget to see    │
│ your dates at a glance.             │
│                                     │
│    [Go to Home Screen] ← Primary    │
│       [Maybe Later]                 │
└─────────────────────────────────────┘
```

**Video Content (3:4 aspect ratio):**
- Screen recording showing: Long press home screen → Tap "+" → Search "Remembered" → Select widget size → Place widget
- Duration: 10-15 seconds, looping
- Silent or subtle background music

**"Go to Home Screen" CTA Behavior:**
- Dismisses the app to home screen (user can immediately follow along)
- Video shows exactly what to do once they're there
- Minimizes app to background using `UIApplication.shared.perform(#selector(NSXPowerAssertion.suspend))`

**Alternative approach (iOS 18+):**
```swift
// Send to home screen
if #available(iOS 18.0, *) {
    await UIApplication.shared.requestSceneSessionDestruction(
        UIApplication.shared.connectedScenes.first as! UIWindowScene,
        options: nil
    )
} else {
    // Fallback: Just dismiss the sheet - user navigates manually
}
```

**Technical Implementation:**
```swift
// WidgetPromptView.swift
Button("Go to Home Screen") {
    // Mark as seen
    UserDefaults.standard.set(true, forKey: "hasSeenWidgetPrompt")

    // Minimize app to home screen
    // Note: This uses private API - may need App Store review consideration
    // Alternative: Just dismiss and rely on user navigating themselves
    DispatchQueue.main.async {
        UIApplication.shared.perform(#selector(NSXPowerAssertion.suspend))
    }
}
```

**Persist:** `@AppStorage("hasSeenWidgetPrompt")`

**Asset Requirements:**
- Record 3:4 screen recording of widget installation
- Export as MP4 or use AVPlayer for playback
- Consider hosting video in Assets.xcassets or bundle

---

## P2: Polish & Delight

### 7. Capture Field Intelligence
**Problem:** Users don't know what formats work.

**Solution:** Smart placeholder rotation + inline hints.

- **Rotating placeholders:** Cycle through examples every 3s
  - "Mom's birthday March 15"
  - "Anniversary on October 3rd"
  - "Dentist appointment next Tuesday"
  - "Dad's memorial May 20"

- **Real-time parsing preview:** As user types, show:
  ```
  "Sam's birthday Jan 12"
  ↓
  📅 January 12, 2026 · 🎂 Birthday
  ```

---

## Analytics Implementation

### Core Events to Track

**Onboarding Funnel:**
- `onboarding_started`
- `onboarding_screen_viewed` (screen: "welcome" | "how_it_works" | "first_date")
- `onboarding_completed`
- `first_date_added` (source: "onboarding" | "main_app")

**Activation:**
- `app_opened` (is_first_launch: bool)
- `date_added` (source: "persistent_input" | "detail_view" | "widget", type: string)
- `date_edited`
- `date_deleted`
- `empty_state_viewed`
- `empty_state_cta_tapped`

**Feature Discovery:**
- `widget_prompt_shown`
- `widget_prompt_action` (action: "go_to_home_screen" | "maybe_later")
- `settings_opened`
- `paywall_shown` (source: string)

**Engagement:**
- `notification_scheduled`
- `notification_received`
- `session_duration` (duration_seconds: int)
- `dates_count` (count: int) - tracked weekly

**Conversion:**
- `pro_purchase_started`
- `pro_purchase_completed`
- `pro_purchase_failed` (reason: string)

### Recommended Analytics Platform

**TelemetryDeck** (privacy-focused, no PII)
- Already using it? If not, integrate TelemetryDeck SDK
- Compliant with App Store privacy requirements
- Free tier supports reasonable volume

**Alternative:** PostHog (open source, self-hostable)

### Implementation Notes

```swift
// AnalyticsManager.swift
enum AnalyticsManager {
    static func track(_ event: String, properties: [String: Any] = [:]) {
        #if !DEBUG
        // TelemetryDeck.signal(event, parameters: properties)
        #endif
        print("📊 Analytics: \(event) - \(properties)")
    }
}

// Usage:
AnalyticsManager.track("date_added", properties: [
    "source": "persistent_input",
    "type": item.type
])
```

**Privacy:**
- No PII collection (no names, dates content, etc.)
- Only behavioral events and counts
- Disclose in App Store privacy section

---

## Implementation Sequence

### Phase 1: Core Activation + Analytics Foundation
1. **Set up analytics** (TelemetryDeck or PostHog)
2. **Empty state with CTA** + track events
3. **Persistent capture field** + track events
4. **Basic haptic feedback** (save success)

### Phase 2: Onboarding & Guidance
5. **3-screen onboarding flow** (no skip) + track funnel
6. **Widget setup prompt** + track interactions
7. **Enhanced visual save confirmation**

### Phase 3: Polish & Delight
8. **Parsing preview enhancements** (real-time parsing display, rotating placeholders)

---

## Success Metrics

| Metric | Current (est.) | Target | How to Measure |
|--------|----------------|--------|----------------|
| % users completing onboarding | N/A | 100% | `onboarding_completed` / `onboarding_started` |
| % users adding 1+ date in first session | ~40% | 80% | `first_date_added` (day 0) / `app_opened` (first_launch) |
| % users adding 3+ dates in first week | ~20% | 50% | Count users with 3+ `date_added` events in first 7 days |
| % users with widget installed | Unknown | 40% | Survey or proxy metric: `widget_prompt_action: "go_to_home_screen"` |
| Day 7 retention | Unknown | 35% | % of users opening app on day 7 |
| Conversion to Pro | Unknown | 15% | `pro_purchase_completed` / total users (30-day cohort) |

---

## Design Questions to Answer Before Implementation

### Onboarding
1. **Illustration style:** Minimalist SF Symbols, custom illustrations, or stock assets?
2. **Animation approach:** Lottie files, SwiftUI animations, or static with transitions?
3. **Copy tone:** Playful vs professional vs warm?

### Persistent Input
1. **Visual hierarchy:** How prominent should it be vs the list?
2. **Keyboard avoidance:** Push list up or overlay input over list?
3. **Error states:** How to handle parse failures inline?

### Empty State
1. **Illustration:** Custom asset or SF Symbol composition?
2. **Example phrases:** How many? Randomized or fixed order?

### Widget Prompt
1. **Video recording:** Record on device with actual app data or use demo/placeholder dates?
2. **Timing:** Immediately after 3rd date or wait until next session?
3. **Home screen transition:** Use private API to minimize app, or just dismiss prompt and instruct user to go home manually?

---

## Next Steps

1. [ ] Review and approve this plan
2. [ ] Answer design questions (create mockups if needed)
3. [ ] Record 3:4 widget installation screen recording video (10-15s)
4. [ ] Set up analytics infrastructure (TelemetryDeck/PostHog)
5. [ ] Implement Phase 1 (analytics + empty state + persistent input + haptics)
6. [ ] Monitor activation metrics for 1 week
7. [ ] Iterate based on data before moving to Phase 2
