module EasyType
  #
  # EasyType is a flushable provider. To use this provider, you have to 
  # add certain information to the type definition.
  # You MUST define following attributes on the type
  #
  #  on_create do
  #    "create user #{self[:name]}"
  #  end
  #
  #  on_modify do
  #    "alter user #{self[:name]}"
  #  end
  #
  #  on_destroy do
  #    "drop user #{self[:name]}"
  #  end
  #
  # for all properties you MUST add
  # 
  #  on_apply do
  #   "identified by #{resource[:password]}"
  #  end
  module Provider

    attr_reader :property_flush, :property_hash

    # @private
    def self.included(parent)
      parent.extend(ClassMethods)
    end

    # @private
    def initialize(value={})
      super(value)
      @property_flush = {}
    end

    #
    # Checks if the resource exists. It does that by checking if the ensure property
    # in the property_hash contains :present
    #
    # @return [Boolean] true if it exsist, false if it doesn't exist
    #
    def exists?
      @property_hash[:ensure] == :present
    end

    #
    # Create the resource based on:
    #  - The values in the property_hash
    #  - the command set on the Type
    #  - The on_create value of the Type
    #  - The on_apply values of all the specified parameters and properties
    #
    def create
      @property_flush = @resource
      @property_hash[:ensure] = :present
      command = build_from_type(resource.method(:on_create))
      command.execute
      @property_flush = {}
    end

    #
    # Destroy the resource based on:
    #  - the command set on the Type
    #  - The on_destroy value of the Type
    #
    def destroy
      command = build_from_type(resource.method(:on_destroy))
      command.execute
      @property_hash.clear
      @property_flush = {}
    end

    #
    # Modify the resource based on:
    #  - The values in the property_hash
    #  - the command set on the Type
    #  - The on_modify value of the Type
    #  - The on_apply values of all the specified parameters and properties
    #
    def flush
      if @property_flush && @property_flush != {}
        command = build_from_type(resource.method(:on_modify))
        command.execute
      end
    end

    private
    # @private
    def build_from_type(block)
      command_builder = ScriptBuilder.new( :binding => resource, :acceptable_commands => resource.commands)
      line = block.call( command_builder)
      command_builder.add(line)
      resource.properties.each do | prop |
        command_builder << "#{prop.on_apply command_builder} " if should_be_in_command(prop)
      end
      command_builder
    end

    ##
    # @private
    # Should be in command if the property has defined an apply command
    # and when it is modified e.g. in de @property_flush
    #
    def should_be_in_command(property)
      is_modified_and_defined(property) || is_in_a_modified_group(property)
    end

    # @private
    def is_in_a_modified_group(property)
      if resource.groups.include_property?(property.class) 
        groups = resource.groups
        group = groups.group_for(property.class)
        properties = groups.contents_for(group)
        names = properties.collect {|p| p.name}
        is_modified = names.reduce(false) do |value, entry|
          value || @property_flush[entry]
        end
        defined?(property.on_apply) && is_modified
      else
        false
      end
    end

    # @private
    def is_modified_and_defined(property)
      defined?(property.on_apply) && @property_flush[property.name] 
    end

    module ClassMethods
      #
      # define a getter and a setter method for evert specified parameter and property in the type.
      # Define the setter so it modifies the property_hash and the property_flush based on what the 
      # other provider methods expect.
      #
      def mk_resource_methods
        attributes = [resource_type.validproperties, resource_type.parameters].flatten
        raise Puppet::Error, 'no parameters or properties defined. Probably an error' if attributes == [:provider]
        attributes.each do |attr|
          attr = attr.intern
          next if attr == :name
          define_method(attr) do
            @property_hash[attr] || :absent
          end

          define_method(attr.to_s + "=") do |value|
            @property_flush[attr] = value
          end
        end
      end

      #
      # Retrieve the raw_resource information by calling the`get_raw_resources` method on the Type.
      # Map every element of this Array to a Puppet resource. and return this mapped Array
      #
      # @return [Array] Mapped Array of resources
      # @raise [Puppet::Error] When `get_raw_resources` is not defined on the type.
      #
      #
      def instances
        fail("information: to_get_raw_resources not defined on type #{resource_type.name}") unless defined?(resource_type.get_raw_resources)
        raw_resources = resource_type.get_raw_resources
        raw_resources.collect do |raw_resource|
          map_raw_to_resource(raw_resource)
        end
      end


      #
      # Prefetch all information of the specified resource. Because we already have everything in the inatnces
      # array, we just have to set the provider 
      #
      # @return [Array] of Puppet Resources
      #
      def prefetch(resources)
        objects = instances
        resources.keys.each do |name|
          if provider = objects.find{ |object| object.name == name } 
            resources[name].provider = provider
          end
        end
      end

    private
      # @private
      def map_raw_to_resource(raw_resource)
        resource = {}
        non_meta_parameter_classes.each do | parameter_class |
          if defined?(parameter_class.translate_to_resource)  
            resource[parameter_class.name] = parameter_class.translate_to_resource(raw_resource)
          end
        end
        resource[:ensure] = :present
        new(resource)
      end

      # @private
      def non_meta_parameter_classes
        resource_type.properties + non_meta_parameters.collect {|param| resource_type.paramclass(param)}
      end

      # @private
      def non_meta_parameters
        resource_type.parameters - resource_type.metaparams
      end

    end
  end

end