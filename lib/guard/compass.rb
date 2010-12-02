require 'guard'
require 'guard/guard'
require 'guard/reporter'

require 'compass'
require 'compass/commands'
require 'compass/logger'

module Guard
  class Compass < Guard
    attr_reader :updater, :options
    attr_accessor :reporter
    
    VERSION = '0.0.6'
    
    autoload :Reactor, 'guard/livereload/reactor'
    attr_accessor :reactor
    
    def initialize(watchers = [], options = {})
      super
      @reporter = Reporter.new
      @options[:workdir] ||= File.expand_path(File.dirname("."))
    end
    
    # Guard Interface Implementation
    
    # Compile all the sass|scss stylesheets
    def start
      options[:api_version]    ||= '1.4'
      options[:host]           ||= '0.0.0.0'
      options[:port]           ||= '35729'
      options[:apply_js_live]  ||= true
      options[:apply_css_live] ||= true
      
      @reactor = Reactor.new(options)
      
      create_updater
      UI.info "Guard::Compass is watching at your stylesheets."
      true
    end
    
    def stop
      reactor.stop
      @updater = nil
      true
    end
    
    # Reload the configuration
    def reload
      create_updater
      true
    end
    
    # Compile all the sass|scss stylesheets
    def run_all
      perform
    end
    
    # Compile the changed stylesheets
    def run_on_change(paths)
      perform
      reactor.reload_browser(paths)
    end
    
    private
      def perform
        if valid_sass_path?
          @updater.execute
          true
        else
          false
        end
      end
      
      def create_updater
        if(options[:configuration_file])
          filepath = Pathname.new(options[:configuration_file])
          if(filepath.relative?)
            filepath = Pathname.new([options[:workdir], options[:configuration_file]].join("/"))
          end
          if(filepath.exist?)
            ::Compass.add_configuration filepath
            options[:configuration_file] = filepath
          else
            reporter.failure "Compass configuration file not found: " + filepath + "\nPlease check Guard configuration."
          end
        end
        @updater = ::Compass::Commands::UpdateProject.new(@options[:workdir] , @options)
        valid_sass_path?
      end
      
      def valid_sass_path?
        unless File.exists? ::Compass.configuration.sass_path
          reporter.failure("Sass files src directory not found: #{::Compass.configuration.sass_path}\nPlease check your Compass configuration.")
          false
        else
          true
        end
      end
  end
end