#!/usr/bin/env ruby

require 'spec_helper'
require 'simple_resource/parameter'

describe SimpleResource::Parameter do

	before do
		class Test
			include SimpleResource::Parameter
		end
	end

	describe ".on_apply" do

		before do
			class Test
				on_apply do
					"done"
				end
			end
		end

		subject { Test.new}

		it "adds a instance method on_apply" do
			expect( subject.on_apply).to eql('done')
		end
	end


	describe ".to_translate_to_resource" do

		before do
			class Test
				to_translate_to_resource do
					"done"
				end
			end
		end


		it "adds a class method translate_to_resource" do
			expect( Test.translate_to_resource).to eql('done')
		end

	end


end

