# Auto OBS Sources Switcher

> Got sick and tired of the NVIDIA App, its telemetry, and random bloatware, so I decided to ditch ShadowPlay and move over to the OBS Replay Buffer. But here was the catch: unlike ShadowPlay, OBS doesn't auto-switch sources out of the box. If you keep both Display Capture and Game Capture on, your FPS takes a massive hit (around -10% in CS2/Rust on high-Hz monitors) because Windows DWM keeps polling the desktop. If you turn Display Capture off manually, every time you Alt+Tab your stream/clip is just a black screen or a frozen frame. 
> 
> So I made this: when you tab into a game, Display Capture instantly hides so you get 100% native 1:1 FPS. When you Alt+Tab back to desktop or Discord, Display Capture turns right back on. Simple as that.

---

## What does this actually do?

- **In Game:** Instantly hides `Display Capture`. No DWM polling overhead = **no -10% FPS penalty and zero micro-stutters**.
- **Alt-Tabbed / On Desktop:** Turns `Display Capture` back on and hides `Game Capture`. Your desktop, Chrome, and Discord get captured cleanly without any frozen game frames.
- **Zero hassle:** Fully automatic for any fullscreen game (CS2, Rust, Apex, whatever you play).

---

## Why does this even exist?

If you run a 144Hz, 240Hz, or 280Hz+ monitor and leave `Display Capture` running under `Game Capture`:
1. The Windows Desktop Duplication API keeps grabbing desktop frames at your monitor's full refresh rate in the background.
2. In games like **CS2** or **Rust**, this eats ~10% of your FPS and ruins frame pacing.
3. Turning it off manually is annoying as hell when you tab out. This script handles all of that automatically in the background.

---


**Can you get a ban??? NO. (If yea than gg. Shit idea/kekw)**

- `fg_helper.dll` runs **strictly inside OBS (`obs64.exe`)**.
- It **never injects** into the game process, doesn't touch game memory, and doesn't read/write anything.
- It only uses standard Windows calls (`GetForegroundWindow` + `CreateToolhelp32Snapshot`) to check which window is focused. It operates literally the exact same way Discord, Steam Overlay, or Task Manager checks what game you're playing.
- The actual game hook (`graphics-hook64.dll`) is the official OBS hook that is already whitelisted by Valve, EAC, BattlEye, and Faceit.

---

## How to use

1. Grab [`auto_game_display_toggle.lua`](auto_game_display_toggle.lua) and [`fg_helper.dll`](fg_helper.dll).
2. Drop both files into the same folder (e.g. `%APPDATA%\obs-studio\scripts\` or wherever you keep OBS scripts).
3. Open **OBS Studio** -> **Tools** -> **Scripts**.
4. Hit the **`+`** icon and select `auto_game_display_toggle.lua`.
5. Make sure your scene has:
   - **Game Capture** named `Game Capture` (Mode: *Capture any fullscreen application*)
   - **Display Capture** named `Display Capture`
6. Done. It just works.

---

## Settings

Inside **Tools -> Scripts -> auto_game_display_toggle.lua**:
- **Enable Auto Switcher:** Toggle the automation on/off.
- **Game Capture Source:** Pick your game capture source (default: `Game Capture`).
- **Display Capture Source:** Pick your display capture source (default: `Display Capture`).
- **Check Interval (ms):** Polling rate (default: `250 ms`, super light, uses 0% CPU).

---

## Building from source

If you don't trust to my prebuild stuff then go ahead, compile `fg_helper.dll` yourself:
1. Make sure you have Visual Studio (MSVC C++ tools) installed. 
2. Run `build.bat`. 

---

## s/o

s/o to **Gemini Flash 3.8** xddd shit ai slop getting everywhere. Needed to used to it (( ehhh

