require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs    << "lib"
  t.libs    << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose    = true
  t.warning    = false
end

begin
  require "simplecov"
  
  namespace :test do
    desc "Run tests with code coverage"
    task :with_coverage do
      SimpleCov.start do
        add_filter "/test/"
        add_filter "/vendor/"
        
        add_group "Personal Income Tax", "lib/tax_calculator/personal_income_tax"
        add_group "Corporate Tax", "lib/tax_calculator/CorporateTax"
        add_group "VAT", "lib/tax_calculator/Vat"
        add_group "Tax Benefits", "lib/tax_calculator/tax_benefits"
        add_group "Tax Deductions", "lib/tax_calculator/tax_deductions"
        add_group "Config", "lib/tax_calculator/config"
      end
      
      Rake::Task["test"].execute
      
      puts "\nCoverage report generated in coverage/index.html"
    end
  end
  
  task test_with_coverage: "test:with_coverage"
  
rescue LoadError
  task :test_with_coverage do
    warn "SimpleCov is not installed. Run `bundle add simplecov --group development` to enable coverage"
    Rake::Task["test"].execute
  end
end

task default: :test