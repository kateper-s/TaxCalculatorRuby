require_relative 'test_helper'

class TestCorporateTax < Minitest::Test
  def setup
    super
    @corp = TaxCalculator::CorporateTax.new(tax_system: :osn)
  end

  def test_add_transaction
    @corp.add_transaction(
      date: Date.today,
      description: "Sale",
      amount: 100_000,
      type: :income
    )
    
    assert_equal 1, @corp.transactions.size
  end

  def test_calculate_profit_tax
    @corp.add_transaction(amount: 1_000_000, type: :income)
    @corp.add_transaction(amount: 500_000, type: :income)
    
    @corp.add_transaction(amount: 300_000, type: :expense)
    @corp.add_transaction(amount: 100_000, type: :expense)
    
    result = @corp.calculate_profit_tax
    
    assert_equal 1_500_000, result[:total_income]
    assert_equal 400_000, result[:total_expenses]
    assert_equal 1_100_000, result[:gross_profit]
    assert_equal 220_000, result[:tax_amount]
  end

  def test_import_transactions_from_csv
    csv_data = <<~CSV
      date,description,amount,type
      2024-01-01,Sale,100000,income
      2024-01-02,Expense,30000,expense
    CSV
    
    @corp.import_transactions(csv_data)
    
    assert_equal 2, @corp.transactions.size
  end

  def test_depreciation_linear
    depreciation = @corp.calculate_depreciation(
      asset_value: 1_000_000,
      useful_life: 5,
      method: :linear
    )
    
    assert_equal 200_000, depreciation[:annual]  # 1M / 5
    assert_equal 16_666.67, depreciation[:monthly]
    assert_equal 5, depreciation[:schedule].size
    assert_equal 800_000, depreciation[:schedule][0][:remaining_value]
  end

  def test_depreciation_declining_balance
    depreciation = @corp.calculate_depreciation(
      asset_value: 1_000_000,
      useful_life: 5,
      method: :declining_balance
    )
    
    assert depreciation[:annual] < 200_000 
    assert depreciation[:schedule][0][:depreciation] > depreciation[:schedule][1][:depreciation]
  end

  def test_advance_payments
    @corp.add_transaction(amount: 1_000_000, type: :income)
    
    advances = @corp.calculate_advance_payments
    
    assert_equal 4, advances.keys.select { |k| k.to_s.start_with?('q') }.size
    assert_equal 50_000, advances[:q1]  
    assert_equal 200_000, advances[:total]
  end

  def test_tax_optimization_suggestions
    @corp.add_transaction(amount: 100_000_000, type: :income) 
    
    suggestions = @corp.tax_optimization_suggestions
    
    assert suggestions.any? { |s| s[:type] == :system_change }
    assert_includes suggestions.first[:suggestion], "Consider switching"
  end

  def test_compare_tax_systems
    @corp.add_transaction(amount: 1_000_000, type: :income)
    @corp.add_transaction(amount: 600_000, type: :expense)
    
    comparison = @corp.compare_tax_systems
    
    assert_equal 5, comparison.size 
    assert comparison.key?(:osn)
    assert comparison.key?(:usn_income)
    assert comparison.key?(:usn_income_minus_expenses)
    
    assert comparison[:usn_income][:total_tax] < comparison[:osn][:tax_amount]
  end

  def test_losses_carryforward
    @corp.instance_variable_set(:@losses_previous_years, [300_000])
    
    @corp.add_transaction(amount: 500_000, type: :income)
    
    result = @corp.calculate_profit_tax
    
    assert_equal 40_000, result[:tax_amount] 
  end

  def test_quarterly_breakdown
    @corp.add_transaction(date: Date.new(2024, 1, 15), amount: 100_000, type: :income)
    @corp.add_transaction(date: Date.new(2024, 2, 20), amount: 200_000, type: :income)
    @corp.add_transaction(date: Date.new(2024, 4, 10), amount: 300_000, type: :income)
    
    result = @corp.calculate_profit_tax
    
    assert_equal 3, result[:quarterly_breakdown].size
    assert_equal 300_000, result[:quarterly_breakdown][0][:income]  
    assert_equal 300_000, result[:quarterly_breakdown][1][:income]  
  end
end