# frozen_string_literal: true

require_relative "lib/tax_calculator/version"

Gem::Specification.new do |spec|
  spec.name = "tax_calculator"
  spec.version = TaxCalculator::VERSION
  spec.authors = ["kateper-s"]
  spec.email = ["ekaponoma@sfedu.ru"]

  spec.summary = "Библиотека для расчета налогов (НДФЛ, НДС, налог на прибыль) с учетом ставок, вычетов и льгот."
  spec.description = "Позволяет рассчитывать различные налоги для физических и юридических лиц с поддержкой налоговых вычетов, " \
                     "специальных режимов (УСН, патент), страховых взносов, а также формировать налоговую отчетность."
  spec.homepage = "https://github.com/kateper-s/tax_calculator"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ spec/ .github/ .rubocop.yml .rspec])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end