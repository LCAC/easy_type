require 'spec_helper'
require 'easy_type/provider'

describe 'the provider' do

	subject { Puppet::Type.type(:test)}

	before do
		load File.join(File.dirname(__FILE__),'test_type.rb')
	end

	after do
		Puppet::Type.rmtype(:test)
	end

	describe ".instances" do

		it "calls get_raw_resources on the type" do
			expect(subject).to receive(:get_raw_resources).and_call_original
			subject.instances
		end

		describe "traversing type information" do
			it "calls map_raw_to_resource for every parameter when to_map_raw_to_resource set " do
				expect(Puppet::Type::Test::ParameterName).to receive(:translate_to_resource).exactly(2).times.and_call_original
				subject.instances
			end

			it "calls map_raw_to_resource for every property when to_map_raw_to_resource set " do
				expect(Puppet::Type::Test::My_property).to receive(:translate_to_resource).exactly(2).times.and_call_original
				subject.instances
			end
		end

		it "returns valid puppet resources" do
			expect(subject.instances[0].class).to eq Puppet::Type::Test 
		end

		it "returns all specfied valid puppet resources" do
			expect(subject.instances.length).to eq 2 
		end
	end

	describe "basic resource methods" do

		let(:resource) { Puppet::Type::Test.new(:name => 'a_test', :ensure => 'present', :my_property => 'my stuff')}

		describe "create" do

			it "calls on_create on the type" do
				expect_any_instance_of(subject).to receive(:on_create).and_call_original
				resource.provider.create
			end

			it "calls on_apply on the properties" do
				expect_any_instance_of(Puppet::Type::Test::My_property).to receive(:on_apply).and_call_original
				resource.provider.create
			end

		end

		describe "destroy" do

			it "calls on_destroy on the type" do
				expect_any_instance_of(subject).to receive(:on_destroy).and_call_original
				resource.provider.destroy
			end
		end

		describe "modify" do

			context "modifying a property outside a group" do

				it "calls on_update on the type" do
					resource.provider.my_property = "changed"
					expect_any_instance_of(subject).to receive(:on_modify).and_call_original
					resource.provider.flush
				end

				it "calls on_apply on the modified propertie" do
					resource.provider.my_property = "changed"
					expect_any_instance_of(Puppet::Type::Test::My_property).to receive(:on_apply).and_call_original
					resource.provider.flush
				end

				it "executes the command" do
					resource.provider.my_property = "changed"
					expect(resource.provider).to receive(:do_command).and_call_original
					resource.provider.flush
				end
			end

			context "modifying a property in a group" do

				it "calls on_update on the type" do
					resource.provider.first_in_group = "changed"
					expect_any_instance_of(subject).to receive(:on_modify).and_call_original
					resource.provider.flush
				end

				it "calls on_apply on all the properties in the group" do
					resource.provider.first_in_group = "changed"
					expect_any_instance_of(Puppet::Type::Test::First_in_group).to receive(:on_apply).and_call_original
					# expect_any_instance_of(Puppet::Type::Test::Second_in_group).to receive(:on_apply).and_call_original
					debugger
					resource.provider.flush
				end

				xit "executes the command" do
					resource.provider.my_property = "changed"
					expect(resource.provider).to receive(:do_command).and_call_original
					resource.provider.flush
				end
			end


		end


	end


end

