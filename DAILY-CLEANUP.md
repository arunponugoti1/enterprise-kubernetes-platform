# Daily Disk Cleanup — How to Run

A 3-section PowerShell script that **checks → removes → validates** temp/cache/log files on C: drive.
Safe: never touches Documents, Pictures, Downloads, OneDrive, browser passwords, or app data.

---

## 1. Where the script lives

```
C:\Users\ponug\Scripts\Daily-Cleanup.ps1
```

You don't open this file. You just call it from PowerShell.

---

## 2. Where to run the commands

1. Press **Windows key** → type `powershell` → press **Enter**.
   (A blue/black PowerShell window opens.)
2. Paste the command from Step 3 below into that window.
3. Press **Enter**.

> No need to `cd` anywhere. The script runs from any folder.

### One-time setup (only the very first time)

If you see an error like *"running scripts is disabled on this system"*, run this **once**:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Type **Y** and press Enter when asked. You never need to run this again.

---

## 3. The daily commands

### Step A — Preview (deletes nothing, just shows numbers)

```powershell
& "C:\Users\ponug\Scripts\Daily-Cleanup.ps1" -WhatIf
```

Run this the **first time** to see what the script would remove.

### Step B — Real cleanup

```powershell
& "C:\Users\ponug\Scripts\Daily-Cleanup.ps1"
```

Run this **every day** (or whenever you want to free space).

---

## 4. What you'll see

The output has 3 clearly labeled sections:

```
===== 1. CHECK =====
User Temp                250.4 MB  (1832 files)
Edge/IE Web Cache         85.2 MB  (504 files)
...
------ TOTAL ------      450.7 MB

===== 2. REMOVE =====
  cleaned: User Temp
  cleaned: Edge/IE Web Cache
  ...

===== 3. VALIDATE =====
User Temp                now    1.2 MB  (freed 249.2 MB)
...
------ FREED ------      448.5 MB
```

| Section | Meaning |
|---|---|
| **CHECK**    | How much junk exists right now |
| **REMOVE**   | Deletes it (or simulates if `-WhatIf`) |
| **VALIDATE** | Re-measures and shows how much was freed |

---

## 5. Run as Administrator (optional, weekly)

A normal PowerShell can clean **user-level** temp files.
To also clean `C:\Windows\Temp` and Windows Update cache, run **once a week** as admin:

1. Windows key → type `powershell`
2. **Right-click** "Windows PowerShell" → **Run as administrator**
3. Click **Yes** on the UAC prompt
4. Paste the same command from Step 3B and press **Enter**

---

## 6. Schedule it daily (one-time setup, optional)

Run this **once** in a normal PowerShell window to make Windows run the script automatically every day at 9:00 AM:

```powershell
schtasks /Create /TN "Daily Cleanup" /TR "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Users\ponug\Scripts\Daily-Cleanup.ps1" /SC DAILY /ST 09:00 /F
```

Change `09:00` to your preferred time (24-hour format).

To remove the schedule later:
```powershell
schtasks /Delete /TN "Daily Cleanup" /F
```

---

## 7. What it cleans / what it leaves alone

**Cleans (only files older than 1 day):**
- `%TEMP%` — your user temp folder
- Edge/IE web cache
- Windows error reports & crash dumps
- RDP cache
- `C:\Windows\Temp` (admin only)
- Windows Update Delivery Optimization cache (admin only)

**Never touches:**
- Documents, Pictures, Desktop, Downloads
- OneDrive
- Browser passwords, bookmarks, cookies, history
- Saved Gmail / app credentials
- Anything in `AppData\Roaming` (app settings)
- Recycle Bin (unless you add the flag)
