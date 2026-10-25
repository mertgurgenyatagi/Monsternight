# Assets

Every asset the game needs, as a running list. Claude adds to it as the game grows. The user fetches each file and puts it in `assets/`, at the root of the repository, using the folder and file name given here. Claude then wires it in. A file that's in place is done.

The [first playable](roadmap.md#1-first-playable) needed 84 images, 2 fonts, and 71 sounds. The final game adds 10 images and 14 sounds (part 26): the minigames' pieces, two icons, and the sounds of the minigames, the powers and the lobby. Everything else is reused (see [Reused for the final game](#reused-for-the-final-game)).

## For every image

- **PNG with a transparent background,** trimmed close to the shape.
- **Paper cutout** (see [art_and_audio.md](art_and_audio.md)): flat construction-paper shapes, few colors, faint paper texture, slightly uneven hand-cut edges. Colorful, never bleak.
- **One piece per file,** no sprite sheets. The game does all the animating.
- **No text,** because the game adds text so it can be translated. The logo is the only exception.
- **No baked-in shadows or lighting.** The game adds one soft shadow under every piece, so everything looks like paper lifted off the page.
- **Monsters and props face right.**
- **Sizes are rough.** Bigger is fine, since the game scales down.

## For every sound

- **OGG** (Ogg Vorbis).
- **Music:** organ and theremin, as seamless loops. Every track is a version of one main melody, the Monsternight theme.
- **Sound effects:** short, with no silence at the start.
- **Monster voices:** no words, only laughs, howls, hisses, and so on.

## Images

### Shared scenery: `assets/art/scenery/`

| File | What it shows | Size |
|---|---|---|
| `moon.png` | A big paper full moon | 600 × 600 |
| `star.png` | A small paper star. The game scatters them and makes them twinkle | 48 × 48 |
| `fog_1.png` | A long, soft strip of paper fog | 1200 × 300 |
| `fog_2.png` | Another fog strip with a different shape | 1200 × 300 |
| `bat.png` | A bat with its wings spread. The game makes it flap | 160 × 80 |
| `paper_texture.png` | Very faint paper fibers in light grey, laid over everything. Must tile seamlessly | 1024 × 1024 |

Each location below has a far strip (the distant skyline), a ground strip (the earth under the path), and a few props. Far and ground strips must tile seamlessly sideways.

### Foggy village: `assets/art/scenery/`

| File | What it shows | Size |
|---|---|---|
| `village_far.png` | Distant crooked rooftops and chimneys, a few lit windows | 2048 × 600 |
| `village_ground.png` | The edge of a cobbled road | 2048 × 300 |
| `village_house_1.png` | A crooked house with lit windows | 600 tall |
| `village_house_2.png` | Another crooked house, a different shape | 600 tall |
| `village_lamp.png` | A gas street lamp. The game adds the glow | 500 tall |

### Graveyard and church: `assets/art/scenery/`

| File | What it shows | Size |
|---|---|---|
| `graveyard_far.png` | Hills dotted with crosses and bare trees | 2048 × 600 |
| `graveyard_ground.png` | Grassy earth with roots | 2048 × 300 |
| `graveyard_stone_1.png` | A rounded tombstone | 250 tall |
| `graveyard_stone_2.png` | A cross-shaped grave marker | 300 tall |
| `graveyard_tree.png` | A bare, twisted tree | 800 tall |
| `church_hill.png` | The hill above the graveyard that the church path runs over | 2400 × 800 |
| `church_building.png` | A small stone church with a bell tower and lit windows | 1000 tall |

### Dark forest: `assets/art/scenery/`

| File | What it shows | Size |
|---|---|---|
| `forest_far.png` | A dense line of pointed trees | 2048 × 600 |
| `forest_ground.png` | Forest floor with roots and leaves | 2048 × 300 |
| `forest_tree_1.png` | A twisted tree, maybe with a face in the bark | 900 tall |
| `forest_tree_2.png` | Another twisted tree | 900 tall |
| `forest_mushrooms.png` | A cluster of glowing toadstools | 200 tall |

### Swamp: `assets/art/scenery/`

| File | What it shows | Size |
|---|---|---|
| `swamp_far.png` | Low, misty trees hung with moss | 2048 × 600 |
| `swamp_ground.png` | A muddy bank | 2048 × 300 |
| `swamp_water.png` | Murky green water. The game makes it bob. Tiles sideways | 2048 × 200 |
| `swamp_boardwalk.png` | A rickety plank walkway for the upper path. Tiles sideways | 1024 × 150 |
| `swamp_tree.png` | A cypress hung with moss | 900 tall |
| `swamp_reeds.png` | A clump of reeds and cattails | 300 tall |

### Dracula's castle: `assets/art/scenery/`

| File | What it shows | Size |
|---|---|---|
| `castle_far.png` | Jagged mountains | 2048 × 600 |
| `castle_ground.png` | An old stone road | 2048 × 300 |
| `castle.png` | Dracula's castle on a cliff, all towers and lit windows | 1600 tall |
| `castle_gate.png` | Big castle doors at the end of the road. This is the finish | 700 tall |
| `castle_torch.png` | A wall torch with no flame. The game adds `flame.png` | 250 tall |

### Board: `assets/art/board/`

| File | What it shows | Size |
|---|---|---|
| `space.png` | A plain round paper token for a board space. The game tints it and puts an icon on it | 192 × 192 |
| `die_1.png` to `die_6.png` | The six faces of a paper die, with 1 to 6 pips (six files) | 160 × 160 |
| `path_dot.png` | A small paper scrap. The game lines them up between spaces | 32 × 32 |
| `signpost.png` | A wooden signpost with no writing, one at each split | 400 tall |
| `arrow.png` | A paper arrow pointing right. Players click one at a split | 160 × 100 |

### Icons: `assets/art/icons/`

| File | What it shows | Size |
|---|---|---|
| `coin.png` | A gold coin. Also used for coin counts, the gold stake, and the coin flip | 256 × 256 |
| `blood.png` | A drop of blood. Also used for blood counts and the blood stake | 128 × 128 |
| `swap.png` | Two curved arrows chasing each other, for the swap stake | 128 × 128 |
| `spikes.png` | A row of spikes | 128 × 128 |
| `thief.png` | A sneaky gloved hand, grabbing | 128 × 128 |
| `church.png` | A little chapel | 128 × 128 |
| `atlas.png`, `archive.png`, `lab.png`, `stage.png` | The four question categories' icons (made by the user, done; prompts in [asset_prompts.md](asset_prompts.md#category-icons-icons)) | 128 × 128 |
| `flag.png` | A small pennant. Marks the finish and players who have finished | 128 × 128 |

### Monsters: `assets/art/monsters/`

Each monster needs two files: a full body (`<name>.png`, standing, facing right, about 512 tall) and a portrait (`<name>_portrait.png`, head and shoulders, 256 × 256). Its color from [characters.md](characters.md) should show on it.

| Files | Monster |
|---|---|
| `dracula.png`, `dracula_portrait.png` | Dracula: a pale count with slicked hair and a black cape with a red lining |
| `medusa.png`, `medusa_portrait.png` | Medusa: snakes for hair and a green, scaly gown |
| `frankenstein.png`, `frankenstein_portrait.png` | Frankenstein's Monster: flat head, neck bolts, stitches, a jacket too small, a touch of yellow lightning |
| `death.png`, `death_portrait.png` | Death: a hooded robe, a skull face, a scythe, and a violet glow |
| `hyde.png`, `hyde_portrait.png` | Mr. Hyde: a hunched brute in a torn Victorian suit with an orange waistcoat |
| `cthulhu.png`, `cthulhu_portrait.png` | Cthulhu: a teal octopus head with face tentacles and small wings |
| `wolfman.png`, `wolfman_portrait.png` | The Wolf Man: a werewolf in a torn blue shirt |
| `dorian.png`, `dorian_portrait.png` | Dorian Gray: a dandy in a fine pink suit, holding his portrait in a frame |

| File | What it shows | Size |
|---|---|---|
| `stand.png` | A small paper stand that every monster stands on, like a board game piece | 200 × 60 |
| `crumpled.png` | A crumpled paper ball. A monster crumples into it when it loses a duel or dies | 256 × 256 |

### Interface: `assets/art/ui/`

| File | What it shows | Size |
|---|---|---|
| `logo.png` | "Monsternight" in cut-paper letters. The only image with text | 1600 × 500 |
| `cursor.png` | A bony skeleton hand pointing, with the fingertip in the top-left corner | 64 × 64 |
| `panel.png` | A plain paper card with torn edges, even all around so the game can stretch it | 512 × 512 |
| `button.png` | A paper tag for buttons. The game stretches it sideways | 400 × 120 |
| `card.png` | A blank paper playing card, for the stake cards and the VS card | 400 × 560 |
| `portrait_frame.png` | A paper frame for portraits. The game tints it in the monster's color | 300 × 300 |
| `flame.png` | A flame, for the board's torches | 64 × 96 |
| `trophy.png` | A paper trophy cup | 256 × 256 |
| `curtain.png` | The left half of a red theater curtain. The game mirrors it for the right half | 1000 × 1080 |
| `curtain_top.png` | The curtain's scalloped top border | 1920 × 200 |

### Reused for the final game

Principle 2: a new image only where nothing old can do the job.

| Need | Reuses |
|---|---|
| Medusa's stone | The piece tinted grey. When it cracks off, a few `path_dot.png` scraps, tinted grey, fly off as chips |
| Dracula's steal | `blood.png`, flying like any blood |
| The powers' word pops | Text in the display font |
| The lobby | `panel.png` for the room code card, `button.png` for Copy link and Ready, and the readiness as text |

### Fonts: `assets/fonts/`

TTF or OTF.

| File | What it's for | Suggestion |
|---|---|---|
| `display.ttf` | Titles, the countdown, and big numbers. Gothic, with a hand-cut feel | Grenze Gotisch (Google Fonts) |
| `body.ttf` | Everything else. Must be easy to read at small sizes | Spectral (Google Fonts) |

## Sounds

### Music: `assets/audio/music/`

The five board tracks share one tempo and key, so the game can crossfade between them in time.

| File | When it plays, and the feel | Length |
|---|---|---|
| `title.ogg` | Title and setup screens. The main theme in full: playful and spooky | 1.5 to 2 min |
| `select.ogg` | Monster select. A lighter, ticking version | 1 min |
| `board_village.ogg` | The leader is in the village. Quiet and foggy | 2 min |
| `board_graveyard.ogg` | The leader is at the graveyard or church. Creeping and sparse, with a hymn-like organ | 2 min |
| `board_forest.ogg` | The leader is in the forest. Busier, with a bouncing bass line | 2 min |
| `board_swamp.ogg` | The leader is in the swamp. Woozy, with a wobbling theremin | 2 min |
| `board_castle.ogg` | The leader is at the castle. Full pipe organ, grand and urgent: the climax | 2 min |
| `duel.ogg` | Duels: the VS card and the countdown (and the coin flip, until each minigame is built). Minigames themselves have no music. Fast and tense | 1 min |
| `ceremony.ogg` | The trophy ceremony. Triumphant, but still spooky | 1.5 min |
| `sting_final_turn.ogg` | Plays once as the last turn starts. Not a loop | 3 s |
| `sting_finish.ogg` | Plays once when a player reaches the castle gate. Not a loop | 3 s |

### Ambience: `assets/audio/ambience/`

Quiet, seamless loops of 30 to 60 seconds that play under the music.

| File | What it sounds like |
|---|---|
| `village.ogg` | Wind, a creaking sign, a distant dog |
| `graveyard.ogg` | Crows, wind in the grass, and now and then a faraway church bell |
| `forest.ogg` | Owls, creaking branches, rustling leaves |
| `swamp.ogg` | Frogs, bubbles, buzzing insects |
| `castle.ogg` | Distant thunder, bats, howling wind |

### Sound effects: `assets/audio/sfx/`

| File | What it sounds like |
|---|---|
| `ui_hover.ogg` | A soft paper rustle when the mouse moves onto something clickable |
| `ui_click.ogg` | A crisp flick of a paper card |
| `ui_denied.ogg` | A dull thud, for clicking something that's greyed out |
| `timer_low.ogg` | A sputtering candle, for each of the last 5 seconds of a decision |
| `timer_out.ogg` | A candle being snuffed out: time's up |
| `turn_start.ogg` | A soft chime when a player's turn starts |
| `die_roll.ogg` | A paper die tumbling |
| `die_land.ogg` | The die landing with a soft thump |
| `hop_1.ogg`, `hop_2.ogg`, `hop_3.ogg` | A paper game piece tapped down on a board. Three versions so the steps don't all sound the same |
| `flip.ogg` | The swish of a card flipping over |
| `coin_gain.ogg` | A coin clink |
| `coin_lose.ogg` | A coin dropping away |
| `spikes.ogg` | Blades shooting up with a metallic shing |
| `thief.ogg` | A quick snatch and a sneaky giggle |
| `church.ogg` | One bright bell ringing twice |
| `blood_lose.ogg` | A wet drip |
| `blood_gain.ogg` | A reversed drip with a little sparkle |
| `crumple.ogg` | Paper crumpling into a ball |
| `respawn.ogg` | A bright pop |
| `swap.ogg` | A whoosh as two players trade places |
| `card_slam.ogg` | A card slapped down on a table, for the VS card and picking a stake |
| `countdown.ogg` | One tick, played for 3, 2, and 1 |
| `countdown_go.ogg` | A bright organ stab: go |
| `coin_flip.ogg` | A coin flicked into the air, spinning |
| `coin_land.ogg` | The coin landing and settling |
| `fly.ogg` | The swish of coins or blood flying across the screen |
| `drumroll.ogg` | A drumroll before each trophy, about 3 seconds |
| `trophy.ogg` | A warm organ chord as a trophy is handed out |
| `stat.ogg` | A playful plink for each fun stat |

**The final game's effects** (part 26), also in `assets/audio/sfx/`:

| File | What it sounds like |
|---|---|
| `power.ogg` | An eerie theremin swoop under every power's word pop |
| `stone.ogg` | Medusa's victims turning to stone |
| `stone_crack.ogg` | The stone cracking off on their turn |
| `join.ogg` | Someone joins the lobby: two knocks on a door |
| `leave.ogg` | Someone leaves or drops: a door closing |
| `ready.ogg` | Someone clicks Ready: a rubber stamp on paper |
| `start.ogg` | The host starts the match: a heavy door creaking open |

No new music: minigames have none (Q17), and the lobby plays `title.ogg`.

### Monster voices: `assets/audio/voices/`

Three per monster: `<name>_pick.ogg` when it's picked, `<name>_win.ogg` when it wins a duel, and `<name>_lose.ogg` when it loses a duel or dies. The ideas below are suggestions.

| Name | Pick | Win | Lose |
|---|---|---|---|
| `dracula` | A theatrical villain laugh | A smug chuckle and a cape swish | A shocked hiss |
| `medusa` | A nest of hissing snakes | Stone cracking, then a hiss | A shriek |
| `frankenstein` | A low groan | A happy grunt and an electric zap | A long, sad moan |
| `death` | A scythe swish and rattling bones | A slow, bony clap | A skull clattering to the floor |
| `hyde` | A wild cackle | A roar | A pained snarl |
| `cthulhu` | A deep, gurgling rumble | A bubbling roar | A sinking gurgle |
| `wolfman` | A howl | A barking howl | A whimper |
| `dorian` | A charming chuckle | A satisfied hum | Glass cracking, as his portrait breaks |
