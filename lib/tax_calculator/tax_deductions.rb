module TaxCalculator
  class TaxDeductions
    TYPES = {
      standard: {
        base: 3000, 
        children: { first: 1400, second: 1400, third: 3000 },
        disabled: 3000,
        single_parent: 2800
      },
      social: {
        education: { max: 120_000, self_max: 150_000 },
        medical: { max: 120_000, expensive: :unlimited },
        pension: { max: 120_000 },
        charity: { max: 0.25 } 
      },
      property: {
        purchase: { max: 2_000_000, refund: 260_000 },
        mortgage: { max: 3_000_000, refund: 390_000 },
        land: { max: 2_000_000 }
      },
      investment: {
        iis_type_a: { max: 400_000 },
        iis_type_b: { profit_exemption: true },
        securities: { holding_period: '3_years' }
      },
      professional: {
        authors: 0.20,
        inventors: 0.30,
        artists: 0.40
      }
    }.freeze

    def initialize(taxpayer_status: :individual)
      @taxpayer_status = taxpayer_status
      @applied_deductions = []
      @deductions_history = []
    end

    def apply_bulk(deductions)
      deductions.each do |type, params|
        apply(type, params)
      end
    end

    def apply(type, params = {})
      case type
      when :children
        apply_children_deduction(params[:count], params[:details])
      when :education
        apply_education_deduction(params[:amount], params[:who])
      when :medical
        apply_medical_deduction(params[:amount], params[:type])
      when :property
        apply_property_deduction(params[:purchase_price], params[:mortgage])
      when :investment
        apply_investment_deduction(params[:iis_type], params[:amount])
      end
    end

    def max_possible_deductions(annual_income)
      {
        standard: calculate_max_standard,
        social: calculate_max_social(annual_income),
        property: calculate_max_property,
        investment: calculate_max_investment,
        total: calculate_total_possible(annual_income)
      }
    end

    def remaining_deductions
      used = @applied_deductions.sum { |d| d[:amount] }
      
      {
        used: used,
        remaining_standard: calculate_remaining_standard,
        remaining_social: 120_000 - used_by_type(:social),
        remaining_property: 2_000_000 - used_by_type(:property),
        next_year_carryover: calculate_carryover
      }
    end

    def carryover_to_next_year
      {
        property: carryover_by_type(:property),
        investment: carryover_by_type(:investment),
        social: carryover_by_type(:social)
      }
    end

    private

    def apply_children_deduction(count, details = {})
      deduction = 0
      
      count.times do |i|
        case i
        when 0, 1 then deduction += 1400
        when 2 then deduction += 3000
        else deduction += 3000 if i >= 3
        end
      end
      
      deduction *= 2 if details[:single_parent]
      deduction *= 1.5 if details[:disabled_child]
      
      @applied_deductions << { type: :children, amount: deduction, monthly: true }
    end

    def apply_education_deduction(amount, who = :self)
      max_amount = (who == :self) ? 120_000 : 50_000
      actual_amount = [amount, max_amount].min
      
      @applied_deductions << { 
        type: :education, 
        amount: actual_amount,
        who: who,
        date: Time.now
      }
    end

    def apply_medical_deduction(amount, type = :regular)
      if type == :expensive
        @applied_deductions << { type: :medical, amount: amount, unlimited: true }
      else
        actual_amount = [amount, 120_000].min
        @applied_deductions << { type: :medical, amount: actual_amount }
      end
    end

    def apply_property_deduction(purchase_price, mortgage_interest = 0)
      property_deduction = [purchase_price, 2_000_000].min * 0.13
      mortgage_deduction = [mortgage_interest, 3_000_000].min * 0.13
      
      @applied_deductions << { 
        type: :property, 
        amount: property_deduction,
        description: "Purchase deduction"
      }
      
      if mortgage_interest > 0
        @applied_deductions << { 
          type: :property_mortgage, 
          amount: mortgage_deduction,
          description: "Mortgage interest deduction"
        }
      end
    end

    def apply_investment_deduction(iis_type, amount)
      case iis_type
      when :type_a
        actual_amount = [amount, 400_000].min * 0.13
        @applied_deductions << { type: :investment_a, amount: actual_amount }
      when :type_b
        @applied_deductions << { type: :investment_b, benefit: :tax_free_profit }
      end
    end
  end
end