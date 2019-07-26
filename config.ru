require_relative 'src/main.rb'
require 'sidekiq/web'

run Rack::URLMap.new(
  '/' => LambdaMail::App,
  '/admin/sidekiq' => Sidekiq::Web # TODO: auth
)