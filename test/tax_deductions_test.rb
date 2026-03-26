require_relative "test_helper"

module TaxCalculator
  class TaxDeductionsTest < Minitest::Test

    def setup
      @d = TaxDeductions.new
    end

    def test_types_constant_is_frozen
      assert TaxDeductions::TYPES.frozen?
    end

    def test_types_has_expected_categories
      assert_includes TaxDeductions::TYPES.keys, :standard
      assert_includes TaxDeductions::TYPES.keys, :social
      assert_includes TaxDeductions::TYPES.keys, :property
      assert_includes TaxDeductions::TYPES.keys, :investment
      assert_includes TaxDeductions::TYPES.keys, :professional
    end

    def test_property_purchase_max
      assert_equal 2_000_000, TaxDeductions::TYPES[:property][:purchase][:max]
    end

    def test_social_education_self_max
      assert_equal 150_000, TaxDeductions::TYPES[:social][:education][:self_max]
    end

    def test_standard_children_first_amount
      assert_equal 1_400, TaxDeductions::TYPES[:standard][:children][:first]
    end

    def test_investment_iis_type_a_max
      assert_equal 400_000, TaxDeductions::TYPES[:investment][:iis_type_a][:max]
    end

    def test_children_one_child_stored
      @d.apply(:children, count: 1, details: {})
      deductions = @d.instance_variable_get(:@applied_deductions)
      assert_equal 1, deductions.size
    end

    def test_children_two_children_amount_is_2800
      @d.apply(:children, count: 2, details: {})
      amount = @d.instance_variable_get(:@applied_deductions).first[:amount]
      assert_equal 2_800, amount
    end

    def test_children_three_children_amount_is_5800
      @d.apply(:children, count: 3, details: {})
      # 1400 + 1400 + 3000
      amount = @d.instance_variable_get(:@applied_deductions).first[:amount]
      assert_equal 5_800, amount
    end

    def test_children_single_parent_doubles_deduction
      @d.apply(:children, count: 1, details: { single_parent: true })
      amount = @d.instance_variable_get(:@applied_deductions).first[:amount]
      assert_equal 2_800, amount
    end

    def test_children_disabled_child_multiplies_deduction
      @d.apply(:children, count: 1, details: { disabled_child: true })
      amount = @d.instance_variable_get(:@applied_deductions).first[:amount]
      assert_equal 2_100, amount  # 1400 * 1.5
    end

    def test_children_deduction_marked_as_monthly
      @d.apply(:children, count: 1, details: {})
      entry = @d.instance_variable_get(:@applied_deductions).first
      assert entry[:monthly]
    end

    def test_education_self_capped_at_120_000
      @d.apply(:education, amount: 200_000, who: :self)
      amount = @d.instance_variable_get(:@applied_deductions).first[:amount]
      assert_equal 120_000, amount
    end

    def test_education_child_capped_at_50_000
      @d.apply(:education, amount: 80_000, who: :child)
      amount = @d.instance_variable_get(:@applied_deductions).first[:amount]
      assert_equal 50_000, amount
    end

    def test_education_below_cap_uses_actual_amount
      @d.apply(:education, amount: 40_000, who: :self)
      amount = @d.instance_variable_get(:@applied_deductions).first[:amount]
      assert_equal 40_000, amount
    end

    def test_education_stores_who
      @d.apply(:education, amount: 30_000, who: :child)
      entry = @d.instance_variable_get(:@applied_deductions).first
      assert_equal :child, entry[:who]
    end

    def test_medical_regular_capped_at_120_000
      @d.apply(:medical, amount: 200_000, type: :regular)
      amount = @d.instance_variable_get(:@applied_deductions).first[:amount]
      assert_equal 120_000, amount
    end

    def test_medical_expensive_not_capped
      @d.apply(:medical, amount: 500_000, type: :expensive)
      amount = @d.instance_variable_get(:@applied_deductions).first[:amount]
      assert_equal 500_000, amount
    end

    def test_medical_expensive_marked_unlimited
      @d.apply(:medical, amount: 300_000, type: :expensive)
      entry = @d.instance_variable_get(:@applied_deductions).first
      assert entry[:unlimited]
    end

    def test_property_deduction_basic
      @d.apply(:property, purchase_price: 1_500_000, mortgage: 0)
      entry = @d.instance_variable_get(:@applied_deductions).first
      assert_in_delta 195_000, entry[:amount], 1   # 1_500_000 * 0.13
    end

    def test_property_deduction_capped_at_2_000_000
      @d.apply(:property, purchase_price: 5_000_000, mortgage: 0)
      entry = @d.instance_variable_get(:@applied_deductions).first
      assert_in_delta 260_000, entry[:amount], 1   # 2_000_000 * 0.13
    end

    def test_property_no_mortgage_creates_one_entry
      @d.apply(:property, purchase_price: 1_000_000, mortgage: 0)
      assert_equal 1, @d.instance_variable_get(:@applied_deductions).size
    end

    def test_property_with_mortgage_creates_two_entries
      @d.apply(:property, purchase_price: 1_000_000, mortgage: 500_000)
      assert_equal 2, @d.instance_variable_get(:@applied_deductions).size
    end

    def test_mortgage_deduction_correct_amount
      @d.apply(:property, purchase_price: 0, mortgage: 1_000_000)
      entries = @d.instance_variable_get(:@applied_deductions)
      mortgage_entry = entries.find { |e| e[:type] == :property_mortgage }
      assert_in_delta 130_000, mortgage_entry[:amount], 1  # 1_000_000 * 0.13
    end

    def test_mortgage_capped_at_3_000_000
      @d.apply(:property, purchase_price: 0, mortgage: 5_000_000)
      entries = @d.instance_variable_get(:@applied_deductions)
      mortgage_entry = entries.find { |e| e[:type] == :property_mortgage }
      assert_in_delta 390_000, mortgage_entry[:amount], 1  # 3_000_000 * 0.13
    end

    def test_investment_type_a_capped_at_400_000
      @d.apply(:investment, iis_type: :type_a, amount: 600_000)
      entry = @d.instance_variable_get(:@applied_deductions).first
      assert_in_delta 52_000, entry[:amount], 1   # 400_000 * 0.13
    end

    def test_investment_type_a_below_cap
      @d.apply(:investment, iis_type: :type_a, amount: 200_000)
      entry = @d.instance_variable_get(:@applied_deductions).first
      assert_in_delta 26_000, entry[:amount], 1   # 200_000 * 0.13
    end

    def test_investment_type_b_records_benefit
      @d.apply(:investment, iis_type: :type_b, amount: 1_000_000)
      entry = @d.instance_variable_get(:@applied_deductions).first
      assert_equal :tax_free_profit, entry[:benefit]
    end


    def test_apply_bulk_processes_multiple_deductions
      @d.apply_bulk(
        children:  { count: 2, details: {} },
        education: { amount: 30_000, who: :self }
      )
      deductions = @d.instance_variable_get(:@applied_deductions)
      assert_equal 2, deductions.size
    end

    def test_apply_bulk_children_amount_correct
      @d.apply_bulk(children: { count: 2, details: {} })
      amount = @d.instance_variable_get(:@applied_deductions).first[:amount]
      assert_equal 2_800, amount
    end

    def test_carryover_method_exists
      assert_respond_to @d, :carryover_to_next_year
    end
  end
end
