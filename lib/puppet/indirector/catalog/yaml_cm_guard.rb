require 'puppet/indirector/catalog/yaml'
require 'puppet/cm_guard/mem_cache'
class Puppet::Resource::Catalog::YamlCmGuard < Puppet::Resource::Catalog::Yaml
  desc "Store catalogs as flat files, serialized using YAML."
  
  include Puppet::CmGuard::MemCache
end
