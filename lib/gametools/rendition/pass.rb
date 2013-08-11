require 'gametools/rendition/texture'
require 'opengl-core'
require 'opengl-core/aux'

module GT ; end

class GT::Pass

  # Whether the pass should be skipped.
  attr_accessor :skip
  # The source and destination blend factors for the blend function.
  attr_accessor :blend_source, :blend_dest
  # Depth function and mask
  attr_accessor :depth_func, :depth_mask
  # Stencil mask
  attr_accessor :stencil_mask
  # Stencil function
  attr_accessor :stencil_func, :stencil_ref, :stencil_ref_mask
  # Stencil ops
  attr_accessor :stencil_fail, :depth_fail, :depth_pass
  # Program object (Gl::Program).
  attr_accessor :program
  # Texture units array ( [TextureState, ...] ). Defaults to an empty array.
  # nil entries for a unit are considered unused and their state is not changed.
  attr_accessor :texture_units
  # Pre-pass proc or lambda. Defaults to nil.
  attr_accessor :pre_pass
  # Post-pass proc or lambda. Defaults to nil.
  attr_accessor :post_pass

  def initialize
    load_defaults!
  end

  #
  # Resets the pass's state to defaults. Named arguments correspond to those
  # aspects of the pass's to be reset. By default, all state is reset.
  #
  def load_defaults!(skip:          true,
                     blend_func:    true,
                     depth_func:    true,
                     depth_mask:    true,
                     stencil_mask:  true,
                     stencil_func:  true,
                     stencil_op:    true,
                     program:       true,
                     texture_units: true)

    # Whether the pass should be skipped entirely
    @skip = false if skip

    # Blend function (no BlendFuncSeparate usage)
    if blend_func
      @blend_source = Gl::GL_ONE
      @blend_dest   = Gl::GL_ZERO
    end

    # DepthFunc and DepthMask
    @depth_func = Gl::GL_LESS if depth_func
    @depth_mask = true        if depth_mask

    # StencilMask
    @stencil_mask = ~0 if stencil_mask
    # StencilFunc
    if stencil_func
      @stencil_func     = Gl::GL_ALWAYS
      @stencil_ref      = 0
      @stencil_ref_mask = ~0
    end
    # StencilOp
    if stencil_op
      @stencil_fail     = Gl::GL_KEEP
      @depth_fail       = Gl::GL_KEEP
      @depth_pass       = Gl::GL_KEEP
    end

    # UseProgram
    @program = 0 if program

    # Texture bindings and parameters -- indices map to texture units
    @texture_units = [] if texture_units
  end

  def freeze
    return self if frozen?
    @texture_units.each { |tex| ts.freeze if ts }
    super
  end

  def bind(force: false, current_pass: @@g_pass)
    return false if @skip && ! force

    current_pass ||= @@g_pass

    program = @program
    if force || @program != current_pass.program
      current_pass.program = program
      if program
        program.use
      else
        Gl::glUseProgram(0)
        # There's zero reason to go forward with this pass
        return false
      end
    end

    if force || blend_func_differs?(current_pass)
      Gl::glBlendFunc(@blend_source, @blend_dest)
      current_pass.blend_source = @blend_source
      current_pass.blend_dest   = @blend_dest
    end

    if force || depth_func_differs?(current_pass)
      Gl::glDepthFunc(@depth_func)
      current_pass.depth_func = @depth_func
    end

    if force || depth_mask_differs?(current_pass)
      Gl::glDepthMask(@depth_mask ? Gl::GL_TRUE : Gl::GL_FALSE)
      current_pass.depth_mask = @depth_mask
    end

    if force || stencil_mask_differs?(current_pass)
      Gl::glStencilMask(@stencil_mask)
      current_pass.stencil_mask = @stencil_mask
    end

    if force || stencil_mask_differs?(current_pass)
      Gl::glStencilFunc(@stencil_func, @stencil_ref, @stencil_ref_mask)
      current_pass.stencil_func     = @stencil_func
      current_pass.stencil_ref      = @stencil_ref
      current_pass.stencil_ref_mask = @stencil_ref_mask
    end

    if force || stencil_op_differs?(current_pass)
      Gl::glStencilOp(@stencil_fail, @depth_fail, @depth_pass)
      current_pass.stencil_fail = @stencil_fail
      current_pass.depth_fail   = @depth_fail
      current_pass.depth_pass   = @depth_pass
    end

    GT::UniformHash::instance.bind(program) if program

    current_units = current_pass.texture_units
    texture_units.each_with_index { |state, unit|
      current_tex_state = current_units[unit]
      next unless force || state.nil? || state != current_tex_state

      if state.texture
        Gl::glActiveTexture(Gl::GL_TEXTURE0 + unit)
        state.bind
      end

      if current_tex_state
        current_tex_state.copy(state)
      else
        current_units[unit] = state.dup
      end
    }

    return true
  end

  def do(force: false, pre_pass: nil, post_pass: nil, &block)
    return if @skip && ! force
    pre_pass.call(self) if pre_pass
    @pre_pass.call(self) if @pre_pass
    if self.bind
      yield self && block_given?
      @post_pass.call(self) if @post_pass
      post_pass.call(self) if post_pass
    end
  end

  def self.reset_pass_state!(current_pass: nil)
    DEFAULT_PASS.bind force: true, current_pass: current_pass
  end

  private

  def blend_func_differs?(other = nil)
    other ||= @@g_pass
    @blend_source     != other.blend_source ||
    @blend_dest       != other.blend_dest
  end

  def depth_func_differs?(other = nil)
    other ||= @@g_pass
    @depth_func       != other.depth_func
  end

  def depth_mask_differs?(other = nil)
    other ||= @@g_pass
    @depth_mask       != other.depth_mask
  end

  def stencil_mask_differs?(other = nil)
    other ||= @@g_pass
    @stencil_mask     != other.stencil_mask
  end

  def stencil_func_differs?(other = nil)
    other ||= @@g_pass
    @stencil_func     != other.stencil_func ||
    @stencil_ref      != other.stencil_ref ||
    @stencil_ref_mask != other.stencil_ref_mask
  end

  def stencil_op_differs?(other = nil)
    other ||= @@g_pass
    @stencil_fail     != other.stencil_fail ||
    @depth_fail       != other.depth_fail ||
    @depth_pass       != other.depth_pass
  end

