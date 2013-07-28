module GT ; end
class GT::Lexer ; end

class GT::Lexer::Position

  attr_accessor :line
  attr_accessor :column

  class << self ; alias_method :[], :new ; end

  def initialize(line = 0, column = 0)
    @line   = line
    @column = column
  end

  def to_s
    "[#{@line}:#{@column}]"
  end

end
