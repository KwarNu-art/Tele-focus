# TeleFocus

**Telegram-only** jailbreak tweak for older iPhones that choke on Telegram.

Author credit: **Kwar Nu**

---

## GitHub idea

| Item | Suggestion |
|------|------------|
| Repo name | `TeleFocus` or `telefocus-tweak` |
| Description | Telegram-only performance focus for jailbroken iOS |
| Topics | `ios`, `jailbreak`, `theos`, `telegram`, `tweak` |
| Package id | `com.telefocus.tweak` |
| Injected dylib | `TeleFocus.dylib` (inside the `.deb`) |

### Why `.deb` and not only `.dylib`?

On jailbreak, Cydia/Sileo/Zebra install **packages** (`.deb`).  
Inside the package the actual tweak binary is still:

`/Library/MobileSubstrate/DynamicLibraries/TeleFocus.dylib`

plus `TeleFocus.plist` (filter).  
Theos `make package` builds **both**. You are not choosing deb *instead of* dylib — deb is the install wrapper around the dylib.

---

## What it does (honest)

| Feature | Reality |
|--------|---------|
| Lighter Telegram UI | Less animation, less blur, less shadow |
| FPS preference | Cap 30 or 60 inside Telegram |
| Freeze other apps | Best-effort **suspend** other **user** apps while Telegram is open (never kills SpringBoard / system) |
| Memory trim | Clears URL cache + soft memory warning inside Telegram |
| 24h zero lag / zero crash | **Not guaranteed** — RAM, iOS, network, and Telegram’s own code still matter |
| Auto-delete Telegram features | **Not done** — would need private Telegram reverse engineering and breaks often |

Target app: official Telegram  
Bundle id: `ph.telegra.Telegraph`

---

## Files

```
TeleFocus/
├── Makefile
├── control
├── TeleFocus.plist
├── Sources/
│   ├── Tweak.xm
│   ├── TFEngine.m / .h
│   └── TFPrefs.m / .h
├── layout/.../TeleFocus.plist   # Settings
└── .github/workflows/build.yml
```

---

## Build

```bash
export THEOS=~/theos
cd TeleFocus
make package
make install
```

Respring. Open **Settings → TeleFocus**. Open Telegram.

Requires jailbreak + MobileSubstrate / Substitute / ElleKit.
