module GT ; end

#--
# Keep Lexer constants and such in scope
#++
class GT::Lexer

#
# A token produced by GT::Lexer.
#
class Token

  # Literal keyword token symbols to their descriptors.
  LITERAL_KEYWORDS = {
    :true_kw           => "true",
    :false_kw          => "false",
    :null_kw           => "null"
  }.freeze

  # Keyword token symbols to their descriptors.
  KEYWORDS = {}.merge!(LITERAL_KEYWORDS).freeze

  # Literal token symbols to their descriptors.
  LITERALS = {
    :integer_lit       => "integer",
    :float_lit         => "float",
    :integer_exp_lit   => "integer exp",
    :float_exp_lit     => "float exp",
    :hex_lit           => "hexnum lit",
    :bin_lit           => "binary lit",
    :single_string_lit => "'...' string",
    :double_string_lit => "\"...\" string"
  }.merge(LITERAL_KEYWORDS).freeze

  # Punctuation token symbols to their descriptors.
  PUNCTUATION = {
    :dot               => ".",
    :double_dot        => "..",
    :triple_dot        => "...",
    :bang              => "!",
    :not_equal         => "!=",
    :question          => "?",
    :hash              => "#",
    :at                => "@",
    :dollar            => "$",
    :percent           => "%",
    :paren_open        => "(",
    :paren_close       => ")",
    :bracket_open      => "[",
    :bracket_close     => "]",
    :curl_open         => "{",
    :curl_close        => "}",
    :caret             => "^",
    :tilde             => "~",
    :grave             => "`",
    :backslash         => "\\",
    :slash             => "/",
    :comma             => ",",
    :semicolon         => ";",
    :greater_than      => ">",
    :shift_right       => ">>",
    :greater_equal     => ">=",
    :less_than         => "<",
    :shift_left        => "<<",
    :lesser_equal      => "<=",
    :equals            => "=",
    :equality          => "==",
    :pipe              => "|",
    :or                => "||",
    :ampersand         => "&",
    :and               => "&&",
    :colon             => ":",
    :double_colon      => "::",
    :minus             => "-",
    :double_minus      => "--",
    :arrow             => "->",
    :plus              => "+",
    :double_plus       => "++",
    :asterisk          => "*",
    :double_asterisk   => "**"
  }.freeze

  #
  # All token symbols to their descriptors.
  #
  DESCRIPTORS = {
    :invalid           => "invalid",
    :newline           => "\\n",
    :id                => "identifier",
    :line_comment      => "// comment",
    :block_comment     => "/* comment */"
  }.merge!(PUNCTUATION).merge!(LITERALS).freeze

  # The token's kind, a symbol.
  attr_accessor :kind
  # The token's posiiton in its source string in lines/columns.
  attr_accessor :position
  # The start of the token in its source string.
  attr_accessor :from
  # The end of the token in its source string.
  attr_accessor :to
  # The token's string value.
  attr_accessor :value

  def initialize(kind = nil, position = nil, from = nil, to = nil, value = nil)
    @kind     = kind  || :invalid
    @position = if position
      position.dup
    else
      Position[-1, -1]
    end
    @from     = from  || -1
    @to       = to    || -1
    @value    = String.new(value || '').freeze
  end

  #
  # Returns a string describing the token.
  #
  def descriptor
    DESCRIPTORS[@kind].dup
  end

  #
  # Returns whether this token is an identifier.
  #
  def id?
    @kind == :id
  end

  #
  # Returns whether this token is a true or false boolean literal.
  #
  def boolean?
    @kind == :true_kw || @kind == :false_kw
  end

  #
  # Returns whether this token is a null keyword.
  #
  def null?
    @kind == :null_kw
  end

  #
  # Returns whether this token is a literal.
  #
  def literal?
    LITERALS.include? @kind
  end

  #
  # Returns whether the token is an integer literal. hex_lit and bin_lit tokens
  # are considered integer literals by this method.
  #
  def integer?
    @kind == :integer_lit || @kind == :integer_exp_lit || @kind == :hex_lit || @kind == :bin_lit
  end

  #
  # Returns whether the token is a float literal. hex_lit and bin_lit tokens are
  # not considered float literals by this method.
  #
  def float?
    @kind == :float_lit || @kind == :float_exp_lit
  end

  #
  # Returns whether the token is a string literal.
  #
  def string?
    @kind == :double_string_lit || @kind == :single_string_lit
  end

  #
  # Returns whether the token is a comment.
  #
  def comment?
    @kind == :line_comment || @kind == :block_comment
  end

  #
  # Returns whether the token is punctuation.
  #
  def punctuation?
    PUNCTUATION.include? @kind
  end

  #
  # Returns whether the token is a newline.
  #
  def newline?
    @kind == :newline
  end

  #
  # Attempts to conver the token to an integer.
  #
  def to_i
    case @kind
    when :integer_lit, :integer_exp_lit, :single_string_lit, :double_string_lit
      @value.to_i
    when :float_lit, :float_exp_lit
      @value.to_f.to_i
    when :hex_lit
      @value.to_i(16)
    when :bin_lit
      @value.to_i(2)
    else
      raise TypeError, "Cannot convert this token to an integer"
    end
  end

  #
  # Attempts to convert the token to a Float.
  #
  def to_f
    case @kind
    when :float_lit, :float_exp_lit,
         :integer_lit, :integer_exp_lit,
         :single_string_lit, :double_string_lit
      @value.to_f
    else
      self.to_i.to_f
    end
  end

  #
  # Returns the token's value.
  #
  def to_s
    @value
  end

  #
  # Returns a Hash of the token's attributes.
  #
  def to_hash
    {
      :kind   => @kind,
      :value  => @value,
      :from   => @from,
      :to     => :to,
      :line   => @position.line,
      :column => @position.column
    }
  end

  alias_method :to_h, :to_hash

end # class Token

end # class GT::Lexer
