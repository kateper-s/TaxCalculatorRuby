# test/test_tax_deductions.rb
require_relative 'test_helper'

class TestTaxDeductions < Minitest::Test
  def setup
    super
    @deductions = TaxCalculator::TaxDeductions.new
  end

  def test_children_deduction
    @deductions.apply(:children, count: 2)
    
    assert_equal 2800, @deductions.applied_deductions.first[:amount]
  end

  def test_children_deduction_with_single_parent
    @deductions.apply(:children, count: 2, details: { single_parent: true })
    
    assert_equal 5600, @deductions.applied_deductions.first[:amount]
  end

  def test_children_deduction_with_disabled_child
    @deductions.apply(:children, count: 1, details: { disabled_child: true })
    
    assert_equal 2100, @deductions.applied_deductions.first[:amount]
  end

  def test_education_deduction_self
    @deductions.apply(:education, amount: 150_000, who: :self)
    
    assert_equal 120_000, @deductions.applied_deductions.first[:amount]
  end

  def test_education_deduction_child
    @deductions.apply(:education, amount: 100_000, who: :child)
    
    assert_equal 50_000, @deductions.applied_deductions.first[:amount]
  end

  def test_medical_deduction_regular
    @deductions.apply(:medical, amount: 200_000, type: :regular)
    
    assert_equal 120_000, @deductions.applied_deductions.first[:amount]
  end

  def test_medical_deduction_expensive
    @deductions.apply(:medical, amount: 500_000, type: :expensive)
    
    assert_equal 500_000, @deductions.applied_deductions.first[:amount]
    assert @deductions.applied_deductions.first[:unlimited]
  end

  def test_property_deduction
    @deductions.apply(:property, purchase_price: 5_000_000, mortgage: 3_000_000)
    
    deductions = @deductions.applied_deductions
    assert_equal 2, deductions.size
    
    assert_equal 260_000, deductions.first[:amount]
    
    assert_equal 390_000, deductions.last[:amount]
  end

  def test_investment_deduction_iis_type_a
    @deductions.apply(:investment, iis_type: :type_a, amount: 500_000)
    
    assert_equal 52_000, @deductions.applied_deductions.first[:amount]
  end

  def test_investment_deduction_iis_type_b
    @deductions.apply(:investment, iis_type: :type_b, amount: 1_000_000)
    
    assert_equal :tax_free_profit, @deductions.applied_deductions.first[:benefit]
  end

  def test_apply_bulk_deductions
    bulk_deductions = {
      children: { count: 2 },
      education: { amount: 100_000, who: :self },
      medical: { amount: 50_000, type: :regular }
    }
    
    @deductions.apply_bulk(bulk_deductions)
    
    assert_equal 3, @deductions.applied_deductions.size
  end

  def test_max_possible_deductions
    max_deductions = @deductions.max_possible_deductions(2_000_000)
    
    assert max_deductions[:standard] > 0
    assert max_deductions[:social] > 0
    assert max_deductions[:property] > 0
    assert max_deductions[:investment] > 0
  end

  def test_remaining_deductions
    @deductions.apply(:children, count: 2) # 2800
    @deductions.apply(:education, amount: 50_000)
    
    remaining = @deductions.remaining_deductions
    
    assert_equal 52_800, remaining[:used]
    assert remaining[:remaining_standard] > 0
    assert_equal 70_000, remaining[:remaining_social] # 120_000 - 50_000
  end

  def test_carryover_to_next_year
    @deductions.apply(:property, purchase_price: 1_500_000) # Использовали 1.5M из 2M
    
    carryover = @deductions.carryover_to_next_year
    
    assert_equal 500_000, carryover[:property][:remaining]
    assert carryover[:property][:can_carryover]
  end

  def test_deductions_history
    @deductions.apply(:children, count: 1)
    @deductions.apply(:education, amount: 30_000)
    
    history = @deductions.instance_variable_get(:@deductions_history)
    assert_equal 2, history.size
    assert history.first[:date].is_a?(Time)
  end
end