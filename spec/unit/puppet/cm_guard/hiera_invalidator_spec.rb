#! /usr/bin/env ruby
require 'puppetlabs_spec_helper/module_spec_helper'
require 'puppet/cm_guard/hiera_invalidator'

describe Puppet::CmGuard::HieraInvalidator do

  let(:node) do
    node = Object.new
    node.stubs(:parameters).returns({})
    node
  end

  describe "#recompile?" do
    it "recompiles if hiera thinks so" do
      subject.expects(:lookup).with('update_node',false,{},nil,:priority).returns(true)
      subject.recompile?(node).should be_true
    end 

    it "does not recompile by default" do
      subject.recompile?(node).should be_false
    end
  end
end


