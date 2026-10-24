# Generates docs/sound_prompts.md so the shared blocks stay word for word identical.
import math
import sys

OUT_PATH = sys.argv[1]
MAX_CHARS = 450  # ElevenLabs' Sound Effects prompt limit

STYLE = "Style: spooky but lighthearted and theatrical. Crisp, clean, professionally recorded sound."

SOUND = {
    "effect": "Sound: a single isolated one-shot, dry and close-miked, starting instantly, on a clean silent background.",
    "voice": "Sound: a wordless monster vocal, menacing and full of character. No words, no speech. "
    "Dry and close-miked, on a clean silent background.",
    "ambience": "Sound: a quiet, seamless background ambience loop at night, wide and distant, "
    "at a steady level, with no music and no voices.",
}

# Words shared by matching sets
COIN = "A small, thick gold coin"
DIE = "A hollow cardboard die"
BOARD = "a thick cardboard game board"
CARD = "A stiff paper playing card"
CANDLE = "A small candle flame"
DROP = "A single fat drop of thick liquid"
ORGAN = "a church pipe organ"


def fmt(seconds):
    return f"{seconds:g} s"


# make: a longer length to generate at, so the sound isn't cut off; processing cuts it to seconds.
# bare: the subject alone, without Style and Sound. part: half of another file, joined in processing.
def entry(path, subject, family, seconds, influence, note=None, label=None, make=None, bare=False, part=False):
    if family == "ambience":
        duration, looping, proc = seconds, "on", f"{fmt(seconds)}, seamless loop."
    else:
        # The tool's shortest clip is 0.5 s; keep to half-second steps and let processing cut
        duration = make or max(0.5, math.ceil(seconds * 2) / 2)
        looping, proc = "off", f"{fmt(seconds)}, one-shot."
    return dict(path=path, label=label, subject=subject, family=family, note=note, proc=proc, bare=bare, part=part,
                settings=f"duration {fmt(duration)}, looping {looping}, prompt influence {influence}%.")


def effect(name, subject, seconds, influence=75, **kw):
    return entry(f"sfx/{name}.ogg", subject, "effect", seconds, influence, **kw)


def ambience(name, subject):
    return entry(f"ambience/{name}.ogg", subject, "ambience", 30, 50)


