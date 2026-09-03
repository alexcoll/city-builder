class Economy
  COSTS = {
    road: 10,
    residential: 50,
    commercial: 100,
    industrial: 75,
    police: 200,
    fire: 200,
    hospital: 500,
    park: 100,
    bulldoze: 5
  }.freeze

  TAX_PER_LEVEL = {
    residential: 20,
    commercial: 40,
    industrial: 30
  }.freeze

  attr_reader :money, :income_history, :expense_history, :last_income, :last_expense

  def initialize(starting_money = 50_000)
    @money = starting_money
    @income_history = []
    @expense_history = []
    @last_income = 0
    @last_expense = 0
  end

  def can_afford?(amount)
    @money >= amount
  end

  def spend(amount)
    return false unless can_afford?(amount)

    @money -= amount
    true
  end

  def earn(amount)
    @money += amount
  end

  def cost_for(tool)
    COSTS[tool] || 0
  end

  def tax_for(zone_type, level)
    (TAX_PER_LEVEL[zone_type] || 0) * level
  end

  def record_income(amount)
    @income_history << amount
    @last_income = amount
  end

  def record_expense(amount)
    @expense_history << amount
    @last_expense = amount
  end

  def last_profit
    @last_income - @last_expense
  end
end
