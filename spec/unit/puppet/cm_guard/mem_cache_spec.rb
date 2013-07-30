#! /usr/bin/env ruby
require 'puppetlabs_spec_helper/module_spec_helper'
require 'puppet/cm_guard/mem_cache'

class MemCacheDummyParent

  def self.base_path
    Dir.mktmpdir('mem_cache',File.expand_path(File.join(File.dirname(__FILE__),'../../../tmp')))
  end

  def find(request)
    :catalog_on_disc
  end

  def save(request)
    true
  end

  def path(name,ext)
    "#{MemCacheDummy.base_path}/#{name}.dummy"
  end

end
class MemCacheDummyParentNil < MemCacheDummyParent
  def find(request)
    nil
  end
end
class MemCacheDummy2 < MemCacheDummyParentNil
  include Puppet::CmGuard::MemCache
end
class MemCacheDummy < MemCacheDummyParent
  include Puppet::CmGuard::MemCache
end

DummyRequest = Struct.new(:key,:instance)

describe Puppet::CmGuard::MemCache do
  let!(:subject) { MemCacheDummy.new }
  let!(:subject2) { MemCacheDummy2.new }
  let(:request) { DummyRequest.new('key','instance') }
  let(:now) { Time.now }

  describe "#find" do
    context "with a cached catalog" do
      it 'returns the cached catalog if timestamp is the current' do
        subject.send(:cache_catalog,'key','instance',now)
        subject.expects(:read_timestamp).returns(now)
        subject.find(request).should eql('instance')
      end
      it 'does not return the cached catalog if timestamp is old' do
        subject.send(:cache_catalog,'key','instance',Time.mktime(0))
        subject.stubs(:read_timestamp).returns(now)
        subject.find(request).should eql(:catalog_on_disc)
      end
      it 'recaches the freshly read catalog' do
        subject.send(:cache_catalog,'key','instance',Time.mktime(0))
        subject.stubs(:read_timestamp).returns(now)
        subject.find(request).should eql(:catalog_on_disc)
        subject.send(:mem_cache)['key'][:catalog].should eql(:catalog_on_disc)
      end
      it 'does not cache a nil catalog' do
        subject2.send(:cache_catalog,'key','instance',Time.mktime(0))
        subject2.stubs(:read_timestamp).returns(now)
        subject2.expects(:cache_catalog).never
        subject2.find(request).should be_nil
      end
    end
    context 'without a cached catalog' do
      it 'delegates to the parent' do
        subject.expects(:current_cache).with('key').returns(nil)
        subject.expects(:read_timestamp).returns(now)
        subject.expects(:cache_catalog).with('key',:catalog_on_disc,now)
        subject.find(request).should eql(:catalog_on_disc)
      end
      it 'does not cache the catalog if there is no timestamp' do
        subject.expects(:current_cache).with('key').returns(nil)
        subject.expects(:read_timestamp).returns(nil)
        subject.expects(:cache_catalog).never
        subject.find(request).should eql(:catalog_on_disc)
      end

    end
  end
  describe "#save" do
    it 'caches the stored catalog with the right timestamp' do
      subject.expects(:save_timestamp).with('key').returns(:some_time)
      subject.save(request).should be_true
      subject.send(:mem_cache)['key'][:timestamp].should eql(:some_time)
    end
  end
end


