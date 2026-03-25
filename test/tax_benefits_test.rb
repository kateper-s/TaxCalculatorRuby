require_relative "test_helper"

module TaxCalculator
  class TaxBenefitsTest < Minitest::Test

    def setup
      @benefits = TaxBenefits.new
    end

    # ── constant ──────────────────────────────────────────────────────────────

    def test_benefit_categories_frozen
      assert TaxBenefits::BENEFIT_CATEGORIES.frozen?
    end

    def test_benefit_categories_has_veterans
      assert_includes TaxBenefits::BENEFIT_CATEGORIES, :veterans
    end

    def test_benefit_categories_has_pensioners
      assert_includes TaxBenefits::BENEFIT_CATEGORIES, :pensioners
    end

    def test_veterans_monthly_exemption
      assert_equal 500, TaxBenefits::BENEFIT_CATEGORIES[:veterans][:monthly_exemption]
    end

    def test_disabled_group1_full_exemption
      assert TaxBenefits::BENEFIT_CATEGORIES[:disabled][:group1][:full_exemption]
    end

    def test_pensioners_property_tax_exemption
      assert TaxBenefits::BENEFIT_CATEGORIES[:pensioners][:property_tax_exemption]
    end

    # ── regional coefficient ──────────────────────────────────────────────────

    def test_far_east_coefficient
      b = TaxBenefits.new(region: :far_east)
      assert_in_delta 120_000, b.apply_regional_coefficient(100_000), 0.01
    end

    def test_siberia_coefficient
      b = TaxBenefits.new(region: :siberia)
      assert_in_delta 115_000, b.apply_regional_coefficient(100_000), 0.01
    end

    def test_north_coefficient
      b = TaxBenefits.new(region: :north)
      assert_in_delta 150_000, b.apply_regional_coefficient(100_000), 0.01
    end

    def test_default_region_no_adjustment
      b = TaxBenefits.new(region: :default)
      assert_in_delta 100_000, b.apply_regional_coefficient(100_000), 0.01
    end

    def test_unknown_region_no_adjustment
      b = TaxBenefits.new(region: :unknown)
      assert_in_delta 50_000, b.apply_regional_coefficient(50_000), 0.01
    end

    def test_regional_coefficient_zero_amount
      b = TaxBenefits.new(region: :north)
      assert_in_delta 0, b.apply_regional_coefficient(0), 0.01
    end

    def test_base_tax_without_benefits
      result = @benefits.calculate_tax_burden(100_000, with_benefits: false)
      assert_in_delta 13_000, result[:base_tax], 0.01
    end

    def test_effective_rate_without_benefits
      result = @benefits.calculate_tax_burden(100_000, with_benefits: false)
      assert_in_delta 13.0, result[:effective_rate], 0.01
    end

    def test_tax_burden_returns_base_tax_key
      result = @benefits.calculate_tax_burden(200_000, with_benefits: false)
      assert result.key?(:base_tax)
    end

    def test_tax_burden_returns_effective_rate_key
      result = @benefits.calculate_tax_burden(100_000, with_benefits: false)
      assert result.key?(:effective_rate)
    end

    def test_tax_burden_scales_with_income
      result1 = @benefits.calculate_tax_burden(100_000, with_benefits: false)
      result2 = @benefits.calculate_tax_burden(200_000, with_benefits: false)
      assert_in_delta result1[:base_tax] * 2, result2[:base_tax], 1
    end
  end
end
