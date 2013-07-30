#! /usr/bin/env ruby
require 'puppetlabs_spec_helper/module_spec_helper'
require 'puppet/cm_guard/dummy_invalidator'

describe Puppet::CmGuard::DummyInvalidator do

  describe "#recompile?" do
    it "always recompiles" do
      subject.recompile?(nil).should be_true
    end 
  end
end


