require 'gametools/rendition/pass'
require 'gametools/rendition/pass/builder'

module GT ; end
class GT::Material ; end

class GT::Material::Builder

  def self.build(material, &block)
    raise ArgumentError, "build must be given a block" unless block_given?
    self.new(material).instance_exec(&block)
    material
  end

  def initialize(material)
    @material = material
  end

  def pass(index = nil, &block)
    passes = @material.passes
    index ||= passes.length
    pass = GT::Pass.new
    pass.class::Builder.build(pass, &block)
    passes[index] = pass
  end

end