# B-AUDIO
covers: G-0025..G-0056
domain: game | type: bundle | path: audio\**
format: audio-bank + lookup tables | depth: P2

## Role
The **audio system** — 32 files, 3.3 GB. Streamed music/speech banks
(`SPC_EA..SPC_PA` radio stations, `GENRL`, `SCRIPT` (320 MB mission speech),
`FEET` footsteps, `PAIN_A`, `CUTSCENE`, `ADVERTS`, `AMBIENCE`) plus the index
tables that map events->banks: `BankSlot.dat`, `BankLkup.dat`, `TrakLkup.dat`,
`StrmPaks.dat`, `PakFiles.dat`, `EventVol.dat`. `AudioEvents.txt` /
`AudioEventHistory.txt` (data\, in B-DATA-CONFIG) define the events.

## Structure
- Streamed banks: compressed audio streams (packages of tracks).
- `.dat` index files: bank slot/lookup tables (binary); exact layout
  [UNVERIFIED] without audio-format docs.
- Bank naming: SPC_<X> = radio per locale? [UNVERIFIED] - names like SPC_EA/FA/GA/NA/PA map to stations.

## Relations
- AudioEvents -> BankSlot/TrakLkup -> streamed bank; drives script audio
  commands in main.scm (G-0329).

## Annotations
- P2 fingerprint only: sizes/hashes recorded; inner stream decode out of scope
  for the harness (needs audio tooling). Structural record complete.
