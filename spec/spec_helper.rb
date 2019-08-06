require 'capybara/rspec'
require 'sidekiq/testing'
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require_relative '../src/main'

RSpec.configure do |config|
  config.before(:each) do
    Mail::TestMailer.deliveries.clear
  end
end

Capybara.app = LambdaMail::App
Capybara.server = :webrick
