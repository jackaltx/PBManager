iso_mgr = nil

desc "Build and populate data directory"
task :init do

  # this loads the application and config data
  require "PBManager"
end

desc "Creates a modified ISO with preseed/kickstart"
task :createiso => :init do

  # this loads the type
  # TODO  make this a factory
  iso_mgr = PBManager::IsoBuilder.new

  if !iso_mgr.iso_exists?
    puts "creating build_iso"
    iso_mgr.create_build_root
    iso_mgr.create_iso
  else
    puts "build_iso exists"
  end
end

desc "Create a new vmware instance for kickstarting"
task :createvm => :createiso do
  vagrant_mgr = PBManager::VagrantMgr.new(iso_mgr.vm_name)
  vagrant_mgr.create_vm
  vagrant_mgr.mountiso
  vagrant_mgr.createovf
  vagrant_mgr.createvmx
  vagrant_mgr.createvbox
  vagrant_mgr.vagrantize
  #vagrant_mgr.packagevm
end
