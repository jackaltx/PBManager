module PBManager
  class VagrantMgr

    def initialize(vmname)

      @vmname = vmname

      @app_config = PBManager::AppConfig.instance

    end


    def create_vm
      begin

        destroy_vm

        dir = "#{@app_config.build_dir}/vagrant"
        unless File.directory?(dir)
          FileUtils.mkdir_p(dir)
        end


        case @app_config.settings[:vmos]
          when /(centos|redhat)/
            ostype = 'RedHat'
        end

        PBManager::log.info "Creating VM '#{@vmname}' in #{dir} ..."
        system("VBoxManage createvm --name '#{@vmname}' --basefolder '#{dir}' --register --ostype #{ostype}")
        Dir.chdir("#{dir}/#{@vmname}")
        PBManager::log.info "Configuring VM settings..."
        system("VBoxManage modifyvm '#{@vmname}' --memory 2048 --nic1 nat --usb off --audio none")
        system("VBoxManage storagectl '#{@vmname}' --name 'IDE Controller' --add ide")
        system("VBoxManage createhd --filename 'box-disk1.vmdk' --size 8192 --format VMDK")
        system("VBoxManage storageattach '#{@vmname}' --storagectl 'IDE Controller' --port 0 --device 0 --type hdd --medium 'box-disk1.vmdk'")
        system("VBoxManage storageattach '#{@vmname}' --storagectl 'IDE Controller' --port 1 --device 0 --type dvddrive --medium emptydrive")
      ensure
        Dir.chdir(@app_config.base_dir)
      end

    end

    def destroy_vm

      if %x{VBoxManage list vms}.match /("#{@vmname}")/
        PBManager::log.info "Destroying VM #{@vmname}..."
        system("VBoxManage unregistervm '#{@vmname}' --delete")
      end

    end

    def mountiso
      PBManager::log.info "Mounting #{@vmos} on #{@vmname}"
      system("VBoxManage storageattach '#{@vmname}' --storagectl 'IDE Controller' --port 1 --device 0 --type dvddrive --medium '#{@app_config.ksiso_dir}/#{@app_config.settings[:vmos]}.iso'")
    end

    def unmountiso

      sleeptotal = 0
      while %x{VBoxManage list runningvms}.match /("#{@vmname}")/
        PBManager::log.info "Waiting for #{@vmname} to shut down before unmounting..." if sleeptotal >= 90
        sleep 5
        sleeptotal += 5
      end
      PBManager::log.info "Unmounting #{@vmos} on #{@vmname}"
      system("VBoxManage storageattach '#{@vmname}' --storagectl 'IDE Controller' --port 1 --device 0 --type dvddrive --medium none")
    end

    def stopvm
      if %x{VBoxManage list runningvms}.match /("#{@vmname}")/
        PBManager::log.info "Stopping #{@vmname}"
        system("VBoxManage controlvm '#{@vmname}' poweroff")
      end
    end

    def createovf

      unmountiso

      PBManager::log.info "Converting Original .vbox to OVF..."
      FileUtils.rm_rf("#{@app_config.ovf_dir}/#{@vmname}-ovf") if File.directory?("#{@app_config.ovf_dir}/#{@vmname}-ovf")
      FileUtils.mkdir_p("#{@app_config.ovf_dir}/#{@vmname}-ovf")
      system("VBoxManage export '#{@vmname}' -o '#{@app_config.ovf_dir}/#{@vmname}-ovf/#{@vmname}.ovf'")
    end

    def createvmx

      unmountiso

      PBManager::log.info "Converting OVF to VMX..."
      FileUtils.rm_rf("#{@app_config.vmware_dir}/#{@vmname}-vmware") if File.directory?("#{@app_config.vmware_dir}/#{@vmname}-vmware")
      FileUtils.mkdir_p("#{@app_config.vmware_dir}/#{@vmname}-vmware")
      system("'#{@app_config.settings[:ovftool]}' --lax --compress=9 --targetType=VMX '#{@app_config.ovf_dir}/#{@vmname}-ovf/#{@vmname}.ovf' '#{@app_config.vmware_dir}/#{@vmname}-vmware'")

      PBManager::log.info 'Changing virtualhw.version = "9" to "8"'
      # JKL bug fix on next line
      vmxpath = "#{@app_config.vmware_dir}/#{@vmname}-vmware/#{@vmname}/#{@vmname}.vmx"
      content = File.read(vmxpath)
      content = content.gsub(/^virtualhw\.version = "9"$/, 'virtualhw.version = "8"')
      File.open(vmxpath, 'w') { |f| f.puts content }
    end

    def createvbox

      PBManager::log.info "Making copy of VM for VBOX..."
      FileUtils.rm_rf("#{@app_config.vbox_dir}/#{@vmname}-vbox") if File.directory?("#{@app_config.vbox_dir}/#{@vmname}-vbox")
      FileUtils.mkdir_p("#{@app_config.vbox_dir}/#{@vmname}-vbox")
      system("rsync -a '#{@app_config.vagrant_dir}/#{@vmname}/' '#{@app_config.vbox_dir}/#{@vmname}-vbox'")
    end

    def vagrantize

      PBManager::log.info "Vagrantizing VM..."
      system("vagrant package --base '#{@vmname}' --output '#{@app_config.vagrant_dir}/#{@vmname}.box'")
      FileUtils.ln_sf("#{@app_config.vagrant_dir}/#{@vmname}.box", "#{@app_config.vagrant_dir}/#{@app_config.settings[:vmos].downcase}-latest.box")
    end

    def packagevm

      system("zip -rj '#{@app_config.cache_dir}/#{@vmname}-ovf.zip' '#{@app_config.ovf_dir}/#{@vmname}-ovf'")
      system("zip -rj '#{@app_config.cache_dir}/#{@vmname}-vmware.zip' '#{@app_config.vmware_dir}/#{@vmname}-vmware'")
      system("zip -rj '#{@app_config.cache_dir}/#{@vmname}-vbox.zip' '#{@app_config.vbox_dir}/#{@vmname}-vbox'")
      system("md5 '#{@app_config.cache_dir}/#{@vmname}-ovf.zip' > '#{@app_config.cache_dir}/#{@vmname}-ovf.zip.md5'")
      system("md5 '#{@app_config.cache_dir}/#{@vmname}-vmware.zip' > '#{@app_config.cache_dir}/#{@vmname}-vmware.zip.md5'")
      system("md5 '#{@app_config.cache_dir}/#{@vmname}-vbox.zip' > '#{@app_config.cache_dir}/#{@vmname}-vbox.zip.md5'")
      # zip & md5 vagrant
    end

  end

end