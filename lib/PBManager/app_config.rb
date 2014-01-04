require 'singleton'
require 'logger'
require 'pathname'
require 'yaml'
require 'pp'

module PBManager

  # this sets application wide configuration details
  class AppConfig

    # the dreaded singleton pattern, there is probably something better by now
    include Singleton

    # get the current debug level (setter is below)
    attr_reader :debug

    # get the logger methods
    attr_reader :log

    # location of the code root
    # TODO this will change as we move to gem deployment.
    attr_reader :base_dir

    # location where the "build_root"
    attr_reader :sites_dir

    # relative locations from build_root
    attr_reader :build_dir
    attr_reader :cache_dir

    # relative locations for base_dir
    attr_reader :ksiso_dir
    attr_reader :vagrant_dir
    attr_reader :ovf_dir
    attr_reader :vmware_dir
    attr_reader :vbox_dir
    attr_reader :config_dir

    # the vm of the OS to build, kept though I am only interested in Redhat family
    # perhaps someone can help me keep this valid for other distos
    attr_reader :vmos
    attr_reader :vmtype

    # this is a catch-all, break out as required
    attr_reader :settings

    # Constructor creates all the directories and
    # sets up important shared constants
    # TODO: evaluate importance of contants next version
    #
    def initialize

      unless ENV['PBMANAGER_ROOT'].nil?
        @base_dir = Pathname.new(ENV['PBMANAGER_ROOT'])
        if !@base_dir.directory?
          abort("PBMANAGER_ROOT is not directory")
        end
        @base_dir = @base_dir.realpath.to_s
      else
        abort("Could not find PBMANAGER_ROOT")
        return
      end


      # our "build_root" sits off our home directory,
      # TODO make this home or tmp or "where told"
      @sites_dir = ENV['HOME'] + "/Sites"


      @build_dir = "#{@sites_dir}/build"
      @cache_dir = "#{@sites_dir}/cache"

      # TODO Evaluate moving these to where they need to be realized.
      @ksiso_dir = "#{@build_dir}/isos"
      @vagrant_dir = "#{@build_dir}/vagrant"
      @ovf_dir = "#{@build_dir}/ovf"
      @vmware_dir = "#{@build_dir}/vmware"
      @vbox_dir = "#{@build_dir}/vbox"


      # TODO when ready to gemize the location this will be "~/.pbs/config"

      # if the directory exists then use it, otherwise create it, then
      #   stop and alert the user.

      # TEMPORARY
      @config_dir = "#{@base_dir}/config"
      unless  File.directory?(@config_dir)
        abort("Could not find PBMANAGER_ROOT/config?")
        return
      end

      # TODO when ready to gemize location this will be "~/.pbs/log"
      the_log_dir = "#{@base_dir}/log"
      unless File.directory?(the_log_dir)
        # puts "Making #{the_log_dir} for logging"
        FileUtils.mkdir_p(the_log_dir)
      end

      the_log_file = "#{the_log_dir}/log.txt"
      begin
        @log = Logger.new(the_log_file)
        @log.level = Logger::DEBUG
      rescue => e
        raise PBManager::FatalError.new("Could not find #{the_log_file}", e)
        return
      end

      @settings = YAML.load_file("#{@config_dir}/application.yml")

      # TODO temp hardcode, this will be in "~/.pbs/config" directory
      @vmos = @settings[:vmos]
      @vmtype = @settings[:vmtype]


      @log.unknown("PBManager was initialized")
      @log.debug "@settings = \n#{@settings.to_yaml}"
      @log.info "@vmos = #{@vmos}"
      @log.info "@vmtype = #{@vmtype}"
    end

    # set logging level
    def set_debug(d)

      # do I really need a boolean flag????
      @debug = (debug != 0)

      if d == 1
        @log.level = Logger::WARN
      elsif d == 2
        @log.level = Logger::INFO
      elsif d > 2
        @log.level = Logger::DEBUG
      end
    end


    def print_locations
      puts @base_dir
      pp @settings
    end

  end
end