# ---------------------------------------------------------------- sound effects
effects = [
    effect(
        "ui_click",
        "One sharp flick of a fingernail against a stiff paper card: a single crisp, dry snap.",
        0.2,
    ),
    effect("ui_hover", "A very soft, short rustle of a paper card brushed lightly by a fingertip.", 0.2),
    effect("ui_denied", "A single dull, muffled thud, like a knuckle knocking once on a thick cardboard box.", 0.3),
    effect(
        "hop_1",
        f"A small cardboard game piece set down on {BOARD}: one light, crisp tap.",
        0.2,
        label="`sfx/hop_1.ogg`, `sfx/hop_2.ogg`, `sfx/hop_3.ogg`",
        note="One prompt for all three. Keep three of the four variations, the ones most alike in loudness and length, "
        "and save them as `hop_1`, `hop_2` and `hop_3`. If fewer than three are good, generate again and pick across both rounds.",
    ),
    effect("die_roll", f"{DIE} tumbling and bouncing across {BOARD}: a fast run of light, papery clatters.", 1.0),
    effect("die_land", f"{DIE} landing on {BOARD}: one soft, papery thump as it settles.", 0.4),
    effect("flip", f"{CARD} flipping over in the air: a quick, light swish and a soft paper snap.", 0.4),
    effect("card_slam", f"{CARD} slapped down hard on a wooden table: one sharp, punchy slap.", 0.4),
    effect("turn_start", "A soft, rising two-note chime on an old music box, eerie but inviting.", 1.2, 50),
    effect(
        "timer_low",
        f"{CANDLE} sputtering, hissing and crackling as it struggles to stay lit, more and more frantic.",
        3,
    ),
    effect("timer_out", f"{CANDLE} snuffed out: one quick, soft puff, then a short, dying hiss.", 0.8),
    effect("coin_gain", f"{COIN} dropped onto a little pile of gold coins: one bright, satisfying clink.", 0.6),
    effect("coin_lose", f"{COIN} dropping away: a few clinks that fall in pitch and fade as it bounces off.", 1.0),
    effect("coin_flip", f"{COIN} flicked up with a thumb: a sharp metallic ping, then a fast, airy whirr as it spins.", 1.2),
    effect(
        "coin_land",
        f"{COIN} dropped flat onto a wooden table: one solid, heavy clack as it lands, then a tiny bounce as it settles.",
        0.8,
    ),
    effect("fly", "A quick, light, airy whoosh with a soft, sparkling shimmer trailing behind it.", 0.6, 50),
    effect("blood_lose", f"{DROP} falling onto a stone floor: one heavy, low, wet splat, dark and sticky like blood.", 0.6),
    effect("blood_gain", f"{DROP} in reverse: a soft, wet, rising slurp, ending in a tiny magical sparkle.", 0.8, 50),
    effect(
        "spikes",
        "A row of sharp steel blades shooting up out of the floor all at once: "
        "one quick, bright, metallic shing, like knives drawn from a sheath.",
        0.8,
    ),
    effect(
        "thief",
        "A gloved hand snatching something in one quick, sharp swipe: a short, fast whoosh.",
        0.5,
        note="The first half of `sfx/thief.ogg`. The giggle below is the second half, and processing joins the two.",
    ),
    effect(
        "thief_giggle",
        "A sneaky thief: one short, quiet, mischievous snicker, pleased with the steal. Vocal, one take, fading out.",
        1.5,
        80,
        make=4,
        bare=True,
        part=True,
        note="The second half of `sfx/thief.ogg`, not a file of its own. It's made like the voices: "
        "no Style or Sound, and longer than it needs so it isn't cut off.",
    ),
    effect("church", "A single bright, clear church bell, struck twice and ringing out softly.", 3),
    effect("crumple", "A sheet of paper crushed into a tight ball in one quick squeeze: a short, crunchy crumple.", 0.8),
    effect("respawn", "One bright, round, cheerful pop, like a cork pulled from a bottle.", 0.5),
    effect("swap", "A fast double whoosh as two paper cutouts whip past each other, with a playful, swirling twist.", 0.8, 50),
    effect("countdown", "A single loud, hollow tick of an old grandfather clock, deep and ominous.", 0.5),
    effect("countdown_go", f"One short, bright, punchy chord stab on {ORGAN}, triumphant and spooky.", 1.2, 50),
    effect(
        "drumroll",
        "A tense snare drumroll: one steady, unbroken roll that keeps growing louder the whole way through.",
        3,
        make=4,
    ),
    effect(
        "trophy",
        f"One big, bright, joyful major chord on {ORGAN} at full power, like a victory fanfare, held and ringing out.",
        2.5,
    ),
    effect("stat", "A single bright, playful plink on a bone xylophone, like tapping a skeleton's rib.", 0.5, 50),
]

# ---------------------------------------------------------------- monster voices
VOICE_END = "Creature vocal, one take, fading out."

# Each monster's horror-movie type opens all three of its prompts, then one sound for the moment:
# a pick is an entrance, a win is smug or gleeful, a lose is pained or deflating.
MONSTERS = [
    (
        "dracula",
        "A classic horror movie vampire",
        [
            "one long, low, chilling hiss, cold and sinister.",
            "one short, low, smug, sinister chuckle.",
            "one sharp, pained screech, as if burned by sunlight.",
        ],
    ),
    (
        "medusa",
        "A snake-haired gorgon",
        [
            "one long, cold, venomous hiss, like a nest of snakes rising.",
            "one short, cold, wicked cackle, pleased with herself.",
            "one piercing, furious shriek of pain.",
        ],
    ),
    (
        "frankenstein",
        "A huge undead monster",
        [
            "one deep, slow, low groan from deep in its chest, like a giant slowly waking up.",
            "one deep, slow, pleased rumble, like a giant chuckling.",
            "one slow, sorrowful groan, heavy and defeated, like a giant slumping down.",
        ],
    ),
    (
        "death",
        "A grim reaper skeleton",
        [
            "one cold, hollow, breathy exhale, like a gust of wind through an empty skull.",
            "one quick, gleeful rattle of clattering bones, like a skeleton shaking with laughter.",
            None,
        ],
    ),
    (
        "hyde",
        "A classic horror movie maniac",
        [
            None,
            "one short, gleeful, wicked snicker.",
            "one short, bitter, frustrated growl, beaten.",
        ],
    ),
    (
        "cthulhu",
        "A colossal sea monster from the deep",
        [
            "one slow, deep, gurgling roar, alien and ominous.",
            "one deep, slow, satisfied rumble, bubbling and strange.",
            "one long, low, defeated groan, deep and gurgling, alien and strange.",
        ],
    ),
    (
        "wolfman",
        "A werewolf",
        [
            "one long, wild, powerful howl at the full moon.",
            "one sharp, excited, triumphant bark.",
            "one sad, pitiful whine, like a beaten dog.",
        ],
    ),
    (
        "dorian",
        "A classic horror movie aristocratic villain",
        [
            "one short, cold, sinister laugh, elegant and cruel.",
            "one short, smug, sneering scoff.",
            "one sharp, horrified gasp, as his youth slips away.",
        ],
    ),
]

