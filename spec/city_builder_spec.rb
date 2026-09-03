# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CityBuilder do
  subject(:game) { described_class.new(20, 15) }

  describe '#initialize' do
    it 'creates a grid with specified dimensions' do
      expect(game.grid.width).to eq(20)
      expect(game.grid.height).to eq(15)
    end

    it 'starts with 50000 money' do
      expect(game.economy.money).to eq(50_000)
    end

    it 'starts with 0 population' do
      expect(game.population).to eq(0)
    end

    it 'starts at happiness 50' do
      expect(game.happiness).to eq(50)
    end

    it 'starts unpaused' do
      expect(game.paused?).to be false
    end

    it 'starts at speed 1' do
      expect(game.speed).to eq(1)
    end

    it 'defaults tool to road' do
      expect(game.current_tool).to eq(:road)
    end
  end

  describe '#select_tool?' do
    it 'changes the current tool' do
      game.select_tool?(:residential)
      expect(game.current_tool).to eq(:residential)
    end

    it 'returns true for valid tools' do
      expect(game.select_tool?(:commercial)).to be true
    end

    it 'returns false for invalid tools' do
      result = game.select_tool?(:invalid)
      expect(result).to be false
      expect(game.current_tool).to eq(:road)
    end
  end

  describe '#change_speed' do
    it 'changes speed within bounds' do
      game.change_speed(3)
      expect(game.speed).to eq(3)
    end

    it 'clamps to minimum 0' do
      game.change_speed(-5)
      expect(game.speed).to eq(0)
    end

    it 'clamps to maximum 3' do
      game.change_speed(10)
      expect(game.speed).to eq(3)
    end
  end

  describe '#toggle_pause' do
    it 'toggles pause on and off' do
      game.toggle_pause
      expect(game.paused?).to be true
      game.toggle_pause
      expect(game.paused?).to be false
    end
  end

  describe '#can_build?' do
    it 'returns true for valid placement in bounds' do
      expect(game.can_build?(0, 0)).to be true
    end

    it 'returns false for out of bounds' do
      expect(game.can_build?(-1, 0)).to be false
      expect(game.can_build?(20, 0)).to be false
    end

    it 'returns false when cannot afford' do
      game.select_tool?(:hospital)
      game.economy.spend?(49_900)
      expect(game.can_build?(0, 0)).to be false
    end

    it 'returns false when bulldozing empty tile' do
      game.select_tool?(:bulldoze)
      expect(game.can_build?(0, 0)).to be false
    end
  end

  describe '#place_tile?' do
    it 'places road on empty tile' do
      result = game.place_tile?(0, 0)
      expect(result).to be true
      expect(game.grid.tile_at(0, 0)).to eq(Tile::ROAD)
    end

    it 'spends money on placement' do
      game.place_tile?(0, 0)
      expect(game.economy.money).to eq(50_000 - 10)
    end

    it 'cannot place on occupied tile' do
      game.place_tile?(0, 0)
      game.select_tool?(:residential)
      result = game.place_tile?(0, 0)
      expect(result).to be false
      expect(game.grid.tile_at(0, 0)).to eq(Tile::ROAD)
    end

    it 'bulldozes existing tiles' do
      game.place_tile?(0, 0)
      game.select_tool?(:bulldoze)
      game.place_tile?(0, 0)
      expect(game.grid.tile_at(0, 0)).to eq(Tile::EMPTY)
    end

    it 'increments build stats' do
      game.place_tile?(0, 0)
      expect(game.stats[:total_built]).to eq(1)
    end

    it 'increments bulldoze stats' do
      game.place_tile?(0, 0)
      game.select_tool?(:bulldoze)
      game.place_tile?(0, 0)
      expect(game.stats[:total_bulldozed]).to eq(1)
    end
  end

  describe '#simulate' do
    it 'does nothing when paused' do
      game.toggle_pause
      game.simulate
      expect(game.month).to eq(1)
      expect(game.year).to eq(2024)
    end

    it 'advances time by one month' do
      game.simulate
      expect(game.month).to eq(2)
    end

    it 'rolls over to next year after december' do
      12.times { game.simulate }
      expect(game.month).to eq(1)
      expect(game.year).to eq(2025)
    end

    it 'collects taxes from developed zones' do
      game.place_tile?(1, 0)
      game.place_tile?(2, 0)
      game.grid.place_tile?(2, 0, Tile::RESIDENTIAL)
      game.grid.upgrade_tile?(2, 0)
      initial_money = game.economy.money
      game.simulate
      expect(game.economy.money).to be > initial_money
    end
  end

  describe '#tick!' do
    it 'increments tick counter' do
      game.change_speed(3)
      19.times { game.tick! }
      expect(game.month).to eq(1)
      game.tick!
      expect(game.month).to eq(2)
    end
  end

  describe 'building growth' do
    it 'develops zones adjacent to roads over time' do
      game.place_tile?(5, 5)
      game.select_tool?(:residential)
      game.place_tile?(6, 5)
      allow(game).to receive(:rand).and_return(0.0)
      30.times { game.simulate }
      expect(game.grid.level_at(6, 5)).to be > 0
    end

    it 'increases population when residential develops' do
      game.place_tile?(5, 5)
      game.select_tool?(:residential)
      game.place_tile?(6, 5)
      allow(game).to receive(:rand).and_return(0.0)
      30.times { game.simulate }
      expect(game.population).to be > 0
    end
  end

  describe 'happiness' do
    it 'increases with services' do
      game.place_tile?(5, 5)
      game.select_tool?(:police)
      game.place_tile?(6, 5)
      game.send(:update_happiness)
      expect(game.happiness).to be >= 50
    end

    it 'decreases with industrial pollution' do
      game.select_tool?(:industrial)
      10.times { |i| game.place_tile?(i, 0) }
      game.send(:update_happiness)
      expect(game.happiness).to be < 50
    end
  end

  describe '#screen_to_grid' do
    it 'converts screen coordinates to grid coordinates' do
      gx, gy = game.screen_to_grid(48, 24, 0, 0, 24)
      expect(gx).to eq(2)
      expect(gy).to eq(1)
    end

    it 'accounts for camera offset' do
      gx, gy = game.screen_to_grid(0, 0, 24, 24, 24)
      expect(gx).to eq(1)
      expect(gy).to eq(1)
    end
  end
end
