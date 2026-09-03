# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Economy do
  subject(:economy) { described_class.new(50_000) }

  describe '#initialize' do
    it 'sets starting money' do
      expect(economy.money).to eq(50_000)
    end

    it 'defaults to empty history' do
      expect(economy.income_history).to be_empty
      expect(economy.expense_history).to be_empty
    end

    it 'accepts custom starting money' do
      econ = described_class.new(10_000)
      expect(econ.money).to eq(10_000)
    end
  end

  describe '#can_afford?' do
    it 'returns true when money is sufficient' do
      expect(economy.can_afford?(50_000)).to be true
    end

    it 'returns false when money is insufficient' do
      expect(economy.can_afford?(50_001)).to be false
    end
  end

  describe '#spend?' do
    it 'deducts money when affordable' do
      economy.spend?(1_000)
      expect(economy.money).to eq(49_000)
    end

    it 'returns true on success' do
      expect(economy.spend?(100)).to be true
    end

    it 'returns false and does not deduct when unaffordable' do
      result = economy.spend?(60_000)
      expect(result).to be false
      expect(economy.money).to eq(50_000)
    end
  end

  describe '#earn' do
    it 'adds money' do
      economy.earn(5_000)
      expect(economy.money).to eq(55_000)
    end
  end

  describe '#cost_for' do
    it 'returns the cost for known tools' do
      expect(economy.cost_for(:road)).to eq(10)
      expect(economy.cost_for(:residential)).to eq(50)
      expect(economy.cost_for(:commercial)).to eq(100)
      expect(economy.cost_for(:industrial)).to eq(75)
      expect(economy.cost_for(:police)).to eq(200)
      expect(economy.cost_for(:bulldoze)).to eq(5)
    end

    it 'returns 0 for unknown tools' do
      expect(economy.cost_for(:unknown)).to eq(0)
    end
  end

  describe '#tax_for' do
    it 'calculates tax based on zone type and level' do
      expect(economy.tax_for(:residential, 1)).to eq(20)
      expect(economy.tax_for(:residential, 3)).to eq(60)
      expect(economy.tax_for(:commercial, 2)).to eq(80)
      expect(economy.tax_for(:industrial, 1)).to eq(30)
    end

    it 'returns 0 for unknown zone types' do
      expect(economy.tax_for(:road, 1)).to eq(0)
    end
  end

  describe '#record_income and #record_expense' do
    it 'records income' do
      economy.record_income(1_000)
      expect(economy.last_income).to eq(1_000)
    end

    it 'records expense' do
      economy.record_expense(500)
      expect(economy.last_expense).to eq(500)
    end

    it 'maintains independent histories' do
      economy.record_income(1_000)
      economy.record_income(2_000)
      economy.record_expense(300)
      expect(economy.income_history).to eq([1_000, 2_000])
      expect(economy.expense_history).to eq([300])
    end
  end

  describe '#last_profit' do
    it 'calculates profit as income minus expense' do
      economy.record_income(1_000)
      economy.record_expense(400)
      expect(economy.last_profit).to eq(600)
    end

    it 'is negative when expenses exceed income' do
      economy.record_income(100)
      economy.record_expense(500)
      expect(economy.last_profit).to eq(-400)
    end
  end

  describe '#last_income / #last_expense' do
    it 'returns 0 when history is empty' do
      expect(economy.last_income).to eq(0)
      expect(economy.last_expense).to eq(0)
    end
  end
end
