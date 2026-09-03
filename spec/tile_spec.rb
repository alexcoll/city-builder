require 'spec_helper'

RSpec.describe Tile do
  describe '.zonable?' do
    it 'returns true for zone types' do
      expect(described_class.zonable?(Tile::RESIDENTIAL)).to be true
      expect(described_class.zonable?(Tile::COMMERCIAL)).to be true
      expect(described_class.zonable?(Tile::INDUSTRIAL)).to be true
    end

    it 'returns false for non-zone types' do
      expect(described_class.zonable?(Tile::EMPTY)).to be false
      expect(described_class.zonable?(Tile::ROAD)).to be false
      expect(described_class.zonable?(Tile::POLICE)).to be false
    end
  end

  describe '.service?' do
    it 'returns true for service types' do
      expect(described_class.service?(Tile::POLICE)).to be true
      expect(described_class.service?(Tile::FIRE)).to be true
      expect(described_class.service?(Tile::HOSPITAL)).to be true
      expect(described_class.service?(Tile::PARK)).to be true
    end

    it 'returns false for non-service types' do
      expect(described_class.service?(Tile::RESIDENTIAL)).to be false
      expect(described_class.service?(Tile::ROAD)).to be false
    end
  end
end
