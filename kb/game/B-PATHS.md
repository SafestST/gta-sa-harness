# B-PATHS
covers: G-0256..G-0328
domain: game | type: bundle | path: data\Paths\**
format: nodes (binary) + img + ipl | depth: P1

## Role
The **navigation/path-node network** — 73 files that drive AI movement: vehicle
pathfinding and pedestrian routes. `NODES0..NODESn.DAT` are the binary node
graphs (verified binary; headers + node records, 2D/3D flags, links).
`carrec.img` is an IMG of recorded car paths; `*.pth`/`*.npx` style entries
accompany them; the maps-root `paths*.ipl` connect the node network to world
instances.

## Structure
- `NODES*.DAT`: binary; node position (x,y,z), link lists, flags. Record layout
  [UNVERIFIED] without a node-format spec.
- `carrec.img`: standard IMG (see G-0339) holding recorded paths.
- `paths*.ipl` (covered by B-WORLD-DEFS) place the path markers in world space.

## Relations
- Feeds CVehicle pathfinding + CPed route AI; paired with data\maps\paths*.ipl.
- Cross-domain: SAMP vehicle/ped AI still rides the same game node network.

## Annotations
- Binary depth; a full decode needs the documented SA node format (GTAModding).
  The file inventory (73) plus names is the safe, complete structural record.
