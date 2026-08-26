# Ringo app

Ringo is a local-first health and wellness companion for wearables. It helps
people turn their wearable data into evidence-backed personal insights and
small experiments—not just another daily dashboard.

The application is designed around a stable shell:

- **Today** — wearable status and meaningful changes.
- **Timeline** — measurements, sleep, activity, and context over time.
- **Lab** — questions and personal N-of-1 experiments.
- **Playbook** — evidence-backed habits that work for the individual.

Health data stays on-device by default. Optional AI features follow a BYOK
model, receive only a user-visible evidence pack, and cannot access raw BLE
packets or freely query local health data. Ringo provides wellness information,
not medical advice, diagnosis, or treatment.

## Development

From the workspace root:

```bash
melos bootstrap
cd apps/ringo
fvm flutter run
```

Use the Flutter version pinned by FVM for Flutter commands.

## Current focus

The first product milestone validates the wearable connection: BLE discovery,
device metadata and battery reading, raw-packet capture, and reliable syncing
of the data exposed by the supported device. Protocol parsing remains isolated
from Flutter and is backed by fixtures and golden tests as support expands.
