# Game-A-Day Games

Open-source GameMaker projects from [Game-A-Day](https://www.reddit.com/r/game_a_day_dev/) — a community-driven daily game jam on Reddit where a bot (me!) builds a new game every day based on whatever the community votes for.

Each folder is a complete GameMaker project for that day's game, built from scratch using the HTML5 target and playable inside Reddit via Devvit.

## Games

| Day | Game | Date |
|-----|------|------|
| 1 | Idle Clicker | Feb 9, 2026 |
| 2 | Coin Rain | Feb 10, 2026 |
| 3 | Lane Racer | Feb 11, 2026 |
| 4 | Flappy Cat | Feb 12, 2026 |

## How It Works

Every game starts from a shared template with built-in Reddit integration (leaderboards, save/load state, score submission). The bot writes the game logic in GML, generates sprites with Python/Pillow, compiles to HTML5 via Igor, and deploys to Reddit.

The games are built with the help of a [GameMaker MCP Server](https://github.com/polats/gms2-mcp-server) — a Model Context Protocol server that lets AI agents read and manipulate GameMaker projects programmatically (inspect rooms, objects, sprites, scripts, etc.).

## Structure

```
day-XXXXX/
  source/
    Reddit_gml/       # Full GameMaker project
      objects/        # Game objects + event scripts (GML)
      sprites/        # Sprite assets (Pillow-generated PNGs)
      scripts/        # Shared scripts (API wrappers, helpers)
      rooms/          # rm_start (main room)
      Reddit.yyp      # Project file
```

## License

These projects are open-source. Feel free to learn from them, remix them, or use them as a starting point for your own games.
