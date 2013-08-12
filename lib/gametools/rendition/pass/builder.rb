# :markup: tomdoc

require 'gametools/rendition/texture'

module GT ; end
class GT::Pass ; end

# Internal: A builder class to help define materials in Ruby source. Those using
# this function should only ever call its ::build singleton method with a block.
#
# Typically only used by GT::Material::Builder.
class GT::Pass::Builder

  class <<self

    # Public: Builds a pass using the Builder. Must be provided a block.
    #
    # pass  - The pass to build with. If nil, a new Pass object is allocated and
    #         will be the pass returned.
    # block - The block to use when building the pass. This block will executed
    #         in the context of a builder instance.
    #
    # Examples
    #
    #   GT::Pass::Builder.build {
    #     map 'some_texture.png'
    #     map 'another_texture.png',
    #         min_filter: nearest,
    #         mag_filter: nearest
    #
    #     shader shader_program
    #   }
    #   # => #<GT::Pass:...>
    #
    # Returns the provided Pass or a new Pass.
    # Raises ArgumentError if no block is given.
    #
    # Signature
    #
    #   build([pass = nil]) { }
    def build(pass = nil, &block)
      raise ArgumentError, "build must be given a block" unless block_given?
      pass ||= GT::Pass.new
      self.new(pass).instance_exec(&block)
      pass
    end

    # Internal: Converts a GL texture filter symbol to a GL constant.
    #
    # Returns a GL constant.
    def filter_constant(name)
      case name
      when :linear, nil            then Gl::GL_LINEAR
      when :nearest                then Gl::GL_NEAREST
      when :linear_mipmap_nearest  then Gl::GL_LINEAR_MIPMAP_NEAREST
      when :nearest_mipmap_linear  then Gl::GL_NEAREST_MIPMAP_LINEAR
      when :nearest_mipmap_nearest then Gl::GL_NEAREST_MIPMAP_NEAREST
      when :linear_mipmap_linear   then Gl::GL_LINEAR_MIPMAP_LINEAR

      when Gl::GL_LINEAR, Gl::GL_NEAREST, Gl::GL_LINEAR_MIPMAP_NEAREST,
           Gl::GL_NEAREST_MIPMAP_LINEAR, Gl::GL_NEAREST_MIPMAP_NEAREST,
           Gl::GL_LINEAR_MIPMAP_LINEAR
        name

      else raise ArgumentError, "Invalid filter type: #{name}"
      end
    end

    # Internal: Converts a GL texture wrapping symbol to a GL constant.
    #
    # Returns a GL constant.
    def wrap_constant(name)
      case name
      when :repeat, nil then Gl::GL_REPEAT
      when :clamp       then Gl::GL_CLAMP_TO_EDGE
      when :mirror      then Gl::GL_MIRRORED_REPEAT

      when Gl::GL_REPEAT, Gl::GL_CLAMP_TO_EDGE, Gl::GL_MIRRORED_REPEAT
        name

      else raise ArgumentError, "Invalid wrapping type: #{name}"
      end
    end

    def depth_func_constant(func)
      case func
      when :never    then Gl::GL_NEVER
      when :less     then Gl::GL_LESS
      when :equal    then Gl::GL_EQUAL
      when :lequal   then Gl::GL_LEQUAL
      when :greater  then Gl::GL_GREATER
      when :notequal then Gl::GL_NOTEQUAL
      when :gequal   then Gl::GL_GEQUAL
      when :always   then Gl::GL_ALWAYS

      when Gl::GL_NEVER, Gl::GL_LESS, Gl::GL_EQUAL, Gl::GL_LEQUAL,
           Gl::GL_GREATER, Gl::GL_NOTEQUAL, Gl::GL_GEQUAL, Gl::GL_ALWAYS
        func

      else
        raise ArgumentError, "Invalid function: #{func}"
      end
    end
    alias_method :stencil_func_constant, :depth_func_constant

    def stencil_op_constant(op)
      case op
      when :keep      then Gl::GL_KEEP
      when :zero      then Gl::GL_ZERO
      when :replace   then Gl::GL_REPLACE
      when :incr      then Gl::GL_INCR
      when :incr_wrap then Gl::GL_INCR_WRAP
      when :decr      then Gl::GL_DECR
      when :decr_wrap then Gl::GL_DECR_WRAP
      when :invert    then Gl::GL_INVERT
      when Gl::GL_KEEP, Gl::GL_ZERO, Gl::GL_REPLACE, Gl::GL_INCR,
           Gl::GL_INCR_WRAP, Gl::GL_DECR, Gl::GL_DECR_WRAP, Gl::GL_INVERT
        op
      else
        raise ArgumentError, "Invalid stencil op: #{op}"
      end
    end

    def blend_func_constant(func)
      case func
      when :zero                then Gl::GL_ZERO
      when :one                 then Gl::GL_ONE
      when :src_color           then Gl::GL_SRC_COLOR
      when :one_minus_src_color then Gl::GL_ONE_MINUS_SRC_COLOR
      when :dst_color           then Gl::GL_DST_COLOR
      when :one_minus_dst_color then Gl::GL_ONE_MINUS_DST_COLOR
      when :src_alpha           then Gl::GL_SRC_ALPHA
      when :one_minus_src_alpha then Gl::GL_ONE_MINUS_SRC_ALPHA
      when :dst_alpha           then Gl::GL_DST_ALPHA
      when :one_minus_dst_alpha then Gl::GL_ONE_MINUS_DST_ALPHA

      when Gl::GL_ZERO, Gl::GL_ONE, Gl::GL_SRC_COLOR, Gl::GL_ONE_MINUS_SRC_COLOR,
           Gl::GL_DST_COLOR, Gl::GL_ONE_MINUS_DST_COLOR, Gl::GL_SRC_ALPHA,
           Gl::GL_ONE_MINUS_SRC_ALPHA, Gl::GL_DST_ALPHA, Gl::GL_ONE_MINUS_DST_ALPHA
        func

      else
        raise ArgumentError, "Invalid blend function: #{func}"
      end
    end

    def boolean_value(value)
      case value
      when true, :on, :yes, :true, :enabled, Gl::GL_TRUE     then true
      when false, :off, :no, :false, :disabled, Gl::GL_FALSE then false
      else raise ArgumentError, "Invalid boolean value: #{enabled}"
      end
    end

  end

  # Internal: Initializes the Builder with a Pass to use.
  #
  # Raises ArgumentError if the pass is nil.
  def initialize(pass)
    raise ArgumentError, "Pass is nil" unless pass
    @pass = pass
  end

  # Public: Adds a texture unit state object to the pass. If a unit is specific,
  # defines that specific unit, otherwise appends a unit to the pass's list of
  # texture units. Optionally specifies filtering and wrapping parameters,
  # otherwise uses TextureState defaults.
  #
  # Returns the new TextureState.
  def map(path, unit: nil, min_filter: nil, mag_filter: nil, x_wrap: nil, y_wrap: nil, z_wrap: nil)
    units = @pass.texture_units
    unit ||= units.length

    gen_mipmaps = min_filter != :linear && min_filter != :nearest

    min_filter = self.class.filter_constant(min_filter)
    mag_filter = self.class.filter_constant(mag_filter)

    x_wrap = self.class.wrap_constant(x_wrap)
    y_wrap = self.class.wrap_constant(y_wrap)
    z_wrap = self.class.wrap_constant(z_wrap)

    state = GT::Pass::TextureState.new(
      GT::Texture.new(path, gen_mipmaps),
      min_filter: min_filter,
      mag_filter: mag_filter,
      x_wrap: x_wrap,
      y_wrap: y_wrap,
      z_wrap: z_wrap)

    units[unit] = state

    state
  end

  #
  # Sets the shader object for the pass. Overwrites prior shader settings.
  #
  # Returns the assigned Program object.
  #
  def program(program = nil, &block)
    @pass.program =
      case #program
      when program.nil? && ! block_given?
        raise ArgumentError, "Must be given a block or a Program object"
      when block_given?
        GT::Program.new(nil, &block)
      else
        program
      end
  end

  def blend(*args)
    if args.length == 1
      args = case args[0]
             when :opaque
               [Gl::GL_ONE, Gl::GL_ZERO]
             when :alpha, :transparent
               [Gl::GL_SRC_ALPHA, Gl::GL_ONE_MINUS_SRC_ALPHA]
             when :premul_alpha, :premultiplied_alpha
               [Gl::GL_SRC_ALPHA, Gl::GL_ONE_MINUS_SRC_ALPHA]
             when :add, :additive, :screen
               [Gl::GL_SRC_ALPHA, Gl::GL_ONE]
             when :multiply, :modulate
               [Gl::GL_SRC_ALPHA, Gl::GL_DST_COLOR]
             else
               raise ArgumentError, "Invalid single blend function: #{args[0]}"
             end
    elsif args.length != 2
      raise ArgumentError, "Invalid arguments to blend: #{args}"
    end

    args.map! { |func| self.class.blend_func_constant(func) }

    @pass.blend_source = args[0]
    @pass.blend_dest   = args[1]
  end

  def depth_mask(enabled)
    @pass.depth_mask = self.class.boolean_value(enabled)
  end

  def depth_func(mode)
    @pass.depth_func = self.class.depth_func_constant(mode)
  end

  def stencil_mask(mask)
    @pass.stencil_mask = mask
  end

  def stencil_func(mode, ref = 0, mask = ~0)
    @pass.stencil_func = self.class.stencil_func_constant(mode)
    @pass.stencil_ref  = ref
    @pass.stencil_mask = mask
  end

  def stencil_op(stencil_fail, depth_fail, depth_pass)
    @pass.stencil_fail = self.class.stencil_op_constant(stencil_fail)
    @pass.depth_fail   = self.class.stencil_op_constant(depth_fail)
    @pass.depth_pass   = self.class.stencil_op_constant(depth_pass)
  end

  def before(&block)
    @pass.pre_pass = block && lambda(&block)
  end

  def after(&block)
    @pass.post_pass = block && lambda(&block)
  end

end