# Rated good in the first round, so they keep their first-round prompts and settings
FIRST_ROUND = {
    "death_lose": "Death, the Grim Reaper, a skeleton in a hooded robe, with dry, rattling bones and a hollow, rasping breath. "
    "A hollow, rasping groan, then his skull dropping and clattering across a wooden floor.",
    "hyde_pick": "Mr. Hyde, a hunched, savage Victorian brute with a rough, gravelly, unhinged voice. "
    "A wild, wheezing, unhinged cackle.",
}

voices = [
    entry(f"voices/{name}_{moment}.ogg", FIRST_ROUND[f"{name}_{moment}"], "voice", 2.5, 50,
          note="Kept from the first round, where it was rated good, so it keeps that round's prompt.")
    if sound is None
    else entry(f"voices/{name}_{moment}.ogg", f"{kind}: {sound} {VOICE_END}", "voice", 4, 80, bare=True)
    for name, kind, sounds in MONSTERS
    for moment, sound in zip(["pick", "win", "lose"], sounds)
]

# ---------------------------------------------------------------- ambience
ambiences = [
    ambience(
        "village",
        "A foggy village street: a soft, steady wind, a wooden shop sign creaking slowly on its chains, "
        "and now and then a dog barking far away.",
    ),
    ambience(
        "graveyard",
        "A graveyard on a hill: soft wind through long grass, a few crows cawing now and then, "
        "and once, a faraway church bell tolling.",
    ),
    ambience("forest", "A dark forest: leaves rustling in a soft breeze, old branches creaking, and an owl hooting now and then."),
    ambience("swamp", "A murky swamp: a chorus of croaking frogs, mud bubbling and popping, and insects buzzing and chirping."),
    ambience(
        "castle",
        "Outside a mountain castle in a storm: wind howling around stone towers, distant rolling thunder, "
        "and bats fluttering and squeaking now and then.",
    ),
]

SECTIONS = [
    ("Sound effects", "sfx", effects, None),
    (
        "Monster voices",
        "voices",
        voices,
        "Each monster's prompts open with the same horror-movie type, so its sounds belong together. "
        "Make them back to back and compare them. A pick is an entrance, a win is smug or gleeful, "
        "and a lose is pained or deflating. Two first-round voices were rated good and keep their first-round prompts.",
    ),
    (
        "Ambience",
        "ambience",
        ambiences,
        "Turn Looping on for all five. 30 seconds is the longest the tool makes, which is the short end of the "
        "30 to 60 seconds in assets.md. Each prompt keeps its rare sounds rare, so the repeat is hard to hear.",
    ),
]

