# Omnissa OS Optimization Tool: Golden Image Prep

A Windows batch script that prepares a **Windows 11 25H2** golden image for **Omnissa Horizon**. It runs the Omnissa Horizon OS Optimization Tool (OSOT) with a custom template, cleans up temporary data, disables update services, runs a Cortex image scan, and shuts the machine down so it is ready to be snapshotted.

| | |
|---|---|
| **Version** | 1.0 |
| **Author** | Fabio |
| **Created** | 13.11.2026 |
| **Target OS** | Windows 11 25H2 |

## What the script does

1. **Pre-checks**: verifies that the OSOT executable and the XML template exist; exits with an error if either is missing.
2. **Runs OSOT** in optimization mode using the XML template plus command-line overrides (see below).
3. **Cleans `C:\temp`**: deletes all files and subfolders.
4. **Empties the Recycle Bin** via PowerShell (`Clear-RecycleBin`).
5. **Stops and disables** the Windows Update (`wuauserv`) and Microsoft Edge Update (`edgeupdate`) services.
6. **Runs a Cortex (Palo Alto Networks) image preparation scan** on `C:\Temp` using `cytool`.
7. **Releases the IP address** and **shuts down** the machine after 10 seconds with the message "Image Ready".

## OSOT settings applied

| Parameter | Value |
|-----------|-------|
| `-o` | Optimize mode |
| `-t` | Use the XML template defined in `TEMPLATEFile` |
| `-OneDrive` | disable |
| `-HVCI` | disable |
| `-Smartscreen` | disable |
| `-securitycenter` | disable |
| `-firewall` | disable |
| `-antivirus` | disable |
| `-storeapp` | remove all, except ScreenSketch, Calculator, Photos |
| `-officeupdate` | disable |
| `-windowsupdate` | disable |
| `-notification` | disable |
| `-visualeffect` | balanced |
| `-SyncHkcuToHku` | enable |
| `-background` | `#4c4a48` |
| `-f` | Finalize tasks `0 1 3 4 5 7 8 9 10` (see the OSOT documentation for what each index does) |

## Requirements

- Windows 11 25H2 golden image VM (run **as Administrator**)
- Omnissa Horizon OS Optimization Tool installed in `C:\Program Files\Omnissa\OSOptimization`
- The OSOT XML template in the same folder
- Cortex agent installed at `C:\Program Files\Palo Alto Networks\Traps\` (for the file scan step)
- PowerShell available (used for the Recycle Bin cleanup)

## Configuration

Edit the variables at the top of the script:

```bat
set "OSOTFile=OmnissaHorizonOSOptimizationTool-x86_64-1.2.2609.37751670449.exe"
set "OSOTPath=C:\Program Files\Omnissa\OSOptimization"
set "TEMPLATEFile=RUAG-Win11 25H2-V1.0.xml"
```

When you update OSOT or the template, change `OSOTFile` and `TEMPLATEFile` accordingly.

## Usage

1. Boot the golden image and sign in with an administrator account.
2. Make sure OSOT and the template are in place.
3. Open an **elevated** Command Prompt and run:

   ```bat
   Optimize-GoldenImage.cmd
   ```

4. The VM shuts down automatically when finished. Take your snapshot afterwards and use it for your Horizon pool or image.

> **Warning:** the script disables the firewall, antivirus, Windows Update and other protections, releases the IP address and powers the machine off. Only run it on a golden image that is meant to be finalized, never on a production machine.

## Notes and known quirks

- **`C:\temp` cleanup:** the script runs `cd /d C:\temp` followed by `del /s`. If `C:\temp` does not exist, `cd` fails and the delete command runs in the script's current directory. Consider guarding it with `if exist C:\temp` or `cd /d C:\temp || exit /b 1`.
- **Line continuation:** the OSOT command ends with `-f 0 1 3 4 5 7 8 9 10 ^` followed by a trailing space and an empty line. Remove the trailing `^` and space on the last line to avoid unexpected behavior.
- **Exit codes:** the OSOT call does not check its exit code, so the script continues even if OSOT fails. Adding an `if errorlevel 1` check after it would make failures visible.
- **Recycle Bin check:** `-ErrorAction SilentlyContinue` hides errors from `Clear-RecycleBin`, so the `errorlevel` check after it will rarely trigger.
- **Cortex scan:** the `cytool imageprep scan` arguments (`timeout 1 upload 1`) depend on your Cortex agent version. Check them against your Cortex documentation.

## Troubleshooting

| Problem | Likely cause / fix |
|---------|--------------------|
| `ERROR: OSOT executable not found!` | `OSOTFile` or `OSOTPath` is wrong, or OSOT is not installed. |
| `ERROR: XML template not found!` | The template is missing from `OSOTPath` or `TEMPLATEFile` has the wrong name. |
| `Access is denied` | The script is not running in an elevated Command Prompt. |
| Cortex scan does not start | The agent is missing or installed in a different path. Verify `cytool.exe` exists. |
| Services fail to stop | They may already be stopped; this is harmless. |

## License

Add your preferred license here (e.g. MIT) or mark the repository as internal.
