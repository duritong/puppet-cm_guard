source "https://rubygems.org"

if ENV.key?('PUPPET_VERSION')
  puppetversion = "#{ENV['PUPPET_VERSION']}"
  if puppetversion =~ /( |=)2.7/
    gem 'hiera-puppet'
  end
else
  puppetversion = ['>= 3.0']
end

gem 'puppet', puppetversion
gem 'puppetlabs_spec_helper', '>= 0.4.0'
