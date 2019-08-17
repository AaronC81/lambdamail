require_relative 'src/main.rb'
require 'sidekiq/web'

map '/' do
  run LambdaMail::App
end

map '/admin/sidekiq' do
  use Rack::Auth::Basic, 'Please enter a blank username and your LambdaMail password' do |_, password|
    File.read(LambdaMail::Configuration.password_file).chomp == Digest::SHA256.hexdigest(password)
  end

  run Sidekiq::Web
end