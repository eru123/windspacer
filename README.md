# WindSpacer (Windows Disk Spacer)

Make any drive on your Windows PC **look completely full**: instantly, safely, and reversibly.

WindSpacer drops one big "spacer" file onto the drive you choose. The space is genuinely
reserved (Explorer, apps, and Windows all see a full disk), but no real data is ever
written, so filling 50 GB takes half a second, and deleting the file hands every byte
back just as fast.

```
  ==================================================
              W I N D S P A C E R
           make a drive look full, undo it anytime
  ==================================================

  Your drives right now:
   C:  ██████████████████░░   92% full   17.8 GB free
   G:  ███████████░░░░░░░░░   57% full   50.8 GB free   > spacer file: 22.6 GB

  What would you like to do?
   [1] Make a drive look full
   [2] Release space (undo)
   [3] How does this work?
   [4] Exit
```

## Run it straight from this repo (no install)

1. Click **Start**, type `powershell`, press Enter.
2. Paste this line and press Enter:

```powershell
iwr 'https://raw.githubusercontent.com/eru123/windspacer/main/windspacer.ps1' -UseBasicParsing -OutFile "$env:TEMP\windspacer.ps1"; & "$env:TEMP\windspacer.ps1"
```

3. That's it, the menu appears. Pick a number and follow the prompts.

> Reminder for the non-technical folks: pasting one-liners from the internet runs code on
> your PC. Only ever do this from repos you trust.

## Rather download it?

**Easy way:** on this repo's GitHub page click **Code → Download ZIP**, extract it
anywhere, then double-click **`windspacer.bat`**.

**Git way:**

```bash
git clone https://github.com/eru123/windspacer.git
```

…then double-click `windspacer.bat` (keep `windspacer.bat` and `windspacer.ps1` in the
same folder).

If Windows SmartScreen shows "Windows protected your PC" the first time, click
**More info → Run anyway**.

## What it can do

- **Fill a drive**: either completely (you choose how much breathing room it keeps:
  5 GB recommended, 2 GB slim, or 10 GB roomy) or by a **custom size** ("add exactly 37 GB").
- **Release space**: finds every spacer file it created, shows how much each one holds,
  and gives the space back the moment you confirm.
- **Plain-language confirmations**: every action shows exactly what will happen
  ("Free space now 50.8 GB → after 2.0 GB it will look FULL") before touching anything.
- **A live dashboard**: colored fill-bars for every drive, with a tag showing which
  drives currently hold fake space.

## How it works

Imagine parking a giant cardboard box in your garage. The box holds nothing, but nobody
else can park there. WindSpacer creates one big file (`spacer.dat`) that takes up real
space on the drive, so Windows thinks the drive is full. Deleting the box hands the whole
garage back instantly. Nothing else on the drive is touched.

Use it to test how apps behave on a full disk, to fake a "disk full" state for demos or
support training, or to keep spare capacity reserved so nothing else eats it.

## Getting your space back

Option **2** in the menu, or simply delete the `spacer.dat` file sitting in the drive's
root (for `C:` it lives in your user folder). The space returns immediately.

## Safety notes

- Never leaves a drive with less than **1 GB** free, and "fill completely" always keeps
  the breathing room you picked.
- Extra warnings before touching `C:`: a full Windows drive makes Windows nag and some
  apps misbehave until you release it.
- No data is written to disk and nothing is modified besides the single `spacer.dat` file.
- No admin rights needed in most setups (if a drive root refuses the file, it
  automatically falls back to your user folder on `C:`).

## Requirements

Windows 10/11 with PowerShell (included with Windows). Works in Windows Terminal,
PowerShell, or a plain Command Prompt window.

## License

[MIT](LICENSE), free to use, tweak, and share.
