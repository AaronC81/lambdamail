require 'fileutils'
require 'json'
require 'yaml'
require_relative 'plugin.rb'

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
    # The path to the password file.
    #
    # @return [String]
    def self.password_file
      "#{CONFIGURATION_DIR}/password.txt"
    end

    ##
    # Adds a new log message to #logs and prints it.
    #
    # @param [String] message
    # @param [Symbol] level One of :info, :warn, or :error.
    # @return [void]
    def self.log(level, message)
      raise "invalid log level #{level}" unless %I[info warn error].include?(level)

      @logs ||= []
      puts "[#{level.to_s.upcase}] #{message}"
      @logs << [level, message]
    end

    ##
    # Returns all messages logged with #log.
    #
    # @return [Array<String>]
    def self.logs
      @logs
    end

    ##
    # A list of plugin classes.
    #
    # @return [Array<Plugin>]
    def self.plugins
      @plugins ||= Dir["#{plugins_directory}/*"].map do |plugin|
        catch :finish do
          if File.directory?(plugin)
            info_path = File.join(plugin, 'info.yaml')
            code_path = File.join(plugin, 'main.rb')
            unless File.file?(info_path)
              log :warn, "Plugin #{plugin} is missing info.yaml. Ignoring."
              throw :finish
            end
            unless File.file?(code_path)
              log :warn, "Plugin #{plugin} is missing main.rb. Ignoring."
              throw :finish
            end

            info = YAML.safe_load(File.read(info_path))
            %w[name package description version].each do |required_key|
              if info[required_key].nil?
                log :warn, "Plugin #{plugin} is missing key #{info} in info.yaml. Ignoring."
                throw :finish
              end
            end

            plugin_instance = Plugin.new(
              path: plugin,
              name: info['name'].to_s,
              package: info['package'].to_s,
              description: info['description'].to_s,
              version: info['version'].to_s
            )
            plugin_instance_id = plugin_instance.object_id

            execution_environment = Object.new
            execution_environment.instance_variable_set(:@plugin, plugin_instance)

            begin
              execution_environment.instance_eval(File.read(code_path))
            rescue => e
              log :warn, "Plugin #{plugin} threw an exception: #{e}"
              throw :finish
            end

            if plugin_instance_id != execution_environment.instance_variable_get(:@plugin).object_id
              log :warn, "Plugin #{plugin} re-assigned @plugin. Ignoring."
              throw :finish
            end

            plugin_instance
          else
            log :warn, "Encountered a file (#{plugin}) in the plugins directory. Ignoring."
          end
        end
      end.compact
    end

    ##
    # Returns the section kind matching the given plugin package and ID.
    # Throws an exception if it can't be found.
    #
    # @return [Content::SectionKind]
    def self.find_section_kind(package, id)
      section_kinds = []
      Configuration.plugins.each do |p|
        section_kinds.push(*p.section_kinds.map { |sk| [p, sk] })
      end
      section_kind = section_kinds.find do |(p, sk)|
        sk.id == id && p.package == package
      end.last
      raise 'could not find section kind' unless section_kind
      section_kind
    end

    ##
    # Returns the template matching the given plugin package and ID.
    # Throws an exception if it can't be found.
    #
    # @return [Content::Template]
    def self.find_template(package, id)
      templates = []
      Configuration.plugins.each do |p|
        templates.push(*p.templates.map { |t| [p, t] })
      end
      template = templates.find do |(p, t)|
        t.id == id && p.package == package
      end.last
      raise 'could not find template' unless template
      template
    end

    ##
    # Returns the contents of the main configuration file as a Hash.
    # TODO: use yaml instead
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

    # Ensure that the configuration dirs and files exists
    FileUtils.mkdir_p(CONFIGURATION_DIR)
    File.write(configuration_file, {
      mailing_list: {
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