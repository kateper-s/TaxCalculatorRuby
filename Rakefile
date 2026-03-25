require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/test_*.rb']
  t.verbose = true
  t.warning = false
end

task :test_file, [:file] do |t, args|
  if args[:file]
    ruby "-Ilib:test #{args[:file]}"
  else
    puts "Usage: rake test_file[test/test_personal_income_tax.rb]"
  end
end

task :test_with_coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task[:test].invoke
end

task default: :test