require 'fileutils'
require 'json'

module LambdaMail
  module Configuration
    ##
    # The path at which configuration files are found.
    CONFIGURATION_DIR = File.expand_path('~/.local/share/lambdamail/')

    ##
    # The path to the SQLite database.
    # 
    # @return [String]
    def self.database_file
      "#{CONFIGURATION_DIR}/lambdamail.db"
    end

    ##
    # The path to the general configuration file.
    #
    # @return [String]
    def self.configuration_file
      "#{CONFIGURATION_DIR}/config.json"
    end

    ##
    # The path to the directory containing plugins.
    #
    # @return [String]
    def self.plugins_directory
      "#{CONFIGURATION_DIR}/plugins"
    end

    ##
    # Returns the contents of the main configuration file as a Hash.
    #
    # @return [Hash]
    def self.load_configuration_file
      JSON.parse(File.read(configuration_file))
    end

    ##
    # Write the contents of the main configuration file given a Hash. Returns
    # a Boolean indicating whether the write actually occured; it will not
    # occur if the Hash is not valid (according to #validate).
    #
    # @param [Hash] hash
    # @param [Boolean]
    def self.write_configuration_file(hash)
      if validate(hash).empty?
        File.write(configuration_file, hash.to_json)
        true
      else
        false
      end
    end

    ##
    # Gets the SMTP/IMAP emailer account which is configured.
    #
    # @return [SmtpEmailerAccount]
    def self.smtp_emailer_account
      acct = load_configuration_file['mailing_list']['emailer_account']
      raise unless acct['kind'] == 'smtp_imap'
      emailer = Mailing::SmtpEmailerAccount.new
      emailer.smtp_details = acct['smtp_details'].map do |k, v|
        [k.to_sym, v]
      end.to_h
      emailer.imap_details = acct['imap_details'].map do |k, v|
        [k.to_sym, v]
      end.to_h
      emailer.imap_sent_mailbox = acct['imap_sent_mailbox']
      emailer
    end

    # Ensure that the configuration dirs and files exists
    FileUtils.mkdir_p(CONFIGURATION_DIR)
    File.write(configuration_file, {
      mailing_list: {
        enable_user_signups: true,
        emailer_account: {
          kind: nil,
          smtp_details: {
            address: nil,
            port: nil,
            domain: nil,
            user_name: nil,
            password: nil,
            authentication: nil,
            enable_starttls: false,
            enable_starttls_auto: false,
            openssl_verify_mode: nil,
            ssl: false,
            tls: false,
          },
          imap_details: {
            address: nil,
            port: nil,
            user_name: nil,
            password: nil,
            enable_ssl: false,
            enable_starttls: false,
            authentication: nil
          },
          imap_sent_mailbox: nil
        }
      }
    }.to_json) unless File.exist?(configuration_file)
    FileUtils.mkdir_p(plugins_directory)
  end
end