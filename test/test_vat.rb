require_relative 'test_helper'

class TestVAT < Minitest::Test
  def setup
    super
    @vat = TaxCalculator::VAT.new(company_type: :llc, vat_registered: true)
  end

  def test_add_invoice
    @vat.add_invoice(
      number: "INV-001",
      date: Date.today,
      amount: 100_000,
      vat_rate: 0.20,
      counterparty: "Company LLC",
      type: :sale
    )
    
    assert_equal 1, @vat.invoices.size
    assert_equal 20_000, @vat.invoices.first[:vat_amount]
    assert_equal 120_000, @vat.invoices.first[:total_with_vat]
  end

  def test_calculate_vat_payable
    @vat.add_invoice(number: "SALE-1", amount: 100_000, vat_rate: 0.20, type: :sale)
    @vat.add_invoice(number: "SALE-2", amount: 50_000, vat_rate: 0.10, type: :sale)
    
    @vat.add_invoice(number: "PURCH-1", amount: 30_000, vat_rate: 0.20, type: :purchase)
    @vat.add_invoice(number: "PURCH-2", amount: 20_000, vat_rate: 0.10, type: :purchase)
    
    result = @vat.calculate_vat_payable
    
    assert_equal 25_000, result[:vat_outgoing]
    assert_equal 8_000, result[:vat_incoming]
    assert_equal 17_000, result[:vat_payable]
  end

  def test_vat_by_quarter
    @vat.add_invoice(number: "INV-1", date: Date.new(2024, 1, 15), amount: 100_000, vat_rate: 0.20, type: :sale)
    @vat.add_invoice(number: "INV-2", date: Date.new(2024, 2, 20), amount: 50_000, vat_rate: 0.20, type: :sale)
    @vat.add_invoice(number: "INV-3", date: Date.new(2024, 4, 10), amount: 200_000, vat_rate: 0.20, type: :sale)
    
    q1_result = @vat.calculate_vat_payable(quarter: 1)
    q2_result = @vat.calculate_vat_payable(quarter: 2)
    
    assert_equal 30_000, q1_result[:vat_outgoing]  
    assert_equal 40_000, q2_result[:vat_outgoing]  
  end

  def test_purchase_ledger
    @vat.add_invoice(number: "PURCH-1", amount: 100_000, vat_rate: 0.20, type: :purchase, counterparty: "Supplier A")
    @vat.add_invoice(number: "PURCH-2", amount: 50_000, vat_rate: 0.20, type: :purchase, counterparty: "Supplier A")
    @vat.add_invoice(number: "PURCH-3", amount: 200_000, vat_rate: 0.10, type: :purchase, counterparty: "Supplier B")
    
    ledger = @vat.purchase_ledger
    
    assert_equal 350_000, ledger[:total_purchases]  
    assert_equal 50_000, ledger[:total_vat]         
    assert_equal 2, ledger[:by_counterparty].size
    assert_equal 150_000, ledger[:by_counterparty]["Supplier A"][:total]
  end

  def test_sales_ledger
    @vat.add_invoice(number: "SALE-1", amount: 100_000, vat_rate: 0.20, type: :sale, counterparty: "Client A")
    @vat.add_invoice(number: "SALE-2", amount: 50_000, vat_rate: 0.00, type: :sale, counterparty: "Client B") 
    
    ledger = @vat.sales_ledger
    
    assert_equal 150_000, ledger[:total_sales]
    assert_equal 20_000, ledger[:total_vat]
    assert_equal 1, ledger[:export_sales].size
    assert_equal 1, ledger[:taxable_at_standard].size
  end

  def test_proportional_deduction
    @vat.add_invoice(number: "SALE-1", amount: 800_000, vat_rate: 0.20, type: :sale)
    @vat.add_invoice(number: "SALE-2", amount: 200_000, vat_rate: nil, type: :sale) 
    
    result = @vat.proportional_deduction_check
    
    assert_in_delta 0.8, result[:proportion], 0.01
    assert result[:can_deduct_full]
    assert_nil result[:adjustment_needed]
  end

  def test_generate_vat_declaration
    @vat.add_invoice(number: "SALE-1", date: Date.new(2024, 2, 15), amount: 1_000_000, vat_rate: 0.20, type: :sale)
    @vat.add_invoice(number: "PURCH-1", date: Date.new(2024, 1, 10), amount: 500_000, vat_rate: 0.20, type: :purchase)
    
    declaration = @vat.generate_vat_declaration(1)
    
    assert_equal 1, declaration[:period]
    assert_equal 200_000, declaration[:section1][:vat_at_20]  
    assert_equal 100_000, declaration[:section2][:vat_deductible]
    assert_equal 100_000, declaration[:section3][:vat_payable] 
    assert declaration[:section3][:payment_due].is_a?(Date)
  end

  def test_vat_calculation_errors
    @vat.add_invoice(
      number: nil,  
      date: Date.today,
      amount: 100_000,
      vat_rate: 0.20,
      type: :sale
    )
    
    assert @vat.invoices.first[:is_valid] == false
  end

  def test_different_vat_rates
    rates = [0.20, 0.10, 0.0, nil]
    
    rates.each do |rate|
      @vat.add_invoice(
        number: "TEST-#{rate}",
        amount: 100_000,
        vat_rate: rate,
        type: :sale
      )
    end
    
    result = @vat.calculate_vat_payable
    
    assert_equal 30_000, result[:vat_outgoing]
    assert_equal 4, result[:transactions_count]
  end
end