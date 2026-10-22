# Coil

A daily word game. Drag one snake through all 25 tiles of a 5×5 board. Every 5 letters along the snake must spell a word, and all five words share a theme. Your time is your score.

Files:
- `site/index.html`: the public website version, with the global leaderboard. See `SETUP.md` to put it online.
- `coil.html`: the version published on Claude. It has no global leaderboard, because Claude's sharing only lets the page's owner save shared data.
- `supabase.sql`: one-time database setup for the leaderboard.

## Rules

1. Start on the glowing tile. Move up, down, left or right. No diagonals.
2. Every 5 letters must spell a word. All five words fit today's theme.
3. Use every tile exactly once. If you box yourself in, drag back, tap an earlier tile, or press Undo.
4. Fill all 25 tiles to finish. Each hint adds 20 seconds.

Hard mode hides the start tile.

## What makes it different

- **Two skills at once.** You need the vocabulary to find words (like Wordle or Strands) and the spatial planning to avoid stranding tiles (like LinkedIn's Zip). No other daily word game combines the two.
- **One unbroken path.** Every board has a single intended route, and the generator checks that it bends inside every word so no word sits in a straight line.
- **Time-based score.** Times are easy to compare and invite a rematch ("I got 1:12, beat that").

## Built-in viral hooks

- **Same board for everyone, once a day.** It resets at local midnight and is numbered (Coil No. 1, No. 2…) so people can compare.
- **Spoiler-free share card.** One square per word, colored by how fast you found it:

  ```
  Coil No. 1 · 1:12
  🐍 Viper · 🔥4
  🟩🟨🟩🟧🟩
  ```

  🟩 15s or less · 🟨 30s or less · 🟧 a minute or less · 🟥 longer · 💡 used a hint

- **Snake ranks.** Each finish earns a rank people can brag about: Black Mamba (45s or less), Viper (90s), Python (2:30), Garter Snake (4:00), Slowworm (anything slower). Hints count against the rank.
- **Streaks and rank history.** Players see a current streak, a best streak, a best time and how often they've earned each rank.
- **A theme reveal.** The theme stays hidden until you press Start, so the first second of every game is a small surprise.
- **Practice mode.** After the daily, players can keep going on unlimited random boards.

## How the puzzles are made

- 42 hand-written themes (In the kitchen, Pirate ship, Sound effects…), each with 10–20 five-letter words.
- Every day picks one theme (all 42 are used before any repeats), takes 5 of its words, and lays them along a random winding path that covers the whole board.
- The day number seeds the generator, so every player gets the identical board with no server.
- Any path that covers every tile and spells real words counts as a solve. The dictionary has about 12,700 five-letter words.

## Global leaderboard (website version)

- Every daily finish is saved automatically under a fun generated name ("Neon Mamba 42"). Players can rename themselves.
- The results card shows "#12 of 348 · Faster than 97% of players today", and the share card adds "Top 4%" (or "#2 of 7" while fewer than 20 people have played).
- The start screen shows social proof: "348 players have finished today. Fastest: 0:38".
- A trophy button opens the full top 50 for the day.
- Ranking is time plus 20 seconds per hint. Only a player's first finish each day counts. Times under 8 seconds, closed days and rude names are rejected by the database.
- Players have no accounts. Each device keeps a private random id.
- Like Wordle, scores come from the player's browser, so a determined cheater could fake a time. Server-side solve checks would be the next hardening step if that becomes a problem.

## Next steps to go big

1. **Get your own short domain** (for example `playcoil.com`) and point it at the GitHub Pages site.
2. **Add a challenge-a-friend link** that opens a practice board with the sender's time to beat.
3. **Launch on short video.** A 10-second screen recording of the snake filling the board is very watchable. Post daily on TikTok, Reels and Shorts.
4. **Add more themes** to grow past the current 42-day theme cycle.
