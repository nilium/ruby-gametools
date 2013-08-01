module GT ; end
class GT::Lexer ; end

#
# A position into a lexer's source string.
#
class GT::Lexer::Position

  # The line in the source string. Starts at 1.
  attr_accessor :line
  # The column in the source string. Starts at 1.
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
