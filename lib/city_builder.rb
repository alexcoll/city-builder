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

  def set_tool(tool)
    valid_tools = %i[road residential commercial industrial police fire hospital park bulldoze]
    return false unless valid_tools.include?(tool)

    @current_tool = tool
    true
  end

  def set_speed(speed)
    @speed = speed.clamp(0, 3)
  end

  def toggle_pause
    @paused = !@paused
  end

  def can_build?(x, y)
    return false unless @grid.in_bounds?(x, y)
    return false if @current_tool == :bulldoze && @grid.get(x, y) == Tile::EMPTY

    @economy.can_afford?(@economy.cost_for(@current_tool))
  end

  def place(x, y)
    return false unless can_build?(x, y)

    if @current_tool == :bulldoze
      handle_bulldoze(x, y)
    elsif @grid.get(x, y) == Tile::EMPTY
      handle_build(x, y)
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

  def screen_to_grid(sx, sy, camera_x, camera_y, tile_size)
    [((sx + camera_x) / tile_size).to_i, ((sy + camera_y) / tile_size).to_i]
  end

  private

  def handle_bulldoze(x, y)
    was_zonable = Tile.zonable?(@grid.get(x, y))
    @grid.set(x, y, Tile::EMPTY)
    @economy.spend(@economy.cost_for(:bulldoze))
    @stats[:total_bulldozed] += 1
    recalculate_population if was_zonable
    true
  end

  def handle_build(x, y)
    cost = @economy.cost_for(@current_tool)
    return false unless @economy.spend(cost)

    @grid.set(x, y, @current_tool)
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
      zone = @grid.get(x, y)
      level = @grid.level_at(x, y)
      income += @economy.tax_for(zone, level)
    end
    @economy.earn(income)
    @economy.record_income(income)
  end

  def grow_buildings
    @grid.development_candidates.each do |x, y|
      @grid.upgrade(x, y) && add_population(x, y) if rand < growth_chance(x, y)
    end
  end

  def growth_chance(x, y)
    chance = 0.03
    chance += 0.02 if nearby_service?(x, y)
    chance += 0.01 if @happiness > 60
    chance -= 0.01 if @happiness < 40
    chance.clamp(0.0, 0.1)
  end

  def nearby_service?(x, y)
    @grid.neighbors(x, y).any? { |nx, ny| Tile.service?(@grid.get(nx, ny)) }
  end

  def add_population(x, y)
    return unless @grid.get(x, y) == Tile::RESIDENTIAL

    @population += 10 * @grid.level_at(x, y)
  end

  def recalculate_population
    @population = 0
    @grid.height.times do |y|
      @grid.width.times do |x|
        next unless @grid.get(x, y) == Tile::RESIDENTIAL

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
