# This is an example invalidator for
# CmGuard based on hiera lookups.
#
# It will ask hiera whether the node should be updated
# or not by looking up the key `update_node` (default: false).
# The scope will be all params that the node got, which are all the
# facts and ENC parameters.
module Puppet::CmGuard
  class HieraInvalidator
begin
  require 'hiera_puppet' # only load if the code is used
  include HieraPuppet
rescue LoadError# on clients hiera_puppet migh not be deployed
end

    def recompile?(node)
      scope = node.parameters.dup 
      hl('update_node',scope,false) == true
    end
  
    def hl(key,scope,default)
      lookup(key,default,scope,nil,:priority)
    end
  end
end
