# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Grid do
  subject(:grid) { described_class.new(10, 8) }

  describe '#initialize' do
    it 'creates a grid with correct dimensions' do
      expect(grid.width).to eq(10)
      expect(grid.height).to eq(8)
    end

    it 'fills grid with empty tiles' do
      8.times do |y|
        10.times do |x|
          expect(grid.tile_at(x, y)).to eq(Tile::EMPTY)
        end
      end
    end

    it 'initializes all levels to zero' do
      8.times do |y|
        10.times do |x|
          expect(grid.level_at(x, y)).to eq(0)
        end
      end
    end
  end

  describe '#tile_at and #place_tile?' do
    it 'retrieves a tile at valid coordinates' do
      grid.place_tile?(3, 2, Tile::ROAD)
      expect(grid.tile_at(3, 2)).to eq(Tile::ROAD)
    end

    it 'returns nil for out of bounds coordinates' do
      expect(grid.tile_at(-1, 0)).to be_nil
      expect(grid.tile_at(10, 0)).to be_nil
      expect(grid.tile_at(0, 8)).to be_nil
    end

    it 'resets level when setting a tile' do
      grid.place_tile?(1, 1, Tile::RESIDENTIAL)
      grid.upgrade_tile?(1, 1)
      grid.upgrade_tile?(1, 1)
      expect(grid.level_at(1, 1)).to eq(2)

      grid.place_tile?(1, 1, Tile::COMMERCIAL)
      expect(grid.level_at(1, 1)).to eq(0)
    end
  end

  describe '#in_bounds?' do
    it 'returns true for coordinates within the grid' do
      expect(grid.in_bounds?(0, 0)).to be true
      expect(grid.in_bounds?(9, 7)).to be true
      expect(grid.in_bounds?(5, 4)).to be true
    end

    it 'returns false for coordinates outside the grid' do
      expect(grid.in_bounds?(-1, 0)).to be false
      expect(grid.in_bounds?(10, 0)).to be false
      expect(grid.in_bounds?(0, 8)).to be false
    end
  end

  describe '#upgrade_tile?' do
    before do
      grid.place_tile?(1, 1, Tile::RESIDENTIAL)
    end

    it 'increments level' do
      grid.upgrade_tile?(1, 1)
      expect(grid.level_at(1, 1)).to eq(1)
    end

    it 'can upgrade to level 3' do
      grid.upgrade_tile?(1, 1)
      grid.upgrade_tile?(1, 1)
      grid.upgrade_tile?(1, 1)
      expect(grid.level_at(1, 1)).to eq(3)
    end

    it 'does not exceed level 3' do
      4.times { grid.upgrade_tile?(1, 1) }
      expect(grid.level_at(1, 1)).to eq(3)
    end

    it 'returns false when already at max level' do
      3.times { grid.upgrade_tile?(1, 1) }
      expect(grid.upgrade_tile?(1, 1)).to be false
    end

    it 'returns false for out of bounds' do
      expect(grid.upgrade_tile?(-1, 0)).to be false
    end
  end

  describe '#road_adjacent?' do
    it 'returns true when a road is adjacent' do
      grid.place_tile?(2, 2, Tile::ROAD)
      expect(grid.road_adjacent?(3, 2)).to be true
    end

    it 'returns true for roads in all four directions' do
      grid.place_tile?(1, 0, Tile::ROAD)
      grid.place_tile?(3, 2, Tile::ROAD)
      grid.place_tile?(2, 1, Tile::ROAD)
      grid.place_tile?(2, 3, Tile::ROAD)
      expect(grid.road_adjacent?(2, 2)).to be true
    end

    it 'returns false when no road is adjacent' do
      grid.place_tile?(0, 0, Tile::RESIDENTIAL)
      expect(grid.road_adjacent?(5, 5)).to be false
    end

    it 'returns false at grid edges with no roads' do
      expect(grid.road_adjacent?(0, 0)).to be false
    end
  end

  describe '#neighbors' do
    it 'returns all valid neighbors' do
      neighbors = grid.neighbors(5, 4)
      expect(neighbors.size).to eq(4)
    end

    it 'returns fewer neighbors at corners' do
      neighbors = grid.neighbors(0, 0)
      expect(neighbors.size).to eq(2)
    end

    it 'excludes out of bounds neighbors' do
      neighbors = grid.neighbors(0, 0)
      coords = neighbors.map { |n| n }
      expect(coords).to include([1, 0], [0, 1])
      expect(coords).not_to include([-1, 0], [0, -1])
    end
  end

  describe '#count_type' do
    it 'counts tiles of a given type' do
      grid.place_tile?(0, 0, Tile::ROAD)
      grid.place_tile?(1, 0, Tile::ROAD)
      grid.place_tile?(2, 0, Tile::RESIDENTIAL)
      expect(grid.count_type(Tile::ROAD)).to eq(2)
      expect(grid.count_type(Tile::RESIDENTIAL)).to eq(1)
    end

    it 'returns zero when no tiles of that type exist' do
      expect(grid.count_type(Tile::POLICE)).to eq(0)
    end
  end

  describe '#development_candidates' do
    it 'returns zones adjacent to roads with level 0' do
      grid.place_tile?(2, 2, Tile::ROAD)
      grid.place_tile?(3, 2, Tile::RESIDENTIAL)
      expect(grid.development_candidates).to include([3, 2])
    end

    it 'does not include already developed zones' do
      grid.place_tile?(2, 2, Tile::ROAD)
      grid.place_tile?(3, 2, Tile::RESIDENTIAL)
      grid.upgrade_tile?(3, 2)
      expect(grid.development_candidates).not_to include([3, 2])
    end

    it 'does not include zones without road access' do
      grid.place_tile?(5, 5, Tile::RESIDENTIAL)
      expect(grid.development_candidates).not_to include([5, 5])
    end
  end

  describe '#developed_zones' do
    it 'returns zones with level > 0' do
      grid.place_tile?(1, 1, Tile::RESIDENTIAL)
      grid.upgrade_tile?(1, 1)
      expect(grid.developed_zones).to include([1, 1])
    end

    it 'does not return undeveloped zones' do
      grid.place_tile?(1, 1, Tile::RESIDENTIAL)
      expect(grid.developed_zones).not_to include([1, 1])
    end
  end
end
