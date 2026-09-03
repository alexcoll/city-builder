# City Builder

A barebones Cities: Skylines-style game built with the Ruby Gosu game engine.

## Features

- Zone-based city building: residential, commercial, industrial
- Road placement and development simulation
- Services: police, fire, hospital, parks
- Economy with taxes collected from developed zones
- Population and happiness simulation
- Bulldoze tool to remove tiles

## Requirements

- Ruby 3.0+
- Gosu gem (installs SDL2 dependencies via Homebrew)

## Setup

```bash
bundle install
ruby main.rb
```

`main.rb` also runs `bundle install` automatically if dependencies aren't present.

## Releases / Deployment

Tagged releases are built automatically by GitHub Actions and hosted free on the
[Releases page](https://github.com/alexcoll/city-builder/releases). Each release
ships a zip containing the source plus a `run.command` launcher:

1. Download `city-builder-<version>.zip` from Releases.
2. Unzip it.
3. `chmod +x run.command` (macOS), then double-click `run.command` — or run `ruby main.rb` from a terminal.
4. First launch installs the Gosu dependency automatically.

Requires Ruby 3.0+ and the Gosu system libraries (on macOS: `brew install sdl2 sdl2_image sdl2_mixer sdl2_ttf`).

## Controls

| Key | Action |
|-----|--------|
| `1`-`9` | Select tool |
| Left click | Build / bulldoze |
| Right / middle drag | Pan camera |
| `WASD` / Arrows | Pan camera |
| `Q` | Change speed |
| `Space` | Pause |
| `Esc` | Quit |

## Development

```bash
rspec      # Run tests
rubocop    # Lint
```
