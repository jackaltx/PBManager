require 'PBManager/version'
require 'PBManager/app_config'
require 'PBManager/error'
require 'PBManager/util'
require 'PBManager/vagrant_mgr'
require 'PBManager/iso_builder'

module PBManager

  # expose these at the module level -
  # While I am using the Module to create a namespace, this is a trick to create a simple interface for all.
  # The side effect I don't like is that it exposes some internals attributes.
  class << self
    attr_reader :log
    attr_reader :settings
  end

  # this makes PBManager::log available for all
  # note: this is the first call to the singleton!!!!!
  @log = PBManager::AppConfig.instance.log

  # this makes PBManager::settings available for all
  # these settings are both runtime and application currently.
  @settings = PBManager::AppConfig.instance.settings

end
