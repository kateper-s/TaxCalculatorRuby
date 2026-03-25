#!/bin/bash

echo "Running all tests..."
bundle exec rake test

echo ""
echo "Running specific test..."
bundle exec ruby -Ilib:test test/test_config.rb

echo ""
echo "Running with coverage..."
bundle exec rake test_with_coverage