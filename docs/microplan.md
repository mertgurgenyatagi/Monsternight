# Microplan

The [final game](roadmap.md#2-final-game), built in parts after the first playable's 24. `/microplan` plans parts in detail and keeps a rough roadmap to the end (see `.claude/skills/microplan/SKILL.md`). It runs in its own session.

- **The brief:** the user's direction for the final game is [final_game_brief.md](questionnaire_answers/final_game_brief.md), saved word for word. The design docs ([game_rules.md](game_rules.md), [board.md](board.md), [characters.md](characters.md), [minigames.md](minigames.md), [screens.md](screens.md), [tech.md](tech.md)) say what the game is. Questionnaires ended at 18; the rest is Claude's call.
- **The code map:** the first playable's notes ([microplan_first_playable.md](microplan_first_playable.md#part-notes)) plus "Part notes" at the end of this file. Read the section your part touches instead of rereading the code.

## Building a part

One part per session, on its own branch from `development`. A part session reads `README.md`, this file, and only the docs and code its part touches.

A part is done when:

1. It runs in Godot with no errors or warnings.
2. Everything in its Polish list is in: animated, with its sounds, nothing glossed over.
3. Claude has checked it by running the game, not just by reading the code. **Keep the testing small** (the user is low on tokens): one headless script for the rules, one short bot run, and a Playwright pair of tabs only where the part says so.
4. No screenshots are saved. A screenshot is only for debugging.
5. Its Part notes are written (short). The branch is committed, pushed and merged into `development`, and `development` is pushed and checked out. The part session never waits for the user. This needs no git approval (README, Handover 3).
6. The session disconnects from the Godot MCP (README, Handover 5), and closes the Godot editor after that.
7. The session's last message ends with `q7Zk#x2` as a line of its own (README, Handover 6) -- except part 51, which ends the process.

If a part turns out too big, split it (46a, 46b) instead of rushing it.

## Microplan 15: the pivot (2026-10-25)

The user played the 1.0.0 build and sent thirteen points. The big one: **the four minigames are thrown out** (real-time games over a free relay do not work) and replaced by one, **Shot in the Dark**. Where each point lands:

| Point | Part |
|---|---|
| 1 Shot in the Dark replaces the minigames | 45 (local), 46 (online) |
| 2 Too long: two dice | 47 (dice, turn counts), 49 (pace) |
| 3 Music: list every moment | the list below; wiring in 50 |
| 4 Online control indicators differ per side | 46 (one symmetric layout) |
| 5 Click a HUD portrait for a powers popup | 48 |
| 6 Back button from the stake step to the opponent step | 47 |
| 7 Numeric countdown instead of the candle | 48 |
| 8 Things get in the way of other things | 49 |
| 9 Everything faster | 49 |
| 10 Zero-sum stakes | 47 |
| 11 Powers that don't play nice: change them | 45 (Hyde), 47 (the rest) |
| 12 Little testing | every part |
| 13 Assets: the user retrieves them, Claude writes prompts | done: [asset_prompts.md](asset_prompts.md#category-icons-icons) has 4 icons; no new sounds are needed |

**Decided with the user:** the Blood stake is a drain (the loser loses 1 blood and the winner gains 1, up to their cap), so it is unavailable unless both players are below their cap (Frankenstein as challenger only needs to be able to win it). Swap stays as it is: the challenger wins it or nothing happens; it is always available.

**Claude's calls:** two dice are added together; the Wolf Man gets +1 per die (+2); Mr. Hyde's guess counts as 20% closer when he starts the duel; a swap duel needs 2 wins before 1 loss (was 3; Dorian still needs 1) because every round is a 20-second question; the decision timers shrink in part 49; local play passes the keyboard.

## Question data format

The user's file is [`sitd_questions/`](../sitd_questions/): `sitd_1000_questions.json` (the source of truth; the `.csv` and `.md` are the same data). **1000 questions**, ids 1 to 1000, each `{id, category, question_en, question_tr, answer}`. The answer is a number: 929 integers, 69 decimals (like -273.15), 3 negatives, from -273.15 to 40075. There are no unit fields: the unit is in the question ("in meters"). There are 75 fine categories (10 to 30 questions each), no repeats in English.

**The four board categories** (a board space shows one, and the question comes from its group; the part keeps the table in one data file, `data/question_groups.json`, and a fine category that is not listed goes to the Stage with a warning):

| Space (icon) | Name | Fine categories (the JSON's `category`) | Questions |
|---|---|---|---|
| `atlas` | The Atlas | Landmarks & Architecture, Geography & Nature, Geography & Geopolitics, Geography & Cities, Transport & Aviation, Demographics & Cities, Oceans & Polar, Exploration & Records, Geology & Earth, Atmosphere & Weather, Transport & Infrastructure, Aviation & Records, Landmarks & Monuments, Theme Parks & World, Space & Astronomy, Astronomy & Universe | 210 |
| `archive` | The Archive | History, History & (Archaeology, Ancient Rome, Ancient Greece, Egypt, Medieval, Ottoman, Royalty, Asia, Americas, USA, Cold War, Disasters, Medicine), Art & Masters, Literature & Books, Languages & Linguistics, Science & Nobel, Inventions & Tech, Brands & Business, Economy & Finance | 240 |
| `lab` | The Lab | Science & Physics, Science & Chemistry, Biology & Anatomy, Animals & Nature, Human Body & Medicine, Health & Diseases, Human Records, Microbiology & Biology, Nature & Botany, Animals & Predators, Marine Life (both), Birds & Flight, Insects & Invertebrates, Mammals & Primates, Canines & Pets, Felines & Pets, Farm Animals, Extreme Wildlife, Agriculture & Produce | 220 |
| `stage` | The Stage | everything else: Cinema, TV, Music, Video Games, Comics, Toys, Games & Chess, Internet, every Sports and every Food category | 330 |

A match never asks the same id twice (`Match.asked`); a group that runs dry starts over.

## Music moments

Every place where music would fit. The files are made by the user. "New" marks what the old list in [assets.md](assets.md#music-assetsaudiomusic) did not have.

**Loops (11 old + 2 new):**
1. Title, setup, lobby and room (`title`)
2. Monster select (`select`)
3. Board, leader in the village (`board_village`)
4. Board, leader at the graveyard or church (`board_graveyard`)
5. Board, leader in the forest (`board_forest`)
6. Board, leader in the swamp (`board_swamp`)
7. Board, leader at the castle (`board_castle`)
8. Duel intro: the VS card (`duel`)
9. Trophy ceremony (`ceremony`)
10. **New:** choosing an opponent and a stake (`challenge`)
11. **New:** Shot in the Dark, the 20 seconds of thinking (`shot`)

**Stings (2 old + 7 new):**
12. Last turn begins (`sting_final_turn`)
13. A player reaches the castle gate (`sting_finish`)
14. **New:** the match starts, as the turn order is rolled (`sting_start`)
15. **New:** the answers are revealed, under the drumroll (`sting_reveal`)
16. **New:** a duel is won (`sting_win`)
17. **New:** a tie, a new question (`sting_draw`)
18. **New:** a player dies and goes back to the start (`sting_death`)
19. **New:** a trophy is handed out at the ceremony (`sting_trophy`)
20. **New:** the champion is crowned at the end of the ceremony (`sting_champion`)

No music: the pause menu and settings (the board's music just ducks), the loading and catch-up curtain, the "Rejoin" and error banners. Ambience loops stay as they are.

## Parts

Seven parts, 45 to 51. They are small on purpose, and none of them needs the relay to be deployed. **Do not microplan after 45 or 48** (the README's multiple-of-3 rule would trigger it): the plan is already made. Part 51 ends the process.

### Part 45: Shot in the Dark, local

**Goal:** a minigame space on the board plays Shot in the Dark on one screen: a question appears, both players type a number in secret, the answers are revealed, the closest wins. The four old games are gone.

**Builds:**
- **Data.** Copy `sitd_questions/sitd_1000_questions.json` to `data/questions.json` (res://) and write `data/question_groups.json` (the table above). `Questions` (static, `src/minigames/questions.gd`): `load_all`, `pick(group, exclude_ids, rng) -> Dictionary`, `text(q)` (Turkish or English by `Settings`), group of a fine category. Add `tools/questions/check_questions.py` (ids unique, answers numeric, both languages present, every fine category mapped, counts per group) and run it once.
- **The game.** `ShotGame` (`src/minigames/shot_game.gd`, code-built, drawn in the frame's 1920 x 1080 space on a paper card): the category tag with its icon, the question in the display font (wrapped, up to 175 characters), the **countdown** (a big number for now; part 48 gives the real `Countdown`), a number box on each side (the challenger on the left, as before, the opponent on the right), a paper keypad (0-9, minus, decimal mark, backspace, Lock in) and the keyboard: digits and numpad, `-`, `.` or `,` for the decimal (both accepted), Backspace, Enter locks. Digits are grouped with a thin space for reading (8 848). A locked box can't change. 30 seconds (was 20), or the moment both have locked.
- **The score.** `ShotGame.judge(a, b, answer, hyde_side) -> int` (side 0, side 1, or `Minigame.DRAW`): the smaller `|guess - answer|` wins; **Hyde, when he is the challenger, has his distance multiplied by 0.8**; no answer loses to an answer; two blanks or an exact tie is a draw. A draw shows "A tie! New question" and asks another (no limit for a duel; a swap duel round counts only when someone wins; after 3 draws in a row the challenger loses, so a duel cannot hang).
- **Local play (pass the keyboard).** The challenger types first behind a cover card ("Name: look, the others look away" with an "I'm ready" button), locks, then the cover passes to the opponent, who also gets 20 seconds; then the reveal. Same layout as online (part 46).
- **The reveal.** The drumroll, then the true answer slams into the middle as a paper card (`card_slam`), the two guesses flip over (`flip`) and count up to their number, "off by N" tags appear under them, the winner's card lifts with a green ribbon and the portrait hops, the loser droops. Click skips it. About 3.5 s.
- **The frame.** `MinigameFrame.play(challenger, opponent, stake, kind)` keeps its signature and result (`{winner, loser, rounds}`), so `Duel`, `Challenge` and the board are untouched. The VS strips stay, the 3-2-1 and the keycap controls go. Swap duels run rounds with a new question each; the tally already exists (`DuelTally`).
- **The board.** `BoardRoller.MINIGAMES` become four free letters for the four groups (the quick kinds keep theirs); `Space` draws the group icons (`icons/atlas`, `archive`, `lab`, `stage`; add them to `make_outlines.py`'s `ICONS`, which bakes the rims); the old icons stop being used. The space's tooltip or name tag, if any, uses the group name (both languages).
- **Mr. Hyde.** His power becomes "his guess counts as 20% closer when he starts the duel" in `characters.md`, `Monsters` and the Turkish strings. The 10% edges in the old games go away with them.
- **Removed:** `pong_game`, `tug_game`, `sumo_game`, `soccer_game`, `circle_physics`, `stub_game`, `mini_link`, `minigame_input`, `Minigames.GAMES`, the `Minigame` physics base (what `ShotGame` does not need), `tools/tests/minigame_net_test*`, the unused images (`assets/art/minigames/*`, `icons/pong|sumo|tug_of_war|head_soccer`) and sounds (`paddle_hit`, `bounce`, `kick`, `jump`, `sumo_bump`, `rope_pull`, `rope_tug`, `whistle`). The raws stay in `images_raw/` and `audio_raw/`. **Online duels:** until part 46, an online duel lets the host flip a fair coin (`coin_flip`), so the build still runs.
- **Docs:** rewrite `minigames.md` (Shot in the Dark, the four spaces, the swap duel, draws), and fix `game_rules.md` (the board spaces), `characters.md` (Hyde), `board.md` and `assets.md` where they name the old games.

**Polish:** the number boxes grow a little when a digit is typed (a small squash), a pencil-scribble feel for the digits (`ui_click`), `ready` on Lock in with the box getting a paper stamp, the card slides in on a bounce and the question words pop in line by line (about 0.4 s total), the countdown number turns red and shakes in the last 5 s with `timer_low` ticks and `timer_out` at 0, an invalid key (a second minus, a second decimal mark) shakes the box with `ui_denied`, the cover card slides across with `flip`.

**Assets:** the 4 category icons (prompts in `asset_prompts.md`; `python tools/images/process_images.py . atlas archive lab stage`). If the user has not delivered them yet, use `coin`-tinted stand-ins and say so in the notes; no part waits for them. Existing sounds only.

**Check:** the checker script; a headless test of `judge` (closest, Hyde 0.8, blank, tie, negative and decimal answers), of the typing rules (minus, decimal mark, comma, length cap) and of `Questions.pick` (no repeats, group fallback); one plain run with `-- --bot` and a forced landing to see a full duel through to the board.

**Risks:** the thin-space grouping and the decimal comma in Turkish; a long question must fit the card (wrap, then shrink the font to fit). The cover card is the only privacy: a camera over the shoulder is the players' problem.

### Part 46: Shot in the Dark, online

**Goal:** the same duel over the relay: the two duelists type in secret on their own computers, everyone else watches, and no real-time stream is needed. Both sides of the duel see the identical layout (point 4).

**Builds:**
- **Messages.** The question: `Online.decide("question")`, the host picks the id (it avoids `Match.asked`) and every copy shows it in its own language. A duelist's lock goes only to the host (`shot_lock {r, value}`); the host tells everyone `shot_status {side, locked}` so the others see a tick on the box and never the number. When both are locked, or the host's clock reaches 30 s plus a 1 s grace, the host sends `shot_reveal {a, b}` (a missing answer is `null`) and **every copy runs the same reveal and `judge`** (no separate `mini_end`). The countdown on each copy is only for show.
- **Symmetry.** One layout for everybody: challenger left, opponent right, same sizes and positions. Your own box has a "You" tag and the keypad; the others see no keypad and a "writing..." mark that turns into a stamp at the lock. Spectators and the opponent see the same picture except the tag. A headless check compares the two copies' node positions.
- **Log and rejoin.** `Online._log` gets an entry `{k:"s", id, a, b}` (replacing `{k:"m"}`); a rejoiner replays logged duels instantly and a duel in progress shows as a spectator until the reveal.
- **Drops and migration.** A dropped or "Away" duelist has no answer (the host reveals as soon as the present one has locked, after a 3 s grace); a duelist whose copy lost the host keeps their typed value and re-sends it to a new host; the new host restarts the clock with what is left.
- **Cleanup.** `Online.decide("minigame")`, the coin fallback, `MiniLink` leftovers and the `mini` debug flag go; `--bot` types a random plausible number after 3 to 8 s; `?mini=` becomes `?group=atlas|archive|lab|stage` to force a category.
- **Docs:** `tech.md` (the online model: no streams, a few messages per duel, which is what the relay can carry), `screens.md` (the duel).

**Polish:** the spectators' boxes show the tick with `ready` as each locks, the "waiting for Name" line appears when one has locked and the other has not (the same banner style), a duelist who is typing sees a live remaining-seconds number, reveal identical on all copies with the same sounds.

**Assets:** none.

**Check:** extend `online_test.gd` (lock to the host only, `shot_status` never contains a value, reveal from the host only, a spectator's lock ignored, a non-host's reveal ignored, the log round-trip, a draw replays with a new question). One Playwright run with three tabs and `?bot=1&turns=3&group=lab`: all copies show the same question, answers and winner; reload one tab mid-question.

**Risks:** the host's copy knows both answers if the host is a duelist (it is not hidden from their own client; accepted, noted in `tech.md`).

### Part 47: Rules: two dice, zero-sum stakes, Back, powers

**Goal:** a match is about half as long; stakes never create or destroy value; Back works; the powers fit the new game.

**Builds:**
- **Two dice.** `Die` shows two dice side by side (the existing `die_1..6` images, two instances); a click on either rolls both; the roll is the sum (2 to 12), then the Wolf Man's +2 pops beside them ("+1 per die"). `Online`'s `roll` decision carries both dice (`[d1, d2]`), the auto roll picks both, and a path walk uses the sum. `docs/game_rules.md` says "two dice".
- **Turns.** `Match.TURNS_BY_LOBBY` becomes 3: 11, 4: 10, 5: 9, 6: 8, 7: 8, 8: 7 (the board lengths stay: with an average roll of 7 a player needs about 9 turns for 65 spaces). Part 51 tunes them.
- **Zero-sum stakes** (`Match.stakes`, `duel_result`):
  - Gold: both need at least 1 coin (today only the opponent is checked: a penniless challenger who lost paid nothing, which is the bug the user saw). The loser pays 1 to the winner.
  - Blood: the loser loses 1 and the winner gains 1 (`result.gain`, with a green "+1" `DeltaPop`). Available only if both players are below their blood cap (Cthulhu's cap is 4), the two Death rules hold (Death at 1 blood is neither payer nor taker), and the old death-match rule holds for both sides (a player with 1 blood can only be staked if they have 0 coins). **Blood duels will be rare, because blood sits at its cap most of the time; the church matters more. Tell the user in the summary.**
  - Frankenstein as challenger: he is exempt when he loses (nothing is paid, the winner gains nothing), so only the conditions for his winning are checked.
  - Swap: unchanged, always available.
  - `Match.stakes` returns the stakes and, for the greyed cards, the reason is not shown (as today).
- **Back.** The stake step gets a "Back" button (always, beside the cards; "Walk away" stays and shows only when swap is the only stake against every opponent). Back returns to the opponent step with the same running timer; online it is a stake decision whose value is `Challenge.BACK`, so every copy goes back together.
- **Swap duel length:** the challenger needs 2 wins before 1 loss (`Duel.roll_rounds`/`swap_wins`); Dorian still 1.
- **Powers, reviewed against two dice and the new stakes:** the Wolf Man +2 (above), Mr. Hyde (part 45), Dorian (above); Dracula, Medusa, Death, Cthulhu and Frankenstein stay (their text in `characters.md` gets the drain and two-dice wording). If a power still misbehaves while testing, change it and note it.
- **Docs:** `game_rules.md`, `characters.md`, `minigames.md` (stakes table).

**Polish:** both dice tumble with `die_roll`, land one after the other (`die_land` twice, 0.15 s apart) and the total pops big; a rolled double (the same face) gives a small extra hop of the piece; the Back button slides the cards away and back with `flip`; the drain's blood drop flies from the loser's portrait to the winner's.

**Assets:** none (the die images exist).

**Check:** a headless test over all stake cases (coins 0/1 on each side, blood at cap and below, Death at 1, Cthulhu, Frankenstein either side, death-match) asserting that coins and blood are conserved except in the Frankenstein-loses case; the dice sum range; one short bot match.

**Done (2026-10-25).** `Die` (`src/board/die.gd`) now holds two `DieCube`s (`die_cube.gd`, the old die) and forwards `offer/lock/nudge/tumble([a, b])/leave`; a click on either die rolls both, the second lands 0.15 s after the first, and the total pops above them. `Match.roll(forced: Array) -> Array[int]`; `WOLFMAN_BONUS` is 2; a double hops the piece. `Online`'s roll decision settles to `{"dice": [a, b]}` (JSON floats are cast with `int`). `Match.stakes`/`duel_result` are zero-sum with `result.gain` (blood needs both below their cap; `_blood_ok`), and the board flies the blood drop loser to winner (`Board._duel_blood`). `Challenge.BACK`: a button under the cards, a stake decision online, the candle keeps its time; when this opponent offers nothing but another does, the screen goes back by itself (not after a timeout). "Walk away" shows only when no opponent offers anything but a swap. `TURNS_BY_LOBBY` is 11/10/9/8/8/7; `Duel.SWAP_ROUNDS` is 2. Tests: `tools/tests/rules_test.tscn` (2,304 stake cases and the dice; run with `godot --headless res://tools/tests/rules_test.tscn`), `online_test.gd` updated. A scripted local run (roll, Back, pick, a blood and a gold `duel_end`) printed no errors. **Not tested:** Back over the relay in a browser, the dice look (no screenshots taken). **Changed on the way, by the user:** Shot in the Dark's clock is 30 s (was 20; part 49 keeps 30), and `SITD_COVER` in Turkish is now "ekrana sen bak, diğerleri bakmasın" (the old text said the opposite). **Tell the user:** blood duels will be rare, because blood sits at its cap most of the time.

### Part 48: Powers popup and the numeric countdown

**Goal:** clicking a monster at the top shows what it can do; every timer is a number, not a candle.

**Builds:**
- **`PowerCard`** (`src/board/power_card.gd`): clicking a HUD portrait opens a paper card beside it with the monster's name, its power in a long form (both languages; Hyde's new text), the player's name, blood and coins, and any status (stone: "misses the next turn", "Reconnecting", "Away", "Finished"). Click the portrait again, click elsewhere or press Esc to close; only one is open; it does not stop the game or block clicks on the board (the click that closes it still goes through); online timers keep running. It opens on the board only (not in monster select, which already writes the power).
- **`Countdown`** (`src/ui/countdown.gd`): replaces `Candle` everywhere (die, path choice, opponent and stake, monster select, Shot in the Dark): a paper tag with the seconds left as a number in the display font, `start(seconds)`, `stop()`, `timed_out`. It pops in like the candle, turns red and shakes at 5 s and below with `timer_low` per second, and `timer_out` at 0. Non-choosers see the same number (as the candle was for show). Delete `candle.gd`, `flame.gd`, `candle_test.gd`, `candle.png`, `flame.png` (the raws stay).
- **Docs:** `screens.md` (the HUD click, the countdown), `art_and_audio.md` where it mentions the candle.

**Polish:** the card pops in with `PaperMotion.pop_in` and a paper tab pointing at its portrait, the portrait lifts a little while its card is open, the number pulses once on each second in the last five, and the tag shrinks away on `stop`.

**Assets:** none.

**Check:** `execute_game_script` clicks a portrait and asserts one card exists with the right text, a second click closes it; a timer runs to 0 in a bot match and makes the automatic choice; no references to `Candle` remain (a grep).

**Done (2026-10-25).** `Countdown` (`src/ui/countdown.gd`, origin at the tag's middle; `start`, `stop`, `timed_out`, `time_left`, `running`; red, shake, squash and `timer_low` each second from 5 down; `timer_out` at 0) replaced `Candle` in `Board` (beside the die), `BranchChoice`, `Challenge` and `Pregame`. `candle.gd`, `candle_test.*` and `candle.png` are deleted; **`Flame` and `flame.png` stay**, because the scenery's torches use them (the plan said to delete them). Shot in the Dark keeps its own big number (`ShotGame._tick`), which already does the same things. `PowerCard` (`src/board/power_card.gd`): `Hud._toggle_card` opens it when a portrait emits the new `HudPortrait.inspected` (a click while no choice is open; the portrait's `Area2D` is always pickable now), one at a time, with the portrait lifted; its `_input` closes it on a click outside the card and its portrait (the click is not marked handled), `_unhandled_input` closes it on Esc before Settings sees it. New strings `POWER_LONG_*`, `CARD_*` in `strings.csv`. The card is a snapshot of the state when it opens. Tests: `tools/tests/card_test.tscn` (`godot --headless res://tools/tests/card_test.tscn`, 15 checks). Looked at in a plain run: the card under Medusa's portrait and the tag beside the dice. **Not tested:** the countdown on the fork, challenge and monster-select screens (only moved, not seen), the card over the relay.

### Part 49: Faster, and things getting in the way

**Goal:** a turn with no choices takes a few seconds, and nothing covers anything it should not.

**Builds:**
- **Pace.** Collect every duration in one place: a `Pace` constant class (`Pace.t(seconds)` scales by `Pace.FACTOR`, about 0.65) used by `PaperMotion`, the board's glide and hop, the camera, the pops, the banners, the curtain, the VS card, the reveal, the ceremony's beats. Targets: a turn with no choice and an empty landing at most 5 s; a duel from the landing to the first question at most 5 s; the reveal to the board at most 4 s. **Decision timers:** roll 4 s, path 7 s, opponent and stake 15 s together, monster 20 s, Shot in the Dark 30 s (the user's number, changed from 20 on 2026-10-25), away players' timers unchanged. The 12x catch-up (`Engine.time_scale`) must still work. Measure with timestamps printed from a `-- --bot --turns 3` run, before and after, and keep the numbers in the notes.
- **Overlaps.** An audit of everything that appears over the board, with one rule table in code (`Layers`: z-index and a screen slot for each): the HUD strip at the top is never covered; the notice banners (host changed, "X is back", errors, power names) go through one queue instead of stacking; `PowerPop` and `DeltaPop` on one piece stagger by 0.25 s; pieces that share a space fan out; the die and countdown never sit under the signpost or the banners; the opponent/stake cards, the Back and Walk away buttons and the HUD do not overlap at 8 players; the power card (part 48) stays on screen; full-screen controls that do nothing set `mouse_filter` to ignore so they stop eating clicks. A probe script `tools/tests/overlap_probe.gd` lists, in about ten states (die, fork, challenge at 3 and 8 players, a duel, a death, Medusa and Dracula together, a notice with a pop), the visible items whose rectangles intersect a "no-go" pair, and prints them; fix what it prints. At most six debug screenshots, none saved to the repo.
- The user gave no specifics for "things get in the way": if the user names cases later, add them to the probe.

**Polish:** nothing new; the point is that existing motion becomes snappier with its easing kept.

**Assets:** none.

**Check:** the timing numbers before and after; the probe printing nothing; one bot match.

**Risks:** faster tweens can cut a sound off or outrun a `await`; every `await tween.finished` stays, only durations change.

### Part 50: Music

**Goal:** every moment in the music list has its hook; whichever files exist play, the rest are silence.

**Builds:**
- Wire the loops and stings in the list: `challenge` while choosing an opponent and stake (replacing the old board track for those seconds), `shot` under the 20 s question (the `duel` track still plays under the VS card), the new stings through `Sound.sting(name, duck_seconds)` at the match start, the reveal, a duel win, a tie, a death and each trophy and the champion. The board track resumes with a crossfade after each. A missing file is silence (already so), and nothing waits for a sting that does not exist.
- `Sound`: loops set `loop = true` on their stream when loaded; the music ducks when settings or the power card is open (a short ramp, -8 dB); a hidden browser tab pauses the music.
- `tools/sounds/process_music.py`: turns `music_raw/` (WAV or MP3) into `assets/audio/music/*.ogg`: loudness to the same level for all, OGG at a size that keeps the web zip small (about 1.5 MB per 2-minute loop), and a check that the board tracks share a length. `music_raw/` gets a `.gdignore`. Document it in the README.
- Update `docs/assets.md` (the music table becomes the list above, with file names) and `art_and_audio.md` ("minigames have no music" is replaced by the Shot in the Dark loop).

**Polish:** crossfade lengths per transition (1.5 s between board tracks, 0.4 s into a sting), and the sting ducking so the board track does not clash.

**Assets:** the user's music files, whenever they exist. No sounds.

**Check:** headless: `Sound.play_music` with missing and present files does not error; one plain run printing the track names in order through a bot match (the board already prints "Music: ...").

### Part 51: Tuning and release 1.1.0

**Goal:** the pivot is finished, documented and built.

**Builds:**
- One full bot match (4 players, `--turns` default) locally and the 2-tab online run once to the ceremony, with a rejoin in the middle. Fix what breaks.
- Tune from the numbers: turn counts per lobby size, the timers, Hyde's 0.8, the Wolf Man's +2, how often blood duels happen (if they never happen, relax the rule by letting the winner at the cap still drain, and tell the user), the Pace factor.
- Turkish by eye: list the new strings in the notes (categories, the reveal, "Back", the power texts, "A tie!").
- Docs sweep: `game_rules.md`, `minigames.md`, `characters.md`, `screens.md`, `board.md`, `tech.md`, `roadmap.md` and the README say the same thing; remove "four games" everywhere; this file's Part notes are cut down to the code map.
- Version 1.1.0, `build_release.py --web`, the zip loads in Playwright with no console errors, and its size is noted. The Cloudflare deploy and itch.io upload stay the user's (`tools/relay/deploy.md`).
- **The process ends here:** the README says so, and the session writes no final line.

## Roadmap

45 Shot in the Dark, local. 46 Shot in the Dark, online. 47 Two dice, zero-sum stakes, Back, powers. 48 Powers popup and the countdown. 49 Faster, and the overlaps. 50 Music. 51 Tuning and the 1.1.0 release.

**Why it ends at 51:** the user asked for 6 to 8 parts. The work is seven separable pieces; 51 is a multiple of 3, so the README's rule would microplan once more after it, which it should not (51 says the process is over). The old numbering of the first release (parts 25 to 44) is closed: 25 to 44 are done.

## Part notes

Short. The next Microplan reads these instead of the code.

### The code since part 24 (kept)

- **Camera (27):** `BoardCamera.ZOOM := 0.88`. Clickable things are scaled by `1 / ZOOM`. Blemish: `scenery.gd`'s `_ground_fill` leaves faint root streaks.
- **Rules (28):** `Match.MIN_PLAYERS` 3, `TURNS_BY_LOBBY`, static `Match.turns`. `results()` gives `by.finish` 1 to the first finisher only. `Challenge` returns `{opponent, stake: Challenge.WALK}` for a walk away. A headless `-s` script can't see autoloads in `_init`; use `_process`.
- **Board (29):** `BoardRoller` rolls `kinds` per stretch; `Match.start(names, seed)` seeds `Match.board_rng` (`-- --seed N` replays); `Board._enter_tree` calls `BoardPath.configure(size, kinds)`. `BoardPath.next(id)`, `routes()`, `nearby(id)`.
- **Powers (30, 31):** `Match.roll_bonus`, `max_blood`/`min_blood`, `blood_is_safe`, `duel_result`, `Duel.swap_wins`/`roll_rounds`. `PowerPop.show_over`; `Hud.portrait_node(player)`; `DeltaPop`, `PowerBeam`. `Board._play_turns` is the turn loop: glide, die, walk, `land` or `finish`, `Match.next_player()`. `Match.drain`, `petrify`, `take_cracked()`; `BoardPiece.set_stone`, `HudPortrait.set_stone`, `set_presence`.
- **Shot in the Dark (45):** `ShotGame` (`src/minigames/shot_game.gd`, a code-built `Node2D` on a paper card in the frame's 1920 x 1080): `run()` plays one question and gives 0, 1 or `ShotGame.DRAW`; pure statics `judge(a, b, answer, hyde_side)` and `type_key(text, key)`, `value_of(text)` (tests in `tools/tests/shot_test.tscn`, run with `godot --headless res://tools/tests/shot_test.tscn`). Turns: a cover card per side (`SITD_COVER`), then 20 s of typing (keys or the keypad of `PaperButton`s), a stamp on the locked box, then `_reveal` (drumroll, answer slam, flips and count-up, off-by tags, ribbon; a click skips waits). `Questions` (`src/minigames/questions.gd`): `load_all`, `pick(group, asked, rng)`, `text(q)`, `format(v)`/`group_digits(s)` (thin space, decimal comma in Turkish); data in `data/questions.json` and `data/question_groups.json` (every fine category is listed; the checker is `tools/questions/check_questions.py`). `Match.asked` holds the ids asked. `MinigameFrame.play(challenger, opponent, stake, group)` returns `{winner, loser, rounds}`; the game and keypad live in `_front`, above the click blocker; the draw cap is `MAX_DRAWS` 3 in a row; online, each round is `Online.decide("question")` then `ShotGame.run_online` (part 46). Board kinds: letters `a r l g` = `atlas archive lab stage` (`BoardPath.KINDS`, `BoardRoller.MINIGAMES`, `Space.DUELS`); `--mini <group>` forces a landing. **The four category icons are stand-ins** (`coin` with its hue shifted; `make_outlines.py` bakes `*_rim.png`): the user's images replace them through `process_images.py . atlas archive lab stage`. Removed: the four games, `Minigame`, `Minigames`, `MiniLink`, `MinigameInput`, `CirclePhysics`, `StubGame`, the old icons, `assets/art/minigames/`, eight sounds.  Hyde's 0.8 is `ShotGame.HYDE_FACTOR`.
- **Shot in the Dark online (46):** `Online.decide("question", challenger, 0, auto)` gives the question id (every copy does `Match.asked[id] = true`); `Online.shot(sides, seconds) -> {a, b}` is called by `ShotGame.run_online` on every copy (it takes a sequence number like a decision). Messages: `shot_lock {seq, side, value}` (duelist to host; the host accepts only the seat's own peer, a number, once), `shot_status {seq, side}` (host to all, no number; `Online.shot_status` signal, `Online.shot_marked(side)`), `shot_reveal {seq, a, b}` (host only, null = no answer). Host loop `_host_shot`: ends when both lock, at `seconds + GRACE`, or 3 s (`SHOT_DROP_GRACE`) after every present duelist has locked while one is dropped or away. Log entry `{k:"s", seq, a, b}`; a rejoiner's `_replay` holds `d` and `s` entries by seq (no more `_replay_minis`). Host migration: `_on_host_changed` re-sends this copy's locked numbers (`_shot.mine`); a promoted host restarts the clock with at least `TAKEOVER_MIN`. `ShotGame` online: `_mine` says which sides this computer types for; `_fetch.call()` runs `Online.shot` without awaiting (GDScript forbids an un-awaited coroutine call, `.call()` is the way round it); `_process` drives the display clock and the auto-lock at 0; `--bot` types `answer x 0.5 to 1.5` after 3 to 8 s. `?group=` / `-- --group` replaces `mini`. Tests: `online_test.gd` (now 32 checks). Checked by three browser tabs (`?bot=1&turns=3&group=lab`): every copy printed the same winners over 5 duels, and a tab that was reloaded and clicked Rejoin replayed the logged duels with the same winners and went on live. **Fixed on the way:** `build_release.py`'s staging copy left out `data/`, so a built game had no questions (part 45 missed it). Not tested: a duelist reloading in the middle of a question (it comes back as a live shot, typing again with the clock restarted), host migration mid-question in a real browser (only the headless check), a spectator's keyboard.
- **Online I (38):** `Net` (autoload): one `WebSocketPeer`, `open_room`, `leave`, `send`, `broadcast`, signals `connected`, `refused`, `disconnected`, `peer_joined`, `peer_left`, `host_changed`, `received`. Statics `new_code`, `encode`, `decode`, `relay_url`, `room_from_link`, `link_for`, `copy_text`; `Net.id_by_name`; `Net.debug_value`. Relay is `?relay=` or `-- --relay`, default `ws://127.0.0.1:8787`. `tools/relay/` (Cloudflare Worker, SQLite Durable Object `Room`). Lobby: `lobby.tscn` (code-built), `LobbyState`; Start broadcasts `start {names, ids, seed}`. A background browser tab throttles to 130 to 600 ms, so tabs stay in front. Playwright: the game is one canvas, click by coordinates (viewport 960 x 540); `bringToFront` before typing; serve the export with `Cache-Control: no-store`.
- **Online II (39):** `Online` (autoload), lockstep: every copy runs the same `Match`; only choices come from the host through `Online.decide(kind, player, seconds, auto, valid, settle)` and `Online.submit(value)`, numbered by a counter. Kinds: `roll`, `branch`, `opponent`, `stake`, `monster`, `question` (part 46: the id of the Shot in the Dark question). `Online.is_mine`; the host adds 1 s of grace for a remote player. Debug flags: `-- --turns N` / `?turns=N`, `-- --bot` / `?bot=1`. Tests: `tools/tests/online_test.gd` (headless `Godot -s`, 27 checks).
- **Online IV (41a, 41b):** host migration (relay `{t:"host", id}`, `Online.host_id`), `Online.status(name)` `"dropped"`/`"away"` (3 automatic choices in a row; `SHORT_SECONDS` timers), `presence_changed`, Play again (`lobby_again`, `Online.back_to_room`), Leave. The decision log `Online._log`, rejoin from `sessionStorage` (`rejoin`/`rejoined`/`resume`), catch-up behind `CatchUpCurtain` at `Engine.time_scale = 12` with the Master bus muted. Not done: a rejoin during the ceremony fails.
- **Release (42, 44):** `web/shell.html`, `build_release.py --web [--debug]`, relay guards (tests in `tools/relay/`), `Net.PRODUCTION_RELAY` and `Net.PAGE_URL` (empty until the user deploys; the working tree has an uncommitted comment edit in `net.gd` that is the user's), `Net.debug_value` is empty in release builds. Version 1.0.0, 44.5 MB zip. No Windows build.

## Log

- **2026-10-23 to 24, Microplans 1 to 14:** the first playable (parts 1 to 24) and the final game's parts 25 to 44: the questionnaires, assets, camera, lobby-size rules, board per size, powers, the online spike and layer, Pong, Tug of War, Sumo and Head Soccer, the minigames over the network, drops/rejoin/host migration, the deploy and the 1.0.0 release (playtests skipped). See [microplan_first_playable.md](microplan_first_playable.md#log) for the first 24. The old per-part notes, the minigame designs and the plans for 40 to 42 were cut from this file in Microplan 15; git history has them.
- **2026-10-24, sweeping changes 2:** a list of eight fixes (Head Soccer's arena and heads, monster select showing names and a Confirm button, `DeltaPop`, `PowerBeam`, a softer rope sound). Mostly irrelevant now that the games are removed; `DeltaPop` and `PowerBeam` stay.
- **2026-10-25, Microplan 15:** the user played 1.0.0 and sent thirteen points (see "Microplan 15: the pivot"). Planned seven parts, 45 to 51, instead of three plus a rough tail, because the user asked for 6 to 8 and the changes are many but small; the README's multiple-of-3 microplan rule is switched off until 51. The roadmap now ends at 51 (the old end, 44, was the release, which is now 51). Decisions: the four minigames and the real-time online streams are removed for Shot in the Dark; two dice; Blood becomes a drain (the user agreed) so it needs both players below their cap; Swap unchanged (the user agreed); Hyde, the Wolf Man and the swap-duel length changed by Claude. The user supplied the 1000-question database (`sitd_questions/`); the plan groups its 75 categories into four board categories. Four icon prompts were added to `asset_prompts.md`; no new sounds; the music list is above. One bug found while planning: `Match.stakes` checked only the opponent's coins for a gold stake.
