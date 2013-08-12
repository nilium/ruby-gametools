require 'gametools/rendition/pass'
require 'gametools/rendition/material/builder'
require 'gametools/rendition/pass/builder'

module GT ; end

# Basic material
class GT::Material
  attr_accessor :passes

  def initialize(&block)
    @passes = []

    self.class::Builder.build(self, &block) if block_given?
  end

  def each(&block)
    @passes.each(&block)
  end

  def per_pass(&block)
    return to_enum(:per_pass) unless block_given?
    each { |pass| pass.do &block }
    self
  end

end