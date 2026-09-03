class Grid
  DIRECTIONS = [[0, 1], [0, -1], [1, 0], [-1, 0]].freeze

  attr_reader :width, :height, :tiles, :levels

  def initialize(width, height)
    @width = width
    @height = height
    @tiles = Array.new(height) { Array.new(width, Tile::EMPTY) }
    @levels = Array.new(height) { Array.new(width, 0) }
  end

  def get(x, y)
    return nil unless in_bounds?(x, y)

    @tiles[y][x]
  end

  def set(x, y, type)
    return false unless in_bounds?(x, y)

    @tiles[y][x] = type
    @levels[y][x] = 0
    true
  end

  def level_at(x, y)
    return 0 unless in_bounds?(x, y)

    @levels[y][x]
  end

  def upgrade(x, y)
    return false unless in_bounds?(x, y)
    return false if @levels[y][x] >= 3

    @levels[y][x] += 1
    true
  end

  def in_bounds?(x, y)
    x >= 0 && x < @width && y >= 0 && y < @height
  end

  def road_adjacent?(x, y)
    neighbors(x, y).any? { |nx, ny| @tiles[ny][nx] == Tile::ROAD }
  end

  def neighbors(x, y)
    DIRECTIONS.filter_map do |dx, dy|
      nx = x + dx
      ny = y + dy
      [nx, ny] if in_bounds?(nx, ny)
    end
  end

  def count_type(type)
    @tiles.sum { |row| row.count(type) }
  end

  def developed_zones
    result = []
    @height.times do |y|
      @width.times do |x|
        result << [x, y] if Tile.zonable?(@tiles[y][x]) && @levels[y][x].positive?
      end
    end
    result
  end

  def development_candidates
    result = []
    @height.times do |y|
      @width.times do |x|
        result << [x, y] if Tile.zonable?(@tiles[y][x]) && @levels[y][x].zero? && road_adjacent?(x, y)
      end
    end
    result
  end
end
