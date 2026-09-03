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
gem install gosu rspec rubocop
ruby main.rb
```

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
