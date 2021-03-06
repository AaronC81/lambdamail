require 'data_mapper'

require_relative 'utilities.rb'
require_relative 'model/composed_email_message.rb'
require_relative 'model/special_email_message.rb'
require_relative 'model/recipient.rb'
require_relative 'model/pending_subscription.rb'
require_relative 'model/event.rb'
require_relative 'app/app.rb'
require_relative 'configuration.rb'
require_relative 'mailing/send_special_email_message_worker.rb'

module LambdaMail
  VERSION = '1.0.0'
end

if defined?(RSpec)
  db = 'sqlite::memory:'
  LambdaMail::Configuration.log :warn, %(
-----------------------------------------
     .         !!!!! WARNING !!!!!
    / \\      I am running with a temp
   / | \\     in-memory DB. It is VERY
  /  |  \\    unlikely this is intended
 /   .   \\   if you're not developing.
'_________'        Be careful!
-----------------------------------------
)
else
  db = "sqlite://#{LambdaMail::Configuration.database_file}"
end
DataMapper.setup(:default, db)
DataMapper.finalize
DataMapper.auto_upgrade!

# Stops SQLite locking the database constantly - >=3.7 required
DataMapper.repository.adapter.select("PRAGMA journal_mode=WAL")

LambdaMail::Configuration.log :info, "Loaded #{LambdaMail::Configuration.plugins.length} plugins"

LambdaMail::App.run! if $PROGRAM_NAME == __FILE__
