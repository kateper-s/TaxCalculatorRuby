require_relative 'test_helper'

class TestIntegration < Minitest::Test
  def test_full_employee_scenario
    
    employee = TaxCalculator::PersonalIncomeTax.new(
      annual_income: 2_000_000,
      dependents: 2
    )
    
    employee.add_income(source: "Freelance", amount: 500_000, type: :contract)
   
    deductions = TaxCalculator::TaxDeductions.new
    deductions.apply(:children, count: 2)
    deductions.apply(:education, amount: 80_000, who: :self)
    deductions.apply(:medical, amount: 50_000, type: :regular)
    
    result = employee.calculate
    
    assert_equal 2_500_000, result[:total_income]
    assert result[:tax_amount] > 0
    assert result[:effective_rate] < 13.0 
  end

  def test_full_company_scenario
    company = TaxCalculator::CorporateTax.new(tax_system: :osn)
    vat = TaxCalculator::VAT.new
    
    company.add_transaction(amount: 10_000_000, type: :income)
    vat.add_invoice(amount: 10_000_000, vat_rate: 0.20, type: :sale)
    
    company.add_transaction(amount: 6_000_000, type: :expense)
    vat.add_invoice(amount: 6_000_000, vat_rate: 0.20, type: :purchase)
    
    profit_tax = company.calculate_profit_tax
    vat_result = vat.calculate_vat_payable
    
    assert_equal 800_000, profit_tax[:tax_amount]
    
    assert_equal 800_000, vat_result[:vat_payable]
    
    total_tax = profit_tax[:tax_amount] + vat_result[:vat_payable]
    assert_equal 1_600_000, total_tax
  end

  def test_tax_optimization_analysis
    income = 5_000_000
    expenses = 2_000_000
    
    osn = TaxCalculator::CorporateTax.new(tax_system: :osn)
    osn.add_transaction(amount: income, type: :income)
    osn.add_transaction(amount: expenses, type: :expense)
    osn_result = osn.calculate_profit_tax
    
    usn_income = TaxCalculator::CorporateTax.new(tax_system: :usn_income)
    usn_income.add_transaction(amount: income, type: :income)
    usn_income_result = usn_income.calculate_profit_tax
    
    usn_profit = TaxCalculator::CorporateTax.new(tax_system: :usn_income_minus_expenses)
    usn_profit.add_transaction(amount: income, type: :income)
    usn_profit.add_transaction(amount: expenses, type: :expense)
    usn_profit_result = usn_profit.calculate_profit_tax
    
    results = {
      osn: osn_result[:tax_amount],
      usn_6: usn_income_result[:tax_amount],
      usn_15: usn_profit_result[:tax_amount]
    }
    
    optimal = results.min_by { |_, tax| tax }
    
    assert optimal[0] == :usn_15
    assert_equal 450_000, optimal[1] 
  end
end