# frozen_string_literal: true

class CityBuilder
  attr_reader :grid, :economy, :population, :happiness, :month, :year,
              :speed, :current_tool, :stats

  def initialize(width = 60, height = 40)
    @grid = Grid.new(width, height)
    @economy = Economy.new
    @population = 0
    @happiness = 50
    @month = 1
    @year = 2024
    @speed = 1
    @paused = false
    @current_tool = :road
    @tick = 0
    @stats = { total_built: 0, total_bulldozed: 0 }
  end

  def paused?
    @paused
  end

  def select_tool?(tool)
    valid_tools = %i[road residential commercial industrial police fire hospital park bulldoze]
    return false unless valid_tools.include?(tool)

    @current_tool = tool
    true
  end

  def change_speed(speed)
    @speed = speed.clamp(0, 3)
  end

  def toggle_pause
    @paused = !@paused
  end

  def can_build?(col, row)
    return false unless @grid.in_bounds?(col, row)
    return false if @current_tool == :bulldoze && @grid.tile_at(col, row) == Tile::EMPTY

    @economy.can_afford?(@economy.cost_for(@current_tool))
  end

  def place_tile?(col, row)
    return false unless can_build?(col, row)

    if @current_tool == :bulldoze
      perform_bulldoze?(col, row)
    elsif @grid.tile_at(col, row) == Tile::EMPTY
      perform_build?(col, row)
    else
      false
    end
  end

  def simulate
    return if @paused

    advance_time
    collect_taxes
    grow_buildings
    update_happiness
  end

  def tick!
    @tick += 1
    interval = @speed.positive? ? (60 / @speed) : 600
    return unless @tick >= interval

    @tick = 0
    simulate
  end

  def screen_to_grid(start_x, start_y, camera_x, camera_y, tile_size)
    [((start_x + camera_x) / tile_size).to_i, ((start_y + camera_y) / tile_size).to_i]
  end

  private

  def perform_bulldoze?(col, row)
    was_zonable = Tile.zonable?(@grid.tile_at(col, row))
    @grid.place_tile?(col, row, Tile::EMPTY)
    @economy.spend?(@economy.cost_for(:bulldoze))
    @stats[:total_bulldozed] += 1
    recalculate_population if was_zonable
    true
  end

  def perform_build?(col, row)
    cost = @economy.cost_for(@current_tool)
    return false unless @economy.spend?(cost)

    @grid.place_tile?(col, row, @current_tool)
    @stats[:total_built] += 1
    true
  end

  def advance_time
    @month += 1
    return unless @month > 12

    @month = 1
    @year += 1
  end

  def collect_taxes
    income = 0
    @grid.developed_zones.each do |x, y|
      zone = @grid.tile_at(x, y)
      level = @grid.level_at(x, y)
      income += @economy.tax_for(zone, level)
    end
    @economy.earn(income)
    @economy.record_income(income)
  end

  def grow_buildings
    @grid.development_candidates.each do |x, y|
      @grid.upgrade_tile?(x, y) && add_population(x, y) if rand < growth_chance(x, y)
    end
  end

  def growth_chance(col, row)
    chance = 0.03
    chance += 0.02 if nearby_service?(col, row)
    chance += 0.01 if @happiness > 60
    chance -= 0.01 if @happiness < 40
    chance.clamp(0.0, 0.1)
  end

  def nearby_service?(col, row)
    @grid.neighbors(col, row).any? { |nx, ny| Tile.service?(@grid.tile_at(nx, ny)) }
  end

  def add_population(col, row)
    return unless @grid.tile_at(col, row) == Tile::RESIDENTIAL

    @population += 10 * @grid.level_at(col, row)
  end

  def recalculate_population
    @population = 0
    @grid.height.times do |y|
      @grid.width.times do |x|
        next unless @grid.tile_at(x, y) == Tile::RESIDENTIAL

        @population += 10 * @grid.level_at(x, y)
      end
    end
  end

  def update_happiness
    base = 50
    base += service_bonus
    base -= pollution_penalty
    base -= budget_penalty
    @happiness = base.clamp(0, 100)
  end

  def service_bonus
    bonus = 0
    bonus += 5 if @grid.count_type(Tile::POLICE).positive?
    bonus += 5 if @grid.count_type(Tile::FIRE).positive?
    bonus += 5 if @grid.count_type(Tile::HOSPITAL).positive?
    bonus += 3 if @grid.count_type(Tile::PARK).positive?
    bonus
  end

  def pollution_penalty
    (@grid.count_type(Tile::INDUSTRIAL) / 5).to_i
  end

  def budget_penalty
    @economy.money < 1000 ? 10 : 0
  end
end
