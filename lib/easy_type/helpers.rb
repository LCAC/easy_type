require 'version_differentiator'
ruby_18 {require '1.8.7/csv'; CSV=FasterCSV}
ruby_19 {require 'csv'}


module EasyType
	#
	# Contains a set of helpe methods and classed tha can be used throughtout EasyType
	module Helpers
		# @private
		def self.included(parent)
			parent.extend(Helpers)
		end

		class InstancesResults < Hash
			#
			# @param [Symbol] column_name the name of the column to extract from the Hash
			# @raise [Puppet::Error] when the column name is not used in the Hash
			# @return content of the specified key in the Hash
			#
			def column_data(column_name)
				fetch(column_name) do 
					fail "Column #{column_name} not found in results. Results contain #{keys.join(',')}"
				end
			end
		end


		#
		# Convert a comma separated string into an Array of Hashes
		#
		# @param [String] csv_data comma separated string
		# @param [Array] headers of [Symbols] specifying the key's of the Hash
		# @param [Hash] options parsing options. You can specify all options of CSV.parse here
		# @return [Array] of [InstancesResults] a special Hash 
		#
		HEADER_LINE_REGEX = /^(\s*\-+\s*)*/

		def convert_csv_data_to_hash(csv_data, headers = [], options = {})
			options = check_options(options)
			default_options = {
				:header_converters=> lambda {|f| f ? f.strip : nil}
   			# :converters=> lambda {|f| f ? f.strip : nil}
   		}
   		if headers != []
   			default_options[:headers] = headers
   		else
   			default_options[:headers] = true
   		end
   		options = default_options.merge(options)
			skip_lines = options.delete(:skip_lines) {HEADER_LINE_REGEX }
			data = []
			CSV.parse(csv_data, options) do |row|
				data << InstancesResults[row.to_a] unless row_contains_skip_line(row,skip_lines)
			end
			data
		end
private

		def row_contains_skip_line(row, skip_lines)
			skip_lines.match(row.to_s)[1]
		end

		def check_options(options)
			deprecated_option(options,:column_delimeter, :col_sep)
			deprecated_option(options,:line_delimeter, :row_sep)
			options
 		end

 		def deprecated_option(options, old_id, new_id)
			old_value = options.delete(old_id)
			if old_value
	 			Puppet.deprecation_warning("#{old_id} deprecated. Please use #{new_id}")
	 			options[new_id] = old_value
	 		end
		end		
	end
end

