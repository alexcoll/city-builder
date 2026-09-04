# frozen_string_literal: true

require 'gosu'

require_relative 'tile'
require_relative 'grid'
require_relative 'economy'
require_relative 'city_builder'

class GameWindow < Gosu::Window
  TILE_SIZE = 24
  TOOLBAR_WIDTH = 180
  STATUS_HEIGHT = 80

  TOOLS = [
    { key: :road, name: 'Road', cost: 10, hotkey: '1', color: Gosu::Color.rgb(100, 100, 100) },
    { key: :residential, name: 'Residential', cost: 50, hotkey: '2', color: Gosu::Color.rgb(45, 140, 80) },
    { key: :commercial, name: 'Commercial', cost: 100, hotkey: '3', color: Gosu::Color.rgb(50, 100, 160) },
    { key: :industrial, name: 'Industrial', cost: 75, hotkey: '4', color: Gosu::Color.rgb(190, 150, 50) },
    { key: :police, name: 'Police', cost: 200, hotkey: '5', color: Gosu::Color.rgb(30, 60, 180) },
    { key: :fire, name: 'Fire Dept', cost: 200, hotkey: '6', color: Gosu::Color.rgb(200, 40, 30) },
    { key: :hospital, name: 'Hospital', cost: 500, hotkey: '7', color: Gosu::Color.rgb(220, 220, 240) },
    { key: :park, name: 'Park', cost: 100, hotkey: '8', color: Gosu::Color.rgb(80, 180, 80) },
    { key: :bulldoze, name: 'Bulldoze', cost: 5, hotkey: '9', color: Gosu::Color.rgb(160, 60, 40) }
  ].freeze

  KEY_TO_CHAR = {
    Gosu::KB_1 => '1',
    Gosu::KB_2 => '2',
    Gosu::KB_3 => '3',
    Gosu::KB_4 => '4',
    Gosu::KB_5 => '5',
    Gosu::KB_6 => '6',
    Gosu::KB_7 => '7',
    Gosu::KB_8 => '8',
    Gosu::KB_9 => '9'
  }.freeze

  def initialize(game = nil)
    super(1280, 720)
    self.caption = 'City Builder'
    @game = game || CityBuilder.new(60, 40)
    @camera_x = 0.0
    @camera_y = 0.0
    @font = Gosu::Font.new(14)
    @font_large = Gosu::Font.new(18)
    @font_small = Gosu::Font.new(11)
    @dragging = false
    @drag_start_x = 0
    @drag_start_y = 0
    @cam_start_x = 0
    @cam_start_y = 0
  end

  def close
    @game.save_to
    super
  end

  def update
    handle_drag_pan
    handle_camera_movement
    @game.tick!
  end

  def draw
    draw_grid
    draw_toolbar
    draw_status_bar
    draw_cursor_highlight
  end

  def button_down(id)
    case id
    when Gosu::MS_LEFT
      handle_left_click
    when Gosu::MS_MIDDLE, Gosu::MS_RIGHT
      start_drag
    when Gosu::KB_ESCAPE
      close
    when Gosu::KB_SPACE
      @game.toggle_pause
    when Gosu::KB_UP, Gosu::KB_W
      # handled in update
    when Gosu::KB_Q
      @game.change_speed((@game.speed % 3) + 1)
    end

    handle_hotkey(id)
  end

  def button_up(id)
    @dragging = false if [Gosu::MS_MIDDLE, Gosu::MS_RIGHT, Gosu::MS_LEFT].include?(id)
  end

  private

  def handle_drag_pan
    return unless @dragging

    dx = @drag_start_x - mouse_x
    dy = @drag_start_y - mouse_y
    @camera_x = @cam_start_x + dx
    @camera_y = @cam_start_y + dy
  end

  def handle_camera_movement
    x_dir = horizontal_input
    y_dir = vertical_input
    @camera_x += x_dir * 6
    @camera_y += y_dir * 6
    @camera_x = @camera_x.clamp(0, (@game.grid.width * TILE_SIZE) - width + TOOLBAR_WIDTH)
    @camera_y = @camera_y.clamp(0, (@game.grid.height * TILE_SIZE) - height + STATUS_HEIGHT)
  end

  def horizontal_input
    left = button_down?(Gosu::KB_LEFT) || button_down?(Gosu::KB_A)
    right = button_down?(Gosu::KB_RIGHT) || button_down?(Gosu::KB_D)
    return -1 if left && !right
    return 1 if right && !left

    0
  end

  def vertical_input
    up = button_down?(Gosu::KB_UP) || button_down?(Gosu::KB_W)
    down = button_down?(Gosu::KB_DOWN) || button_down?(Gosu::KB_S)
    return -1 if up && !down
    return 1 if down && !up

    0
  end

  def draw_grid
    start_x = [(@camera_x / TILE_SIZE).floor, 0].max
    start_y = [(@camera_y / TILE_SIZE).floor, 0].max
    end_x = [start_x + (width / TILE_SIZE) + 2, @game.grid.width].min
    end_y = [start_y + (height / TILE_SIZE) + 2, @game.grid.height].min

    (start_y...end_y).each do |y|
      (start_x...end_x).each do |x|
        px = ((x * TILE_SIZE) - @camera_x).to_i
        py = ((y * TILE_SIZE) - @camera_y).to_i
        draw_tile(x, y, px, py)
      end
    end
  end

  def draw_tile(col, row, pixel_x, pixel_y)
    tile = @game.grid.tile_at(col, row)
    level = @game.grid.level_at(col, row)
    color = tile_color(tile, level)
    Gosu.draw_rect(pixel_x, pixel_y, TILE_SIZE - 1, TILE_SIZE - 1, color)
    draw_building_details(tile, level, pixel_x, pixel_y) if level.positive?
  end

  def tile_color(tile, level)
    case tile
    when Tile::EMPTY      then Gosu::Color.rgb(60, 100, 55)
    when Tile::ROAD       then Gosu::Color.rgb(80, 80, 80)
    when Tile::RESIDENTIAL
      brighten(Gosu::Color.rgb(30, 120, 60), level)
    when Tile::COMMERCIAL
      brighten(Gosu::Color.rgb(40, 80, 140), level)
    when Tile::INDUSTRIAL
      brighten(Gosu::Color.rgb(170, 140, 40), level)
    when Tile::POLICE     then Gosu::Color.rgb(20, 40, 160)
    when Tile::FIRE       then Gosu::Color.rgb(180, 30, 20)
    when Tile::HOSPITAL   then Gosu::Color.rgb(210, 210, 230)
    when Tile::PARK       then Gosu::Color.rgb(60, 160, 60)
    else Gosu::Color.rgb(50, 50, 50)
    end
  end

  def brighten(base_color, level)
    factor = level * 15
    Gosu::Color.rgb(
      [base_color.red + factor, 255].min,
      [base_color.green + factor, 255].min,
      [base_color.blue + factor, 255].min
    )
  end

  def draw_building_details(tile, level, pixel_x, pixel_y)
    case tile
    when Tile::RESIDENTIAL
      # Draw a little house shape
      bx = pixel_x + 4
      by = pixel_y + TILE_SIZE - 4 - (level * 4)
      Gosu.draw_rect(bx, by, TILE_SIZE - 8, level * 4, Gosu::Color.rgb(50, 80, 50))
    when Tile::COMMERCIAL
      bx = pixel_x + 3
      by = pixel_y + TILE_SIZE - 4 - (level * 5)
      Gosu.draw_rect(bx, by, TILE_SIZE - 6, level * 5, Gosu::Color.rgb(70, 120, 180))
    when Tile::INDUSTRIAL
      bx = pixel_x + 2
      by = pixel_y + TILE_SIZE - 4 - (level * 4)
      Gosu.draw_rect(bx, by, TILE_SIZE - 4, level * 4, Gosu::Color.rgb(140, 110, 30))
    end
  end

  def draw_toolbar
    Gosu.draw_rect(0, 0, TOOLBAR_WIDTH, height, Gosu::Color.rgba(20, 20, 30, 240))
    @font_large.draw_text('TOOLS', 10, 8, 0, 1, 1, Gosu::Color::WHITE)

    TOOLS.each_with_index do |tool, i|
      y = 36 + (i * 30)
      selected = @game.current_tool == tool[:key]
      bg = selected ? Gosu::Color.rgba(80, 80, 120, 200) : Gosu::Color.rgba(40, 40, 50, 200)
      Gosu.draw_rect(8, y, TOOLBAR_WIDTH - 16, 26, bg)
      Gosu.draw_rect(8, y, 4, 26, tool[:color])

      label = format('[%<key>s] %<name>s $%<cost>d', key: tool[:hotkey], name: tool[:name], cost: tool[:cost])
      @font_small.draw_text(label, 20, y + 6, 0, 1, 1, Gosu::Color::WHITE)
    end

    # Instructions
    instr_y = 36 + (TOOLS.size * 30) + 20
    @font_small.draw_text('WASD/Arrows: Pan', 10, instr_y, 0, 1, 1, Gosu::Color::GRAY)
    @font_small.draw_text('Left Click: Build', 10, instr_y + 16, 0, 1, 1, Gosu::Color::GRAY)
    @font_small.draw_text('Right Drag: Pan', 10, instr_y + 32, 0, 1, 1, Gosu::Color::GRAY)
    @font_small.draw_text('Q: Speed  Space: Pause', 10, instr_y + 48, 0, 1, 1, Gosu::Color::GRAY)
    @font_small.draw_text('Esc: Quit', 10, instr_y + 64, 0, 1, 1, Gosu::Color::GRAY)
  end

  def draw_status_bar
    y = height - STATUS_HEIGHT
    Gosu.draw_rect(0, y, width, STATUS_HEIGHT, Gosu::Color.rgba(20, 20, 30, 240))

    @font_large.draw_text("Money: $#{@game.economy.money}", 10, y + 8, 0, 1, 1, Gosu::Color::GREEN)
    @font_large.draw_text("Pop: #{@game.population}", 250, y + 8, 0, 1, 1, Gosu::Color::WHITE)
    @font_large.draw_text("Happy: #{@game.happiness}%", 420, y + 8, 0, 1, 1, Gosu::Color::YELLOW)

    time_str = "#{@game.month}/#{@game.year}"
    @font_large.draw_text(time_str, 600, y + 8, 0, 1, 1, Gosu::Color::WHITE)

    speed_str = @game.paused? ? 'PAUSED' : "Speed: #{@game.speed}x"
    @font_large.draw_text(speed_str, 750, y + 8, 0, 1, 1, Gosu::Color::WHITE)

    profit = @game.economy.last_profit
    profit_color = profit >= 0 ? Gosu::Color::GREEN : Gosu::Color::RED
    @font.draw_text("Income: $#{@game.economy.last_income}", 10, y + 36, 0, 1, 1, Gosu::Color::WHITE)
    @font.draw_text("Profit: $#{profit}", 250, y + 36, 0, 1, 1, profit_color)
    @font.draw_text("Built: #{@game.stats[:total_built]}  Demolished: #{@game.stats[:total_bulldozed]}", 420, y + 36,
                    0, 1, 1, Gosu::Color::WHITE)
  end

  def draw_cursor_highlight
    return if mouse_x < TOOLBAR_WIDTH

    gx, gy = @game.screen_to_grid(mouse_x, mouse_y, @camera_x, @camera_y, TILE_SIZE)
    return unless @game.grid.in_bounds?(gx, gy)

    px = ((gx * TILE_SIZE) - @camera_x).to_i
    py = ((gy * TILE_SIZE) - @camera_y).to_i
    can = @game.can_build?(gx, gy)
    tint = can ? Gosu::Color.rgba(255, 255, 255, 50) : Gosu::Color.rgba(255, 0, 0, 50)
    Gosu.draw_rect(px, py, TILE_SIZE - 1, TILE_SIZE - 1, tint)
  end

  def handle_left_click
    return if mouse_x < TOOLBAR_WIDTH

    gx, gy = @game.screen_to_grid(mouse_x, mouse_y, @camera_x, @camera_y, TILE_SIZE)
    @game.place_tile?(gx, gy)
  end

  def start_drag
    @dragging = true
    @drag_start_x = mouse_x
    @drag_start_y = mouse_y
    @cam_start_x = @camera_x
    @cam_start_y = @camera_y
  end

  def handle_hotkey(id)
    key_char = KEY_TO_CHAR[id]
    return unless key_char

    tool = TOOLS.find { |t| t[:hotkey] == key_char }
    @game.select_tool?(tool[:key]) if tool
  end
end