end

class GT::Pass::TextureState
  attr_accessor :texture
  attr_accessor :min_filter, :mag_filter
  attr_accessor :x_wrap, :y_wrap, :z_wrap

  def initialize(texture = nil,
                 min_filter: Gl::GL_LINEAR,
                 mag_filter: Gl::GL_LINEAR,
                 x_wrap: Gl::GL_REPEAT,
                 y_wrap: Gl::GL_REPEAT,
                 z_wrap: Gl::GL_REPEAT)
    @texture    = texture
    @min_filter = min_filter || Gl::GL_LINEAR
    @mag_filter = mag_filter || Gl::GL_LINEAR
    @x_wrap     = x_wrap || Gl::GL_REPEAT
    @y_wrap     = y_wrap || Gl::GL_REPEAT
    @z_wrap     = z_wrap || Gl::GL_REPEAT
  end

  def bind
    @texture.bind(min_filter: @min_filter,
                  mag_filter: @mag_filter,
                  x_wrap: @x_wrap,
                  y_wrap: @y_wrap,
                  z_wrap: @z_wrap)
  end

  def copy(other)
    if other
      @texture    = other.texture
      @min_filter = other.min_filter
      @mag_filter = other.mag_filter
      @x_wrap     = other.x_wrap
      @y_wrap     = other.y_wrap
      @z_wrap     = other.z_wrap
    else
      @texture    = nil
      @min_filter = Gl::GL_LINEAR
      @mag_filter = Gl::GL_LINEAR
      @x_wrap = @y_wrap = @z_wrap = Gl::GL_REPEAT
    end
  end

  def ==(other)
    return false unless other.kind_of? self.class
    other.texture    == @texture ||
    other.min_filter == @min_filter ||
    other.mag_filter == @mag_filter ||
    other.x_wrap     == @x_wrap ||
    other.y_wrap     == @y_wrap ||
    other.z_wrap     == @z_wrap
  end
end

class GT::Pass
  @@g_pass = self.new
  DEFAULT_PASS = self.new.freeze
end

