require 'opengl-core'
require 'opengl-core/aux'
require 'snow-math'

module GT ; end

class GT::UniformHash < Hash

  NO_UNIFORM = -1

  @@instance = nil

  def self.instance
    @@instance ||= self.new
  end

  def self.instance=(hash)
    raise "Invalid object" unless hash.nil? || hash.kind_of?(self)
    @@instance = hash
  end

  #
  # Valid types for PackedValue:
  # - Any acceptable type given to #store
  # - :uint, :uint2, :uint3, or :uint4     -> glUniformNuiv or glUniformNui
  # - :int, :int2, :int3, or :int4         -> glUniformNiv or glUniformNi
  # - :float, :float2, :float3, or :float4 -> glUniformNfv or glUniformNf
  # - :mat3 or :float3x3                   -> glUniformMatrix3fv (transpose = GL_FALSE)
  # - :mat4 or :float4x4                   -> glUniformMatrix4fv (transpose = GL_FALSE)
  #
  # type::       Class or Symbol
  # length::     Fixnum (number of elements)
  # value::      String (from Array#pack)
  #
  PackedValue = Struct.new(:type, :length, :value)


  #
  # Assign a value to a uniform with the given name. The value must be a
  # compatible type -- either a snow-math type, a PackedValue, a Float, a
  # Fixnum, or nil.
  #
  #---
  # It's assumed that, when generating a PackedValue from an array, that the
  # array is already flat (or reasonably flat -- the one exception to this is
  # any array of snow-math types, be it the bases or the typed arrays -- in
  # which case they will be converted to arrays and flattened).
  #
  # If you can help it, and I hope to hell you can, you should avoid in any
  # urge to pass in a non-typed array of snow-math types because it will result
  # in a whole hell of a lot of allocations.
  #+++
  def store(name, value)
    super(
      name.to_sym,
      case value

      when PackedValue, Float, Fixnum,
           Snow::Vec2, Snow::Vec2Array,
           Snow::Vec3, Snow::Vec3Array,
           Snow::Vec4, Snow::Vec4Array,
           Snow::Mat3, Snow::Mat3Array,
           Snow::Mat4, Snow::Mat4Array,
           Snow::Quat, Snow::QuatArray, nil
        value

      when Array
        count = value.length
        first_value = value.first
        klass = first_value.class
        # Get the array packing type -- only the first value of the array counts
        # towards the packed value's type. Further types are expected to be the
        # same or can be coerced into that type.
        pack_type =
          case klass
          when Fixnum then 'l*'
          when Float then  'f*'
          when Snow::Vec2, Snow::Vec3, Snow::Vec4, Snow::Quat, Snow::Mat3, Snow::Mat4
            # Flatten the array of snow-math objects into an array of floats
            value = value.each_with_object([]) { |obj, arr|
              obj.each { |inner_value| arr << inner_value }
            }
            'f*'
          when Snow::Vec2Array, Snow::Vec3Array, Snow::Vec4Array, Snow::QuatArray,
               Snow::Mat3Array, Snow::Mat4Array
            # Flatten the array of snow-math arrays
            klass = klass::TYPE
            count = 0
            # Iterate over the inner object's values
            value = value.each_with_object([]) { |inner_arr, arr|
              count += inner_arr.length
              # Iterate over the inner array's objects
              inner_arr.each { |inner_obj|
                # Iterate over inner arrays
                inner_obj.each { |inner_value| arr << inner_value }
              }
            }
            'f*'
          else
            raise "Invalid value array for uniform hash (#{name.inspect} => #{value.inspect})"
          end

        PackedValue[
          klass,
          count,
          value.pack(pack_type)]

      else
        raise "Invalid value for uniform hash (#{name.inspect} => #{value.inspect})"
      end)
  end
  alias_method :[]=, :store

  #
  # Binds a specific named uniform in the hash. If the uniform is not defined in
  # the hash or the location given is NO_UNIFORM, then this is a no-op.
  #
  def bind_uniform(name, location)
    return if location == NO_UNIFORM
    value = self[name]
    return unless value

    type, length, address =
      if value.kind_of? PackedValue
        [value.type, value.length, value.value]
      elsif value.respond_to? :address
        [value.class, value.length, value.respond_to?(:to_p) ? value.to_p : value.address]
      else
        [value.class, 1, nil]
      end

    # Bind the value to the uniform location. Because you can't do
    # Class === Class, this basically turns into a long series of type == X
    # entries. Might be better to refactor it as a bunch if/elsif blocks.
    case

    when type == nil then return

    when type == Float ||
         type == :float
      if address
        glUniform1iv(location, length, address)
      else
        glUniform1i(location, value)
      end

    when type == Fixnum ||
         type == :int
      if address
        glUniform1iv(location, length, address)
      else
        glUniform1i(location, value)
      end

    when type == :int2
      if address
        glUniform2iv(location, length, address)
      else
        glUniform2i(location, *value)
      end

    when type == :int3
      if address
        glUniform3iv(location, length, address)
      else
        glUniform3i(location, *value)
      end

    when type == :int4
      if address
        glUniform4iv(location, length, address)
      else
        glUniform4i(location, *value)
      end

    when type == :uint
      if address
        glUniform1uiv(location, length, address)
      else
        glUniform1ui(location, value)
      end

    when type == :uint2
      if address
        glUniform2uiv(location, length, address)
      else
        glUniform2ui(location, *value)
      end

    when type == :uint3
      if address
        glUniform3uiv(location, length, address)
      else
        glUniform3ui(location, *value)
      end

    when type == :uint4
      if address
        glUniform4uiv(location, length, address)
      else
        glUniform4ui(location, *value)
      end

    when type == Snow::Vec2
      Gl::glUniform2fv(location, 1, address)

    when type == Snow::Vec3
      Gl::glUniform3fv(location, 1, address)

    when type == Snow::Vec4 ||
         type == Snow::Quat
      Gl::glUniform4fv(location, 1, address)

    when type == Snow::Mat3
      Gl::glUniformMatrix3fv(location, 1, Gl::GL_FALSE, address)

    when type == Snow::Mat4
      Gl::glUniformMatrix4fv(location, 1, Gl::GL_FALSE, address)

    when type == Snow::Vec2Array ||
         type == :float2
      Gl::glUniform2fv(location, value.length, address)

    when type == Snow::Vec3Array ||
         type == :float3
      Gl::glUniform3fv(location, value.length, address)

    when type == Snow::Vec4Array ||
         type == Snow::QuatArray ||
         type == :float4 ||
         type == :quat
      Gl::glUniform4fv(location, value.length, address)

    when type == Snow::Mat3Array ||
         type == :mat3 ||
         type == :float3x3
      Gl::glUniformMatrix3fv(location, value.length, Gl::GL_FALSE, address)

    when type == Snow::Mat4Array ||
         type == :mat4 ||
         type == :float4x4
      Gl::glUniformMatrix4fv(location, value.length, Gl::GL_FALSE, address)

    else
      raise "Invalid value of type #{value.class} bound to uniform #{name}"
    end

    nil
  end

  #
  # Binds all uniforms in the hash or any number of named uniforms passed after
  # the program the get the uniform locations from. The program must respond to
  # a call to #uniform_location and return a valid GL uniform or NO_UNIFORM if
  # the program doesn't have that uniform.
  #
  # The program must already be in use.
  #
  def bind(program, *names)
    if names.empty?
      program.each_hinted_uniform do |name|
        location = program.uniform_location(name)
        next if location == NO_UNIFORM
        bind_uniform(name, location)
      end
    else
      names.each do |name|
        name = name.to_sym
        next unless include? name
        location = program.uniform_location(name)
        next if location == NO_UNIFORM
        bind_uniform(name, location)
      end
    end

    self
  end
end
