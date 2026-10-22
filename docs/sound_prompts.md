# Sound prompts

An ElevenLabs prompt for each of the 60 non-music sounds in [assets.md](assets.md#sounds): 31 sound effects, 24 monster voices and 5 ambience loops. The 11 music tracks are made separately. Every path below is inside `assets/audio/`.

**Status:** all 60 are made with `tools/sounds/make_sounds.py` and approved by the user. They're in `audio_raw/` as WAV files, waiting for processing. The music isn't made yet.

The prompts are in the order to make them, not the order of assets.md. Matching sets come one after another: the die, the cards, the candle, the coins, the drips, the countdown, and each monster's three voices. The three hops share one prompt, and the thief is made in two parts, so there are 59 prompts for 60 files.

The settings were checked against ElevenLabs' Sound Effects docs in October 2026. If the tool looks different, tell Claude.

## Making a sound

1. Open Sound Effects in ElevenLabs.
2. Set the three settings from the prompt's **Settings** line:
   - **Duration:** turn Auto off and set the seconds. Some sounds, like the drumroll and the voices, are made longer than they need, so they aren't cut off. Processing cuts them to length.
   - **Looping:** on only for the ambience.
   - **Prompt influence:** 75% for exact sounds like the clicks, the coins and the bell, 50% for looser ones like the whooshes, and 80% for the voices and the thief's giggle. Higher follows the prompt more closely, and lower gives more varied takes.
3. Paste the whole prompt from the box. Each one fits the tool's limit of 450 characters.
4. Listen to all four variations and keep the best. Look out for:
   - words or speech, above all in the voices. A laugh or a groan can come out sounding like a word.
   - music under an effect or an ambience
   - echo or room noise behind an effect or a voice
   - the sound happening twice, like two snips instead of one
   - a voice that sounds cute, goblin-like or sexual instead of like a horror-movie monster
   - a sudden loud sound in an ambience loop

   Silence at the start or the end is fine. Processing trims it. If none of the four works, generate again. If a prompt keeps missing, tell Claude what's wrong, and Claude changes it here.
5. Download it as WAV if the tool offers it, otherwise MP3. Save it in `audio_raw/` under the same folder and name it has in `assets/audio/`, keeping the downloaded extension, for example `audio_raw/sfx/ui_click.wav`. Claude processes everything in `audio_raw/` into `assets/audio/`. `audio_raw/` has a `.gdignore` file so Godot doesn't import the raw sounds.

## How the prompts are built

Effect and ambience prompts have three parts: the sound itself, then Style and Sound. Voice prompts and the thief's giggle are the sound alone.

- **One sound per prompt.** A prompt that asks for two sounds in a row fails: the model drops one or overdoes one. Where assets.md describes two, like the thief's swipe and giggle, each gets its own prompt and processing joins them.
- **Style** is word for word the same in every effect and ambience prompt, so the whole set sounds like one game.
- **Sound** is word for word the same within each family: one block for effects and one for ambience. Effects are dry and close, like paper pieces on a tabletop. Ambience is wide and distant.
- **Paper and cardboard come in through the subjects:** the pieces, the die, the cards and the interface. They aren't in Style, because Style also goes into the ambience, where a paper word could put a rustle under the wind.
- **Matching sets share their words.** Every coin is "a small, thick gold coin", the die and the hops land on the same cardboard board, and each monster's three voices open with the same type.
- **Short, and mostly positive.** Sound prompts work best brief and concrete. Naming a sound can bring it in even after a "no", so the prompts say what to hear. The exception is "no music and no voices" in the ambience, which matters too much to leave out.

**Voices** are built differently. The first ones came out cut off, uncanny, goblin-like or sexual, and test rounds on a few monsters found what works:

- **Name a horror-movie type that sound libraries know well,** like "A werewolf", then one sound in plain words, and end with "Creature vocal, one take, fading out."
- **Make it 4 s at 80% prompt influence.** The model fills the time it's given, so a short clip gets cut off mid-sound. Processing trims the end.
- **Fit the sound to the moment.** A pick is an entrance, a win is smug or gleeful, and a lose is pained or deflating. A roar for a win sounds like a pick.
- **Don't give the model vowels to shape.** A voiced hiss or moan can turn into a word, so Death's sounds are breath and bones.
- **Never use** "man", "male" or a film actor, a sound that rises then trails off, descriptions of the mouth, or "theatrical", "full of character" or "menacing", which make it overact.

`death_lose` and `hyde_pick` were rated good in the first round, so they keep that round's prompts, with Style and the old voice Sound block.

The shared Style block:

> Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

The Sound blocks:

> **Effects:** Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
>
> **The two first-round voices:** Sound: a wordless monster vocal, menacing and full of character. No words, no speech. Dry and close-miked, on a clean silent background.
>
> **Ambience:** Sound: a quiet, seamless background ambience loop at night, wide and distant, at a steady level, with no music and no voices.

## Processing

Each prompt ends with a one-line note: the length, and whether it loops. Claude's script does this for each sound:

1. Trim the silence at the start and the end. Effects have to start instantly.
2. Cut it to the length in its note, with a short fade-out. The length is a maximum, so a shorter sound stays as it is.
3. Join the thief's two parts: the swipe, then the giggle.
4. Make the ambience loops seamless.
5. Even out the loudness, so no sound jumps out. The interface sounds (`ui_`) are the softest, the other effects sit in the middle, and the voices are the loudest. Ambience sits well under everything.
6. Make effects and voices mono. Ambience stays stereo.
7. Save it as OGG under its name and folder in `assets/audio/`.

This needs ffmpeg, which isn't installed yet.

## Sound effects: `sfx/`

### `sfx/ui_click.ogg`

**Settings:** duration 0.5 s, looping off, prompt influence 75%.

```text
One sharp flick of a fingernail against a stiff paper card: a single crisp, dry snap.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.2 s, one-shot.

### `sfx/ui_hover.ogg`

**Settings:** duration 0.5 s, looping off, prompt influence 75%.

```text
A very soft, short rustle of a paper card brushed lightly by a fingertip.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.2 s, one-shot.

### `sfx/ui_denied.ogg`

**Settings:** duration 0.5 s, looping off, prompt influence 75%.

```text
A single dull, muffled thud, like a knuckle knocking once on a thick cardboard box.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.3 s, one-shot.

### `sfx/hop_1.ogg`, `sfx/hop_2.ogg`, `sfx/hop_3.ogg`

**Settings:** duration 0.5 s, looping off, prompt influence 75%.

One prompt for all three. Keep three of the four variations, the ones most alike in loudness and length, and save them as `hop_1`, `hop_2` and `hop_3`. If fewer than three are good, generate again and pick across both rounds.

```text
A small cardboard game piece set down on a thick cardboard game board: one light, crisp tap.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.2 s, one-shot.

### `sfx/die_roll.ogg`

**Settings:** duration 1 s, looping off, prompt influence 75%.

```text
A hollow cardboard die tumbling and bouncing across a thick cardboard game board: a fast run of light, papery clatters.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 1 s, one-shot.

### `sfx/die_land.ogg`

**Settings:** duration 0.5 s, looping off, prompt influence 75%.

```text
A hollow cardboard die landing on a thick cardboard game board: one soft, papery thump as it settles.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.4 s, one-shot.

### `sfx/flip.ogg`

**Settings:** duration 0.5 s, looping off, prompt influence 75%.

```text
A stiff paper playing card flipping over in the air: a quick, light swish and a soft paper snap.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.4 s, one-shot.

### `sfx/card_slam.ogg`

**Settings:** duration 0.5 s, looping off, prompt influence 75%.

```text
A stiff paper playing card slapped down hard on a wooden table: one sharp, punchy slap.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.4 s, one-shot.

### `sfx/turn_start.ogg`

**Settings:** duration 1.5 s, looping off, prompt influence 50%.

```text
A soft, rising two-note chime on an old music box, eerie but inviting.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 1.2 s, one-shot.

### `sfx/timer_low.ogg`

**Settings:** duration 3 s, looping off, prompt influence 75%.

```text
A small candle flame sputtering, hissing and crackling as it struggles to stay lit, more and more frantic.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 3 s, one-shot.

### `sfx/timer_out.ogg`

**Settings:** duration 1 s, looping off, prompt influence 75%.

```text
A small candle flame snuffed out: one quick, soft puff, then a short, dying hiss.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.8 s, one-shot.

### `sfx/coin_gain.ogg`

**Settings:** duration 1 s, looping off, prompt influence 75%.

```text
A small, thick gold coin dropped onto a little pile of gold coins: one bright, satisfying clink.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.6 s, one-shot.

### `sfx/coin_lose.ogg`

**Settings:** duration 1 s, looping off, prompt influence 75%.

```text
A small, thick gold coin dropping away: a few clinks that fall in pitch and fade as it bounces off.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 1 s, one-shot.

### `sfx/coin_flip.ogg`

**Settings:** duration 1.5 s, looping off, prompt influence 75%.

```text
A small, thick gold coin flicked up with a thumb: a sharp metallic ping, then a fast, airy whirr as it spins.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 1.2 s, one-shot.

### `sfx/coin_land.ogg`

**Settings:** duration 1 s, looping off, prompt influence 75%.

```text
A small, thick gold coin dropped flat onto a wooden table: one solid, heavy clack as it lands, then a tiny bounce as it settles.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.8 s, one-shot.

### `sfx/fly.ogg`

**Settings:** duration 1 s, looping off, prompt influence 50%.

```text
A quick, light, airy whoosh with a soft, sparkling shimmer trailing behind it.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.6 s, one-shot.

### `sfx/blood_lose.ogg`

**Settings:** duration 1 s, looping off, prompt influence 75%.

```text
A single fat drop of thick liquid falling onto a stone floor: one heavy, low, wet splat, dark and sticky like blood.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.6 s, one-shot.

### `sfx/blood_gain.ogg`

**Settings:** duration 1 s, looping off, prompt influence 50%.

```text
A single fat drop of thick liquid in reverse: a soft, wet, rising slurp, ending in a tiny magical sparkle.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.8 s, one-shot.

### `sfx/spikes.ogg`

**Settings:** duration 1 s, looping off, prompt influence 75%.

```text
A row of sharp steel blades shooting up out of the floor all at once: one quick, bright, metallic shing, like knives drawn from a sheath.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.8 s, one-shot.

### `sfx/thief.ogg`

**Settings:** duration 0.5 s, looping off, prompt influence 75%.

The first half of `sfx/thief.ogg`. The giggle below is the second half, and processing joins the two.

```text
A gloved hand snatching something in one quick, sharp swipe: a short, fast whoosh.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.5 s, one-shot.

### `sfx/thief_giggle.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

The second half of `sfx/thief.ogg`, not a file of its own. It's made like the voices: no Style or Sound, and longer than it needs so it isn't cut off.

```text
A sneaky thief: one short, quiet, mischievous snicker, pleased with the steal. Vocal, one take, fading out.
```

**Processing:** 1.5 s, one-shot.

### `sfx/church.ogg`

**Settings:** duration 3 s, looping off, prompt influence 75%.

```text
A single bright, clear church bell, struck twice and ringing out softly.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 3 s, one-shot.

### `sfx/crumple.ogg`

**Settings:** duration 1 s, looping off, prompt influence 75%.

```text
A sheet of paper crushed into a tight ball in one quick squeeze: a short, crunchy crumple.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.8 s, one-shot.

### `sfx/respawn.ogg`

**Settings:** duration 0.5 s, looping off, prompt influence 75%.

```text
One bright, round, cheerful pop, like a cork pulled from a bottle.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.5 s, one-shot.

### `sfx/swap.ogg`

**Settings:** duration 1 s, looping off, prompt influence 50%.

```text
A fast double whoosh as two paper cutouts whip past each other, with a playful, swirling twist.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.8 s, one-shot.

### `sfx/countdown.ogg`

**Settings:** duration 0.5 s, looping off, prompt influence 75%.

```text
A single loud, hollow tick of an old grandfather clock, deep and ominous.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.5 s, one-shot.

### `sfx/countdown_go.ogg`

**Settings:** duration 1.5 s, looping off, prompt influence 50%.

```text
One short, bright, punchy chord stab on a church pipe organ, triumphant and spooky.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 1.2 s, one-shot.

### `sfx/drumroll.ogg`

**Settings:** duration 4 s, looping off, prompt influence 75%.

```text
A tense snare drumroll: one steady, unbroken roll that keeps growing louder the whole way through.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 3 s, one-shot.

### `sfx/trophy.ogg`

**Settings:** duration 2.5 s, looping off, prompt influence 75%.

```text
One big, bright, joyful major chord on a church pipe organ at full power, like a victory fanfare, held and ringing out.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 2.5 s, one-shot.

### `sfx/stat.ogg`

**Settings:** duration 0.5 s, looping off, prompt influence 50%.

```text
A single bright, playful plink on a bone xylophone, like tapping a skeleton's rib.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.
```

**Processing:** 0.5 s, one-shot.

## Monster voices: `voices/`

Each monster's prompts open with the same horror-movie type, so its sounds belong together. Make them back to back and compare them. A pick is an entrance, a win is smug or gleeful, and a lose is pained or deflating. Two first-round voices were rated good and keep their first-round prompts.

### `voices/dracula_pick.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A classic horror movie vampire: one long, low, chilling hiss, cold and sinister. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/dracula_win.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A classic horror movie vampire: one short, low, smug, sinister chuckle. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/dracula_lose.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A classic horror movie vampire: one sharp, pained screech, as if burned by sunlight. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/medusa_pick.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A snake-haired gorgon: one long, cold, venomous hiss, like a nest of snakes rising. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/medusa_win.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A snake-haired gorgon: one short, cold, wicked cackle, pleased with herself. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/medusa_lose.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A snake-haired gorgon: one piercing, furious shriek of pain. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/frankenstein_pick.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A huge undead monster: one deep, slow, low groan from deep in its chest, like a giant slowly waking up. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/frankenstein_win.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A huge undead monster: one deep, slow, pleased rumble, like a giant chuckling. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/frankenstein_lose.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A huge undead monster: one slow, sorrowful groan, heavy and defeated, like a giant slumping down. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/death_pick.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A grim reaper skeleton: one cold, hollow, breathy exhale, like a gust of wind through an empty skull. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/death_win.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A grim reaper skeleton: one quick, gleeful rattle of clattering bones, like a skeleton shaking with laughter. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/death_lose.ogg`

**Settings:** duration 2.5 s, looping off, prompt influence 50%.

Kept from the first round, where it was rated good, so it keeps that round's prompt.

```text
Death, the Grim Reaper, a skeleton in a hooded robe, with dry, rattling bones and a hollow, rasping breath. A hollow, rasping groan, then his skull dropping and clattering across a wooden floor.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a wordless monster vocal, menacing and full of character. No words, no speech. Dry and close-miked, on a clean silent background.
```

**Processing:** 2.5 s, one-shot.

### `voices/hyde_pick.ogg`

**Settings:** duration 2.5 s, looping off, prompt influence 50%.

Kept from the first round, where it was rated good, so it keeps that round's prompt.

```text
Mr. Hyde, a hunched, savage Victorian brute with a rough, gravelly, unhinged voice. A wild, wheezing, unhinged cackle.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a wordless monster vocal, menacing and full of character. No words, no speech. Dry and close-miked, on a clean silent background.
```

**Processing:** 2.5 s, one-shot.

### `voices/hyde_win.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A classic horror movie maniac: one short, gleeful, wicked snicker. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/hyde_lose.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A classic horror movie maniac: one short, bitter, frustrated growl, beaten. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/cthulhu_pick.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A colossal sea monster from the deep: one slow, deep, gurgling roar, alien and ominous. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/cthulhu_win.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A colossal sea monster from the deep: one deep, slow, satisfied rumble, bubbling and strange. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/cthulhu_lose.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A colossal sea monster from the deep: one long, low, defeated groan, deep and gurgling, alien and strange. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/wolfman_pick.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A werewolf: one long, wild, powerful howl at the full moon. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/wolfman_win.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A werewolf: one sharp, excited, triumphant bark. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/wolfman_lose.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A werewolf: one sad, pitiful whine, like a beaten dog. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/dorian_pick.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A classic horror movie aristocratic villain: one short, cold, sinister laugh, elegant and cruel. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/dorian_win.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A classic horror movie aristocratic villain: one short, smug, sneering scoff. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

### `voices/dorian_lose.ogg`

**Settings:** duration 4 s, looping off, prompt influence 80%.

```text
A classic horror movie aristocratic villain: one sharp, horrified gasp, as his youth slips away. Creature vocal, one take, fading out.
```

**Processing:** 4 s, one-shot.

## Ambience: `ambience/`

Turn Looping on for all five. 30 seconds is the longest the tool makes, which is the short end of the 30 to 60 seconds in assets.md. Each prompt keeps its rare sounds rare, so the repeat is hard to hear.

### `ambience/village.ogg`

**Settings:** duration 30 s, looping on, prompt influence 50%.

```text
A foggy village street: a soft, steady wind, a wooden shop sign creaking slowly on its chains, and now and then a dog barking far away.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a quiet, seamless background ambience loop at night, wide and distant, at a steady level, with no music and no voices.
```

**Processing:** 30 s, seamless loop.

### `ambience/graveyard.ogg`

**Settings:** duration 30 s, looping on, prompt influence 50%.

```text
A graveyard on a hill: soft wind through long grass, a few crows cawing now and then, and once, a faraway church bell tolling.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a quiet, seamless background ambience loop at night, wide and distant, at a steady level, with no music and no voices.
```

**Processing:** 30 s, seamless loop.

### `ambience/forest.ogg`

**Settings:** duration 30 s, looping on, prompt influence 50%.

```text
A dark forest: leaves rustling in a soft breeze, old branches creaking, and an owl hooting now and then.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a quiet, seamless background ambience loop at night, wide and distant, at a steady level, with no music and no voices.
```

**Processing:** 30 s, seamless loop.

### `ambience/swamp.ogg`

**Settings:** duration 30 s, looping on, prompt influence 50%.

```text
A murky swamp: a chorus of croaking frogs, mud bubbling and popping, and insects buzzing and chirping.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a quiet, seamless background ambience loop at night, wide and distant, at a steady level, with no music and no voices.
```

**Processing:** 30 s, seamless loop.

### `ambience/castle.ogg`

**Settings:** duration 30 s, looping on, prompt influence 50%.

```text
Outside a mountain castle in a storm: wind howling around stone towers, distant rolling thunder, and bats fluttering and squeaking now and then.

Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound.

Sound: a quiet, seamless background ambience loop at night, wide and distant, at a steady level, with no music and no voices.
```

**Processing:** 30 s, seamless loop.
