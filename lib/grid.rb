# frozen_string_literal: true

class Grid
  DIRECTIONS = [[0, 1], [0, -1], [1, 0], [-1, 0]].freeze

  attr_reader :width, :height, :tiles, :levels

  def initialize(width, height)
    @width = width
    @height = height
    @tiles = Array.new(height) { Array.new(width, Tile::EMPTY) }
    @levels = Array.new(height) { Array.new(width, 0) }
  end

  def tile_at(col, row)
    return nil unless in_bounds?(col, row)

    @tiles[row][col]
  end

  def place_tile?(col, row, tile_type)
    return false unless in_bounds?(col, row)

    @tiles[row][col] = tile_type
    @levels[row][col] = 0
    true
  end

  def level_at(col, row)
    return 0 unless in_bounds?(col, row)

    @levels[row][col]
  end

  def upgrade_tile?(col, row)
    return false unless in_bounds?(col, row)
    return false if @levels[row][col] >= 3

    @levels[row][col] += 1
    true
  end

  def in_bounds?(col, row)
    col >= 0 && col < @width && row >= 0 && row < @height
  end

  def road_adjacent?(col, row)
    neighbors(col, row).any? { |nx, ny| @tiles[ny][nx] == Tile::ROAD }
  end

  def neighbors(col, row)
    DIRECTIONS.filter_map do |dx, dy|
      nx = col + dx
      ny = row + dy
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

  def to_h
    { width: @width, height: @height, tiles: @tiles, levels: @levels }
  end

  def self.from_h(data)
    grid = new(data['width'], data['height'])
    grid.instance_variable_set(:@tiles, data['tiles'].map { |row| row.map(&:to_sym) })
    grid.instance_variable_set(:@levels, data['levels'])
    grid
  end
end
