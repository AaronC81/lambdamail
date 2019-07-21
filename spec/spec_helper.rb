require 'capybara/rspec'

require_relative '../src/main'

Capybara.app = LambdaMail::App
Capybara.server = :webrick
