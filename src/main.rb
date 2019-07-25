require 'data_mapper'

require_relative 'utilities.rb'
require_relative 'model/email_section_property.rb'
require_relative 'model/email_section.rb'
require_relative 'model/email_message.rb'
require_relative 'model/recipient.rb'
require_relative 'model/pending_subscription.rb'
require_relative 'app/app.rb'
require_relative 'configuration.rb'
require_relative 'mailing.rb'

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

config = LambdaMail::Utilities.deep_keys_to_sym(LambdaMail::Configuration.load_configuration_file)

LambdaMail::Mailing.smtp_details = config[:mailing_list][:emailer_account][:smtp_details]
LambdaMail::Mailing.imap_details = config[:mailing_list][:emailer_account][:imap_details]
LambdaMail::Mailing.imap_sent_mailbox = config[:mailing_list][:emailer_account][:imap_sent_mailbox]

LambdaMail::App.run! if $PROGRAM_NAME == __FILE__
