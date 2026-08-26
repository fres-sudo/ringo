# Ringo

Ringo is a local-first health and wellness companion for wearable devices. It
turns wearable data into clear, personal evidence: what changed, what may have
caused it, and which small experiment could help verify it.

> Discover what works for your body, then verify it through personal
> experiments.

Ringo is not intended to diagnose, treat, cure, or prevent any medical
condition. Wearable measurements and its insights are informational only and
should not replace professional medical advice.

## Product principles

- **Your data belongs to you.** No required account, no artificial
  subscription, and an export path for the data you collect.
- **Local first.** Wearable data, derived observations, and analytics remain
  on-device by default and work offline.
- **Evidence before explanation.** Deterministic analytics create the evidence;
  optional AI helps explain it, but never invents measurements or performs
  health calculations.
- **Low-friction learning.** Ringo should ask for only the small amount of
  context needed to learn from a personal experiment.
- **A stable, trustworthy interface.** Core navigation stays predictable while
  adaptive surfaces can present evidence in the most useful form.

## What Ringo will help with

Ringo is being built around four enduring areas:

- **Today** — wearable status and the meaningful changes in the current day.
- **Timeline** — measurements, sleep sessions, activity, and personal context
  over time.
- **Lab** — questions, lightweight logging, and N-of-1 experiments to test a
  hypothesis about your own wellbeing.
- **Playbook** — the habits and observations that have been verified for you,
  including their supporting evidence and confidence.

The initial wearable focus is a compatible smart ring, with capabilities such
as heart rate, HRV, SpO₂, temperature, stress, steps, and sleep where the
device makes those data available. Device support is validated per model and
firmware; no device is assumed compatible until its BLE protocol has been
tested.

## Data and privacy model

Ringo stores both the original wearable packets and normalized observations.
Keeping the raw data makes it possible to improve a decoder later without
losing the underlying record. Persistent health data is kept separate from
ephemeral connection and sync state.

AI features are optional and use a bring-your-own-key (BYOK) model. Before any
request, Ringo should show a privacy receipt explaining exactly which compact
evidence pack will be sent. API keys belong in platform secure storage, not in
the repository or the health-data store. Raw BLE packets and unrestricted
database access are never sent to an AI provider.

## Intended architecture

The workspace is organised to keep hardware, storage, and product logic
replaceable:

```text
wearable BLE
  -> transport and protocol decoding
  -> raw packets + normalized observations
  -> local storage
  -> analytics and personal experiments
  -> evidence-backed UI and optional BYOK AI
```

As the application grows, the main boundaries will be:

- `ring_protocol` — pure Dart commands, parsers, checksums, and fixtures.
- `ring_transport` and `ring_sync` — BLE connection, history sync, retry,
  deduplication, and clock handling.
- `health_domain` and `analytics` — observations, sleep, summaries, baselines,
  anomalies, and experiments.
- `storage_tostore` — the local persistence adapter, kept behind a domain
  interface so it can be replaced if necessary.
- `health_bridge` — optional HealthKit and Health Connect integration.
- `ai` — provider-neutral BYOK requests and controlled, evidence-backed
  generative UI.

## Delivery focus

The first milestone is proving that the wearable is genuinely usable: inspect
BLE services, read device information and battery level, collect raw packets,
sync available activity and sleep history, and compare the results with the
vendor application. The app then grows into a reliable foreground companion
before background sync, health-platform bridges, analytics, or AI surfaces are
added.

Every BLE command should have hexadecimal fixtures; parsers and checksums
should have golden tests; and protocol notes should evolve alongside the code.

## Workspace

Ringo is a Flutter workspace managed with Melos. The application lives in
[`apps/ringo`](apps/ringo), with shared domain-neutral utilities under
[`packages`](packages).

### Setup

```bash
melos bootstrap
```

### Run

```bash
cd apps/ringo
fvm flutter run
```

Use the Flutter version pinned by FVM for all Flutter commands.
