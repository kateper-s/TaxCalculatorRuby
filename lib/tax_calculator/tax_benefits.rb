module TaxCalculator
  class TaxBenefits
    BENEFIT_CATEGORIES = {
      veterans: {
        monthly_exemption: 500,
        property_tax_exemption: true,
        transport_tax_discount: 0.5
      },
      disabled: {
        group1: { full_exemption: true },
        group2: { tax_discount: 0.7 },
        group3: { tax_discount: 0.5 }
      },
      pensioners: {
        property_tax_exemption: true,
        land_tax_exemption: 6_000
      },
      large_families: {
        transport_tax_exemption: true,
        land_tax_discount: 0.5
      },
      regional: {
        far_east: { coefficient: 1.2 },
        siberia: { coefficient: 1.15 },
        north: { coefficient: 1.5 }
      }
    }.freeze

    def initialize(region: :default, category: nil)
      @region = region
      @category = category
      @active_benefits = []
    end

    def check_eligibility(taxpayer_info)
      eligible_benefits = []
      
      BENEFIT_CATEGORIES.each do |category, benefits|
        if qualifies_for?(category, taxpayer_info)
          eligible_benefits << {
            category: category,
            benefits: benefits,
            potential_savings: calculate_potential_savings(benefits, taxpayer_info)
          }
        end
      end
      
      eligible_benefits
    end

    def apply_regional_coefficient(amount)
      coefficient = case @region
      when :far_east then 1.2
      when :siberia then 1.15
      when :north then 1.5
      else 1.0
      end
      
      amount * coefficient
    end

    def calculate_tax_burden(annual_income, with_benefits: true)
      base_tax = annual_income * 0.13
      
      if with_benefits && @active_benefits.any?
        reduced_tax = apply_benefits_to_tax(base_tax)
        {
          base_tax: base_tax,
          reduced_tax: reduced_tax,
          savings: base_tax - reduced_tax,
          effective_rate: (reduced_tax / annual_income.to_f * 100).round(2)
        }
      else
        {
          base_tax: base_tax,
          effective_rate: 13.0
        }
      end
    end

    private

    def qualifies_for?(category, info)
      case category
      when :veterans
        info[:veteran_status] == true
      when :disabled
        info[:disability_group].present?
      when :pensioners
        info[:age] >= 60 || info[:retired] == true
      when :large_families
        info[:children_count] >= 3
      else
        false
      end
    end
  end
end