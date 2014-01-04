require 'PBManager/t_sub'
require 'erb'

module PBManager
  class IsoBuilder

    attr_reader :settings

    def initialize

      @app_config = PBManager::AppConfig.instance

      @base_dir = @app_config.base_dir
      @build_dir = @app_config.build_dir
      @cache_dir = @app_config.cache_dir
      @ksiso_dir = @app_config.ksiso_dir

      @iso_glob = 'UNKNOWN-*'


      # hard code till refactor

      @settings = {}
      @settings[:vmos] = @app_config.settings[:vmos]

      pe_install_suffix = @app_config.settings[@settings[:vmos]][:pe_install_suffix]

      # needed in ks.cfg.erb!
      @settings[:pe_version] = @app_config.settings[:pe_version]
      @settings[:pe_install_suffix] = pe_install_suffix


      # two variables appear to be configured via :vmtype in settings :hostname and :pe_tarball

      # TODO :vmtype is a KEY.
      # how can i use it to unify it,

      if @app_config.settings[:vmtype] == :training
        @settings[:hostname] = "#{@settings[:vmtype]}.puppetlabs.vm"
      else
        @settings[:hostname] = "learn.localdomain"
      end

      @settings[:pe_tarball] = "puppet-enterprise-#{@app_config.settings[:pe_version]}#{pe_install_suffix}.tar.gz"

      @settings[:iso_glob] = @app_config.settings[@settings[:vmos]][:iso_glob]
      @settings[:iso_url] = @app_config.settings[@settings[:vmos]][:iso_url]


      # Extract the OS version from the iso filename as debian and Centos are the                                                                    f
      # same basic format and get caught by the match group below
      iso_version = @settings[:iso_url][/^.*-(\d+\.\d\.?\d?)-.*\.iso$/, 1]

      if @app_config.settings[:vmtype] == :training
        @settings[:vmname] = "#{@settings[:vmos]}-#{iso_version}-pe-#{@settings[:pe_version]}".downcase
      else
        @settings[:vmname] = "learn_puppet_#{@settings[:vmos]}-#{iso_version}-pe-#{@settings[:pe_version]}".downcase
      end

      PBManager::log.info "iso_mgr::settings #{@settings}"

    end

    # common activities to all os's
    def create_iso
      begin

        @app_config.settings[@settings[:vmos]][:build_files].each do |bf|
          build_file(bf)
        end

        # TODO  DRY ALERT!!!!

        # clone the git repositories
        @app_config.settings[:common][:git_clone].each do |df|
          PBManager::log.info("git clone: #{df[:src]} => #{df[:dest]}, #{df[:branch]}")
          t = PBManager::TSub.new(df[:dest])
          t.set(':', {'CACHE_DIR' => @app_config.cache_dir})
          x = t.run
          PBManager::gitclone df[:src], x, df[:branch]
        end

        # download the various rpm and tarballs
        @app_config.settings[@settings[:vmos]][:download_files].each do |df|
          PBManager::log.info("Downloading: #{df[:src]} => #{df[:dest]}")
          t = PBManager::TSub.new(df[:dest])
          t.set(':', {'CACHE_DIR' => @app_config.cache_dir})
          x = t.run
          PBManager::download df[:src], x
        end

        download_distro

      rescue PBManager::FatalError => e
        e.process
        abort
      rescue => e
        puts "#{e.class} => #{e.message}"
        PBManager::log.fatal("#{e.class} => #{e.message}")
        PBManager::log.fatal("Backtrace:\n\t#{e.backtrace.join("\n\t")}")
      end
    end

    def iso_exists?
      return File.exist?("#{@ksiso_dir}/#{@settings[:vmos]}.iso")
    end


    # create the build_root directory structure iff required
    #
    def create_build_root

      begin

        PBManager::log.info "> create_build_root()"

        # create first level directories iff they do not exist
        [@build_dir, @ksiso_dir, @cache_dir].each do |dir|
          unless File.directory?(dir)
            PBManager::log.debug("Making #{dir} for all kickstart data")
            FileUtils.mkdir_p(dir)
          end
        end

        # this gets puppet enterprise
        pe_tarball = @settings[:pe_tarball]
        pe_release_url = "#{@app_config.settings[:pe_release_url]}/#{@app_config.settings[:pe_version]}"
        pe_installed = "#{@cache_dir}/#{pe_tarball}"

        unless File.exist?(pe_installed)
          PBManager::download "#{pe_release_url}/#{pe_tarball}", pe_installed
        end

        unless File.exist?("#{pe_installed}.asc")
          PBManager::download "#{pe_release_url}/#{pe_tarball}.asc", "#{@cache_dir}/#{pe_tarball}.asc"
        end

        PBManager::log.unknown "Verifying signature"
        system("gpg --verify --always-trust #{pe_installed}.asc #{pe_installed}")
        puts $?

        PBManager::log.info "< create_build_root()"

      rescue PBManager::FatalError => e
        e.process
        abort
      rescue => e
        puts "#{e.class} => #{e.message}"
        PBManager::log.fatal("#{e.class} => #{e.message}")
        PBManager::log.fatal("Backtrace:\n\t#{e.backtrace.join("\n\t")}")
      end

    end

    # clean it up
    def remove_build_root
      if File.directory?(@sites_dir)
        puts "not yet implemented"
      end
    end


    def vm_name
      @settings[:vmname]
    end

    private

    # download clean distro ISO
    def download_distro

      iso_default = Dir.glob("#{@cache_dir}/#{@settings[:iso_glob]}").first

      if !iso_default
        iso_default = @settings[:iso_glob]
      end

      dest_iso = "#{@ksiso_dir}/#{@settings[:vmos]}.iso"

      if !File.exist?(dest_iso)
        puts "Please specify #{@settings[:vmos]} ISO path or url [#{iso_default}]: "
        iso_uri = STDIN.gets.chomp.rstrip
        iso_uri = iso_default if iso_uri.empty?

        #if iso_uri != iso_file
        case iso_uri
          when /^(http|https):\/\//
            iso_file = File.basename(iso_uri)
            PBManager::log.info("Downloading ISO to #{@cache_dir}/#{iso_file}...")
            download iso_uri, "#{cache_dir}/#{iso_file}"
          else
            PBManager::log.info("Copying ISO to #{@cache_dir}...")
            FileUtils.cp iso_uri, @cache_dir
        end
        iso_file = Dir.glob("#{@cache_dir}/#{@settings[:iso_glob]}").first
        #end


        PBManager::log.info("Mapping files from #{@build_dir} into ISO (#{dest_iso}...")
        map_iso(iso_file, dest_iso)
      else
        PBManager::log.info("Image #{@ksiso_dir}/#{@settings[:vmos]}.iso is already created; skipping")
      end

    end

    # creates files from ERB templates
    def build_file(filename)

      # this is a legacy from the original. It has to be capitalized to do the building
      distro_name = @settings[:vmos]

      template_path = "#{@base_dir}/files/#{distro_name.capitalize}/#{filename}.erb"
      target_dir = "#{@build_dir}/#{@settings[:vmos]}"
      target_path = "#{target_dir}/#{filename}"


      FileUtils.mkdir(target_dir) unless File.directory?(target_dir)

      if File.file?(template_path)
        begin
          PBManager::log.debug "Building #{target_path} from #{template_path}"
          File.open(target_path, 'w') do |f|
            template_content = ERB.new(File.read(template_path)).result(binding)
            f.write(template_content)
          end
        rescue Exception => e
          raise PBManager::FatalError.new("Error processing template: #{template_path}", e)
        end

      else
        raise PBManager::FatalError.new("No source template found: #{template_path}")
      end

    end

    # this builds the new iso
    def map_iso(indev, outdev)

      #puts indev
      #puts outdev

      maps = ''
      @app_config.settings[@settings[:vmos]][:iso_files].each do |df|
        puts df
        t = PBManager::TSub.new(df[:src])
        t.set(':', {'CACHE_DIR' => @app_config.cache_dir, 'BUILD_DIR' => @app_config.build_dir})
        frompath = t.run
        maps += " -map '#{frompath}' '#{df[:dest]}'"
      end

      puts maps

      system("xorriso -osirrox on -boot_image any patch -indev #{indev} -outdev #{outdev} #{maps}")
    end



  end
end