INTRO = """# Sound prompts

An ElevenLabs prompt for each of the {files} non-music sounds in [assets.md](assets.md#sounds): 31 sound effects, 24 monster voices and 5 ambience loops. The 11 music tracks are made separately. Every path below is inside `assets/audio/`.

**Status:** all 60 are made with `tools/sounds/make_sounds.py` and approved by the user. They're in `audio_raw/` as WAV files, and `tools/sounds/process_sounds.py` has processed them into `assets/audio/`. The user reviewed and approved the processed files. The music isn't made yet.

The prompts are in the order to make them, not the order of assets.md. Matching sets come one after another: the die, the cards, the candle, the coins, the drips, the countdown, and each monster's three voices. The three hops share one prompt, and the thief is made in two parts, so there are {count} prompts for {files} files.

The settings were checked against ElevenLabs' Sound Effects docs in October 2026. If the tool looks different, tell Claude.

## Making a sound

1. Open Sound Effects in ElevenLabs.
2. Set the three settings from the prompt's **Settings** line:
   - **Duration:** turn Auto off and set the seconds. Some sounds, like the drumroll and the voices, are made longer than they need, so they aren't cut off. Processing cuts them to length.
   - **Looping:** on only for the ambience.
   - **Prompt influence:** 75% for exact sounds like the clicks, the coins and the bell, 50% for looser ones like the whooshes, and 80% for the voices and the thief's giggle. Higher follows the prompt more closely, and lower gives more varied takes.
3. Paste the whole prompt from the box. Each one fits the tool's limit of {max_chars} characters.
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

- **Name a horror-movie type that sound libraries know well,** like "A werewolf", then one sound in plain words, and end with "{VOICE_END}"
- **Make it 4 s at 80% prompt influence.** The model fills the time it's given, so a short clip gets cut off mid-sound. Processing trims the end.
- **Fit the sound to the moment.** A pick is an entrance, a win is smug or gleeful, and a lose is pained or deflating. A roar for a win sounds like a pick.
- **Don't give the model vowels to shape.** A voiced hiss or moan can turn into a word, so Death's sounds are breath and bones.
- **Never use** "man", "male" or a film actor, a sound that rises then trails off, descriptions of the mouth, or "theatrical", "full of character" or "menacing", which make it overact.

`death_lose` and `hyde_pick` were rated good in the first round, so they keep that round's prompts, with Style and the old voice Sound block.

The shared Style block:

> {STYLE}

The Sound blocks:

> **Effects:** {SOUND_effect}
>
> **The two first-round voices:** {SOUND_voice}
>
> **Ambience:** {SOUND_ambience}

## Processing

Each prompt ends with a one-line note: the length, and whether it loops. Claude's script does this for each sound:

1. Trim the silence at the start and the end. Effects have to start instantly.
2. Cut it to the length in its note, with a short fade-out. The length is a maximum, so a shorter sound stays as it is.
3. Join the thief's two parts: the swipe, then the giggle.
4. Make the ambience loops seamless.
5. Even out the loudness, so no sound jumps out. The interface sounds (`ui_`) are the softest, the other effects sit in the middle, and the voices are the loudest. Ambience sits well under everything.
6. Make effects and voices mono. Ambience stays stereo.
7. Save it as OGG under its name and folder in `assets/audio/`.

`tools/sounds/process_sounds.py` does all of this with ffmpeg. The loudness targets are -28 LUFS for the interface, -22 for the other effects, -19 for the voices and -34 for the ambience, with peaks at most -1.5 dBFS. One-shots are measured by their loudest 200 ms, and ambience over its whole length. A few sharp hits, like the hops and the card slam, reach the peak limit first and come out up to 4 dB quieter.
"""


def prompt(e):
    if e["bare"]:
        return e["subject"]
    return "\n\n".join([e["subject"], STYLE, SOUND[e["family"]]])


def render(e):
    lines = [f"### {e['label'] or '`' + e['path'] + '`'}", "", f"**Settings:** {e['settings']}", ""]
    if e["note"]:
        lines += [e["note"], ""]
    lines += ["```text", prompt(e), "```", "", f"**Processing:** {e['proc']}", ""]
    return "\n".join(lines)


all_entries = [e for _, _, entries, _ in SECTIONS for e in entries]
lengths = {e["path"]: len(prompt(e)) for e in all_entries}
too_long = {p: n for p, n in lengths.items() if n > MAX_CHARS}
if too_long:
    sys.exit(f"Over {MAX_CHARS} characters: {too_long}")

count = len(all_entries)
files = count + 2 - sum(e["part"] for e in all_entries)  # hop_1 makes hop_2 and hop_3 too
assert files == 60, files

intro = (
    INTRO.replace("{files}", str(files))
    .replace("{count}", str(count))
    .replace("{max_chars}", str(MAX_CHARS))
    .replace("{STYLE}", STYLE)
    .replace("{VOICE_END}", VOICE_END)
)
for family, text in SOUND.items():
    intro = intro.replace("{SOUND_" + family + "}", text)

parts = [intro]
for title, folder, entries, blurb in SECTIONS:
    parts.append(f"## {title}: `{folder}/`\n")
    if blurb:
        parts.append(blurb + "\n")
    parts += [render(e) for e in entries]

with open(OUT_PATH, "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(parts).rstrip("\n") + "\n")

longest = max(lengths, key=lengths.get)
print(f"{count} prompts for {files} files written to {OUT_PATH}")
print(f"Longest prompt: {longest}, {lengths[longest]} characters")
