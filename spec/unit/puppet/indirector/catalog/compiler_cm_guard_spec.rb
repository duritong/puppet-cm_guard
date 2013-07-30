#! /usr/bin/env ruby
require 'puppetlabs_spec_helper/module_spec_helper'
require 'puppet/indirector/catalog/compiler_cm_guard'

describe Puppet::Resource::Catalog::CompilerCmGuard do

  before :each do
    vardir = Dir.mktmpdir('cm_guard',File.expand_path(File.join(File.dirname(__FILE__),'../../../../tmp')))
    if Puppet.version =~ /^2\./
      # Puppet 2.7 does not yet create this directory automatically
      Dir.mkdir File.join(vardir,'client_yaml')
    end
    Puppet[:vardir] = vardir
  end

  let(:request) do
    Puppet::Indirector::Request.new(:the_indirection_named_foo,
                                    :find,
                                    "the-node-named-foo",
                                    :environment => "production")
  end 

  describe "#find" do
    it "returns a catalog" do
      subject.find(request).should be_a_kind_of(Puppet::Resource::Catalog)
    end 

    it 'caches the catalog by default' do
      cache = Object.new
      cache.expects(:find).returns(nil)
      cache.expects(:save)
      subject.stubs(:cm_cache).returns(cache)
      subject.find(request).should be_a_kind_of(Puppet::Resource::Catalog)
    end

    it 'does not recompile if cached catalog present and not requested to recompile' do
      cache = Object.new
      catalog = Object.new
      cache.expects(:find).returns(catalog)
      cache.expects(:save).never
      subject.expects(:recompile?).returns(false)
      subject.stubs(:cm_cache).returns(cache)
      Puppet.expects(:notice).with("Using cached catalog for the-node-named-foo")
      subject.find(request).should eql(catalog)
    end

    it 'does recompile the catalog if cached catalog present but requested to recompile' do
      cache = Object.new
      catalog = Object.new
      cache.expects(:find).returns(catalog)
      cache.expects(:save)
      subject.expects(:recompile?).returns(true)
      subject.stubs(:cm_cache).returns(cache)
      subject.find(request).should be_a_kind_of(Puppet::Resource::Catalog)
    end

    it 'returns nil if no catalog is found and does not cache it' do
      cache = Object.new
      compiler = Object.new
      compiler.expects(:find).returns(nil)
      cache.expects(:save).never
      cache.expects(:find).returns(nil)
      subject.stubs(:cm_cache).returns(cache)
      subject.stubs(:compiler).returns(compiler)

      subject.find(request).should be_nil
    end
  end
end


