require 'data_mapper'

require_relative 'model/email_section_property.rb'
require_relative 'model/email_section.rb'
require_relative 'model/email_message.rb'
require_relative 'model/recipient.rb'
require_relative 'app/app.rb'
require_relative 'configuration.rb'

if defined?(RSpec)
  db = 'sqlite::memory:'
  puts %(
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

LambdaMail::App.run! if $PROGRAM_NAME == __FILE__
