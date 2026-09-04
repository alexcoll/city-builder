# City Builder

A barebones Cities: Skylines-style game built with the Ruby Gosu game engine.

## Features

- Zone-based city building: residential, commercial, industrial
- Road placement and development simulation
- Services: police, fire, hospital, parks
- Economy with taxes collected from developed zones
- Population and happiness simulation
- Bulldoze tool to remove tiles
- Auto-save on exit and auto-load on startup

## Requirements

- Ruby 3.0+
- Gosu gem (installs SDL2 dependencies via Homebrew)

## Setup

Install the system libraries (macOS), then the Ruby gems:

```bash
brew bundle          # installs SDL2 libs from Brewfile
bundle install
ruby main.rb
```

`main.rb` also runs `bundle install` automatically if dependencies aren't present.

Your city is saved automatically to `~/.city_builder_save.json` when the game
exits, and that save is loaded automatically the next time you launch. To start
a brand-new city instead, pass `--new`:

```bash
ruby main.rb --new
```

## Releases / Deployment

Tagged releases are built automatically by GitHub Actions and hosted free on the
[Releases page](https://github.com/alexcoll/city-builder/releases). Each release
ships a zip containing the source plus a `run.command` launcher:

1. Download `city-builder-<version>.zip` from Releases.
2. Unzip it.
3. `chmod +x run.command` (macOS), then double-click `run.command` — or run `ruby main.rb` from a terminal.
4. First launch installs the Gosu dependency automatically.

Requires Ruby 3.0+ and the Gosu system libraries (installed via the bundled `Brewfile` on macOS).

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

## Troubleshooting

### `symbol not found in flat namespace '_OBJC_CLASS_$_NSScreen'` on macOS

If `ruby main.rb` (or any `require "gosu"`) fails with a `LoadError`, the
pre-built Gosu native extension was linked without the macOS `AppKit` and
`Foundation` frameworks (Gosu's `extconf.rb` relies on the Homebrew
`sdl2-config --static-libs` path, which returns empty for SDL2 2.32+ and never
links AppKit). Rebuild the gem's native extension from source so the required
frameworks are linked:

```bash
# 1. Locate the gem's build directory.
GEM_DIR="$(ruby -e 'print Gem::dir' 2>/dev/null || true)"
GOSU_ROOT="$(dirname "$(dirname "$(gem which gosu)")")"
cd "$GOSU_ROOT/ext/gosu"

# 2. Patch extconf.rb so SDL2 falls back to dynamic linking and AppKit/Foundation are linked.
ruby -i -pe \
  'sub!(/sdl2-config --static-libs/) { "sdl2-config --libs" }; 
   sub!(/-framework OpenGL/) { "-framework AppKit -framework Foundation -framework OpenGL" }' \
  extconf.rb

# 3. Rebuild and install the bundle in place.
make distclean
ruby extconf.rb
make
cp gosu.bundle ../lib/gosu.bundle
```

Then `require "gosu"` and `ruby main.rb` should work. This is a
build-environment fix, so it only needs to be applied to the machine running the
game — tests and lint run without the Gosu gem.

## Development

```bash
rspec      # Run tests
rubocop    # Lint
```
