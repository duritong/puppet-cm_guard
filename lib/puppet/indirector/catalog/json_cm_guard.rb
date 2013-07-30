unless Puppet.version =~ /^2\./ # this only supported from puppet >= 3.0 on
require 'puppet/indirector/catalog/json'
require 'puppet/cm_guard/mem_cache'
class Puppet::Resource::Catalog::JsonCmGuard < Puppet::Resource::Catalog::Json
  desc "Store catalogs as flat files, serialized using JSON."
  
  include Puppet::CmGuard::MemCache
end
end