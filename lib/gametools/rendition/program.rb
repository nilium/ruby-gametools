require 'opengl-core/aux'

module GT ; end

class GT::Program < Gl::Program

  def initialize(program = nil, &block)
    super(program)
    @aliases = {}
    self.class::Builder.build(self, &block) if block_given?
  end

  def alias_uniform(new_name, old_name)
    new_name = new_name.to_sym
    old_name = lookup_uniform_name(old_name.to_sym)
    hint_uniform(old_name)
    @aliases[new_name] = old_name unless new_name == old_name
  end

  def each_hinted_uniform(&block)
    hinted = @aliases.keys + super(&nil).to_a
    return hinted.each unless block_given?
    hinted.each(&block)
    self
  end

  # Public: De-aliases a uniform name Symbol.
  #
  # name - A uniform name Symbol.
  #
  # Returns a uniform alias Symbol or the provided name.
  def lookup_uniform_name(name)
    while @aliases.include? name
      name = @aliases[name]
    end
    name
  end

  def uniform_location(uniform_name)
    super(lookup_uniform_name(uniform_name.to_sym))
  end
  alias_method :[], :uniform_location

  def hint_uniform(uniform_name)
    super(lookup_uniform_name(uniform_name.to_sym))
  end

end


class GT::Program::Builder

  class <<self

    def build(program = nil, &block)
      raise ArgumentError, "build must be given a block" unless block_given?
      program ||= GT::Program.new
      self.new(program).instance_exec(&block)
      unless program.link
        program.delete
        raise program.info_log
      end
      program
    rescue
      program.delete if program
      raise
    end

    def load_shader_object(shader_path_or_source, type)
      shader_source =
        case #shader_path_or_source
        when shader_path_or_source.kind_of?(IO)
          shader_path_or_source.read

        when shader_path_or_source.kind_of?(String) &&
             File.exists?(shader_path_or_source)
          File.open(shader_path_or_source, 'r') { |io| io.read }

        else
          shader_path_or_source.to_s
        end

      shader = Shader.new(type)
      shader.source = shader_source

      unless shader.compile
        shader.delete
        raise shader.info_log
      end

      shader
    rescue
      shader.delete if shader
      raise
    end

  end


  def initialize(program)
    @program = program
  end

  def vertex_shader(shader_path_or_source)
    shader = self.class::load_shader_object(shader_path_or_source,
                                            Gl::GL_VERTEX_SHADER)
    @program.attach_shader(shader)
    shader.delete
  end
  alias_method :vert, :vertex_shader

  def tess_control_shader(shader_path_or_source)
    shader = self.class::load_shader_object(shader_path_or_source,
                                            Gl::GL_TESS_CONTROL_SHADER)
    @program.attach_shader(shader)
    shader.delete
  end
  alias_method :tess_control, :tess_control_shader

  def tess_evaluation_shader(shader_path_or_source)
    shader = self.class::load_shader_object(shader_path_or_source,
                                            Gl::GL_TESS_EVALUATION_SHADER)
    @program.attach_shader(shader)
    shader.delete
  end
  alias_method :tess_eval, :tess_evaluation_shader

  def geometry_shader(shader_path_or_source)
    shader = self.class::load_shader_object(shader_path_or_source,
                                            Gl::GL_GEOMETRY_SHADER)
    @program.attach_shader(shader)
    shader.delete
  end
  alias_method :geom, :geometry_shader

  def fragment_shader(shader_path_or_source)
    shader = self.class::load_shader_object(shader_path_or_source,
                                            Gl::GL_FRAGMENT_SHADER)
    @program.attach_shader(shader)
    shader.delete
  end
  alias_method :frag, :fragment_shader

  def vertex_attrib(location, name)
    @program.bind_attrib_location(location, name)
  end
  alias_method :attrib, :vertex_attrib

  def alias_uniform(new_name, old_name)
    @program.alias_uniform(new_name, old_name)
  end

  def hint_uniform(name)
    @program.hint_uniform(name)
  end

  def uniform(name, old_name = nil)
    case
    when name && old_name   then alias_uniform(name, old_name)
    when name && ! old_name then hint_uniform(name)
    else raise ArgumentError, "name must not be nil or false"
    end
  end

  def frag_out(output, name)
    output = case output
             when Fixnum then output
             when :out0 then 0
             when :out1 then 1
             when :out2 then 2
             when :out3 then 3
             when :out4 then 4
             when :out5 then 5
             when :out6 then 6
             when :out7 then 7
             else output
             end
    @program.bind_frag_data_location(output, name)
  end

end

