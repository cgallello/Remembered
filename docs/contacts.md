# Remembered — Contact Tagging Spec (No `@`)

## Goal

While the user is typing a new entry in the capture box, suggest matching Contacts so the user can tag a person with **near-zero taps**, without breaking the core promise: **capture in under 5 seconds**.

Contact tagging is assistive. The app must remain fully usable without it.

---

## Non-goals

* Browsing or searching Contacts in a separate screen
* Requiring `@` or any special syntax
* Bulk import or sync of Contacts
* Creating a social graph
* Forcing a contact selection in order to save

---

## UX Overview

### Trigger

Show a lightweight suggestion strip under the capture input when:

* The current **active token** has **3+ characters**
* The token plausibly matches one or more Contacts
* Contacts permission has already been granted

No explicit user action is required to invoke suggestions.

---

### Active token definition

The active token is the substring after the most recent delimiter.

Delimiters:

* Space
* Comma
* Period
* Newline

Examples:

* “Stef birthday” → active token = “birthday”
* “Ste” → active token = “Ste”
* “Dinner with Stef” → active token = “Stef”

---

### Suggestion UI

* Appears inline, directly beneath the text field
* Shows a maximum of **3 suggestions**
* Each suggestion shows:

  * Contact display name
  * Minimal disambiguation if needed (e.g., “Chris G.”)
* No avatars
* No emoji
* Muted, OS-adjacent styling

Suggestions should feel like system assistance, not a feature.

---

### Interaction

Tapping a suggestion:

1. Tags the contact to the entry (metadata only)
2. Replaces the active token in the text field with the contact’s preferred display name
3. Keeps the keyboard open
4. Returns the cursor to the end of the field

One tap. No additional screens.

---

## Permissions & Onboarding

### Guiding principle

Contacts access is **optional**, **intent-based**, and **never required**.

---

### During onboarding

* Do **not** trigger the system Contacts permission prompt.
* Introduce the capability as optional.

Onboarding copy:

Title
Tag people as you type

Body
Remembered can suggest people from your contacts while you’re typing, so you can save dates faster.
This is optional, and nothing leaves your phone.

Actions:

* Continue
* Not now

This screen is informational only.

---

### Post-onboarding (intent-based prompt)

If Contacts permission is not granted:

* Do not show suggestions
* Do not prompt automatically

Intent signal:

* User types a capitalized token with 3+ characters that plausibly represents a name

When intent is detected, show a lightweight inline affordance below the input:

Enable contact suggestions

This is not a modal and not a system prompt.

---

### System permission prompt

Triggered only when the user taps the inline affordance.

Title
Suggest contacts while you type

Body
So you can save dates faster. Contacts are used only on this device.

If accepted:

* Suggestions appear immediately

If denied:

* Suggestions remain disabled
* No re-prompting
* User can enable later via Settings

---

## Matching Rules (Deterministic)

### Candidate fields

* Given name + family name
* Nickname (if present)
* Organization name (low priority)

---

### Matching order

1. Prefix match on given name or full display name
2. Prefix match on family name
3. Contains match (only if token length ≥ 5)

---

### Ranking signals

* Exact prefix match on given name
* Exact prefix match on full display name
* Recently tagged contacts within the app
* Favorites (if supported)
* Shorter edit distance (optional, lightweight only)

---

### Limits

* Maximum of **3 suggestions**
* No “More…” or expansion behavior

---

## Tagging Semantics

### Stored metadata

Each entry may store:

* contact_id (stable identifier)
* contact_display_name (snapshot at time of tagging)

The visible text remains fully editable and is always the source of truth.

---

### Edits after tagging

* Editing the visible name does **not** remove the contact link
* The contact link is removed only by explicit user action
* If the visible name diverges significantly, the link may be marked internally as stale (optional, non-user-facing)

---

### Contact deletion

If the linked contact is deleted from the system:

* Keep the display name snapshot
* Drop the internal contact reference silently

---

## Removing or Changing a Tagged Contact

### Where this happens

In the **detail view** for an entry (not during capture).

---

### Visual treatment

* Contact name appears as plain text
* A subtle row appears beneath the name:

Linked to contact

Example layout:

Stef
Birthday · Nov 3

Linked to contact

---

### Actions

Tapping “Linked to contact” opens a small action sheet:

* Remove contact link
* Cancel

No destructive language.
No confirmation beyond this step.

---

### Behavior on removal

* Removes contact_id
* Leaves visible name text unchanged
* Entry becomes a normal text-only entry

Rule reinforced:
**Text is primary. Contact linkage is assistive metadata.**

---

## Settings

* Toggle: Contact suggestions while typing
* Optional: Prefer nicknames
* Privacy note: Contacts are used only on-device for suggestions

---

## Privacy Guarantees

User-facing:

* Contacts are never uploaded
* Contacts are never shared
* The app works fully without Contacts access

Internal:

* All matching is on-device
* No contact data is logged, hashed, or analyzed
* No analytics include contact-derived information

Any feature requiring contact syncing or storage is out of scope.

---

## Design Constraints

* No emoji
* No playful or cheerful tone
* No celebration or delight animations
* No chips, pills, or tag UI
* Suggestions should feel OS-level, quiet, and optional