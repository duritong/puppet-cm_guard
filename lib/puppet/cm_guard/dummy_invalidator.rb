# This is our default invalidator
# It simply tells CmGuard to always recompile
# the catalog and not use a cached one.
module Puppet::CmGuard
  class DummyInvalidator
    def recompile?(node)
      true  
    end
  end
end 
