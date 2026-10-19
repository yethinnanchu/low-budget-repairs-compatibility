# DLL investigation — 19 October 2026

## Exact build

- Game: Low-Budget Repairs 1.7.17, Unity 6000.3.22f1, Windows x64 IL2CPP.
- Metadata format: 39.
- Original GameAssembly.dll SHA256: `8ce33b4061abdee4a3307a8baeba9e27f80304b2e929513b68bebad8c3cdc16d`.
- Existing patched DLL SHA256: `31a92f17b08342baeb57171e4f8dbe3c17d6e5a92633fcd6e3e3bd812724cc12`.
- Matching global-metadata.dat SHA256: `a75e204fac9d5839c2ca8e757675971d3baf38366045cbaac9c35a576ebb4e8f`.

Method mapping used [yeonahlee/Il2CppDumper](https://github.com/yeonahlee/Il2CppDumper) source commit `f4269053f4acef9c3a835692b3f9e09539893a5e`, built locally. It detected metadata/IL2CPP v39 and found code registration at VA 0x184775000 and metadata registration at VA 0x1852F76F0. PE RVAs/file offsets and instructions were checked with pefile and Capstone. Generated full dumps and game binaries are not distributed.

## Confirmed existing bypass

`LoadingSceneController.<PreloadShaders>d__6.MoveNext()` starts at RVA 0x9648C0, file offset 0x962EC0.

At RVA 0x9649DE / file offset 0x962FDE:

```
original: 0F 84 66 05 00 00   conditional jump to RVA 0x964F4A
patched:  90 E9 66 05 00 00   nop; unconditional jump to RVA 0x964F4A
```

Both instructions end at RVA 0x9649E4, so the displacement remains valid. The skipped block includes a call at RVA 0x964E8B to `GraphicsStateCollection.WarmUpProgressively` at RVA 0x4231EB0 and completion polling via JobHandle. This explains why the bypass can avoid the preload failure. It can also move shader/graphics-state work into actual gameplay; it cannot ensure later render paths work.

## Other inspected paths

| Method | RVA | Observation |
|---|---|---|
| Portal.LocalTeleport | 0x7B14A0 | Door/local teleport path; skipping it would alter game behavior. |
| Portal.<>c__DisplayClass12_0.<LocalTeleport>b__0 | 0x7B9CF0 | Activates destination actions; this appears in the pre-failure log context. Presence on a stack does not establish it caused device loss. |
| Settings.SetScreenRefresh | 0x7C60B0 | Reads the configured frame-rate value and tail-calls Application.set_targetFrameRate at RVA 0x412FBF0. A forced DLL cap would duplicate a working in-game setting. |
| Settings.SetTextureQuality | 0x7C67E0 | Uses the selected settings; no demonstrated defect identified. |
| Majster.Quality.HDRPSettingsSetter.SetQualityLevel | 0x865CC0 | Inspected camera frame-settings path; no untested binary changes made. |

## Crash evidence and limits

Broken-balcony scene: `Apartment_a0_ap02_FixingBalcony`. The captured run completed scene loading, then the local teleport/entry path preceded D3D11 0x887A0005 errors. Resource-view and buffer creation failures and null-buffer locking followed. These later allocation failures do not identify which initial GPU operation lost the device. The user reports that retrying without ThrottleStop tuning still crashes. An overlay-free RTSS comparison remains outstanding.

No additional DLL patch has been demonstrated to reduce these crashes. Silently skipping mission/teleport actions, nulling graphics returns, changing allocation sizes, or patching global graphics wrappers would not be justified by this evidence. The existing diagnostic character trials likewise do not establish a balcony-scene repair.

Next useful evidence is a repeatable entry test with RTSS fully exited, tuning held constant, and the same save/graphics settings; then GPU/driver diagnostics or isolated scene/material tests. A new binary patch should include its exact mapped method, expected original instructions, reversible byte manifest and measured gameplay outcome before being presented as a compatibility improvement.
