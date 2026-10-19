# Low-Budget Repairs 1.7.17 — experimental Intel UHD 620 workarounds

For owners of the exact Windows IL2CPP build of Low-Budget Repairs v1.7.17 made with Unity 6000.3.22f1. Investigated on Intel UHD 620, 16 GB shared system memory and Intel driver 31.0.101.2145. Other builds and hardware are untested. Hash checks reject mismatched files.

## What is included

- `startup`: reproduces the existing two-byte GameAssembly.dll workaround that allowed this machine to get past startup and reach gameplay. At file offset 0x962FDE, `0F 84` becomes `90 E9`, converting a conditional branch into an unconditional branch to the same destination. The exact mapped method is `LoadingSceneController.<PreloadShaders>d__6.MoveNext()` (RVA 0x9648C0). The branch at RVA 0x9649DE skips its graphics-state preload loop and goes to RVA 0x964F4A. See [DLL investigation](DLL-INVESTIGATION.md). This is not a general shader or engine repair.
- `trial1`: disables animated LOD crossfading on living Zbyszek's LODGroup. All detail levels remain. Transitions can visibly pop. A test still encountered device removal while loading; this is not an established fix.
- `trial2`: disables shadow casting on living Zbyszek's 12 renderers across detail levels. A test still encountered device removal while loading; this is not an established fix.
- `trial3`: temporarily disables his hair and moustache renderers for diagnosis. This visibly removes those parts. Progress was possible with partial views and interaction, but the full-body freeze was not demonstrated to be fixed.

The three character trials are alternatives, not cumulative patches. Restore one before applying another. These trials affect level3 (Zbyszek's apartment), not the broken-balcony scene.

## How it helps — and its limits

The startup workaround enabled gameplay on the tested machine. The optional scene trials provide reversible comparisons for isolating a camera-dependent character freeze. No FPS improvement has been measured for these changes.

Later apartment-entry crashes remain unresolved. Logs showed D3D11 device removal (0x887A0005), followed by failed graphics allocations and native crashes. One balcony crash persisted with ThrottleStop tuning disabled. RTSS overlay involvement has not been established. This package does not claim to fix these problems or recommend overclocking, TDR registry changes, unsupported launch flags, or mission skipping.

## Apply and restore

Close the game. Open PowerShell in this folder and specify your installation path:

```powershell
.\Patch.ps1 -Patch startup -Action Validate -GameFolder 'C:\Games\Low-Budget.Repairs.v1.7.17'
.\Patch.ps1 -Patch startup -Action Apply -GameFolder 'C:\Games\Low-Budget.Repairs.v1.7.17'
.\Patch.ps1 -Patch startup -Action Restore -GameFolder 'C:\Games\Low-Budget.Repairs.v1.7.17'
```

Replace `startup` with `trial1`, `trial2`, or `trial3` for a diagnostic scene trial. `Validate` only checks hashes and computes the result in memory. `Apply` saves the original file into a local `backups` directory, checks expected bytes and hashes, and verifies the installed result. `Restore` reverses the selected patch after validating its exact patched hash. Already-applied/already-restored states are reported without rewriting files. Unknown files are refused.

Keep the backups. Back up your saves separately before testing. No game executable, DLL, asset file, save, credentials, machine-specific log, or driver is distributed here. You must supply your own matching installation. No affiliation with the game developer, Intel, or Unity is implied.

## Validation

Character trial bytes were generated from parsed Unity renderer/LODGroup fields and the result reparsed before testing. Startup byte differences were compared against the preserved original DLL, inspected in native disassembly and mapped using the matching metadata-v39 file. Packaging validation checks original-to-patched hashes for all four transformations, without modifying the installed game. Gameplay stability and compatibility remain experimental. Further investigation has not established an additional safe DLL optimization; no new DLL byte patch is included in the investigation update.
