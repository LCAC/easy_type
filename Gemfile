source 'https://rubygems.org'

group :development, :test do
  gem 'rake',                    :require => false
  gem 'puppetlabs_spec_helper',  :require => false
  platform :ruby_19, :ruby_20 do
    gem 'guard'
    gem 'ruby_gntp' 
    gem 'guard-rspec'
    gem 'pry'
    gem 'pry-debugger'
    gem 'pry-stack_explorer'
  end
end

group :test do
  platform :ruby_19, :ruby_20 do
    gem 'coveralls',               :require => false
    gem 'simplecov',               :require => false
  end
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end
