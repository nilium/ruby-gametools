module GT ; end

# Keep Lexer constants and such in scope
class GT::Lexer

class Token

  LITERAL_KEYWORDS = {
    :true_kw           => "true",
    :false_kw          => "false",
    :null_kw           => "null"
  }

  KEYWORDS = {}.merge!(LITERAL_KEYWORDS)

  LITERALS = {
    :integer_lit       => "integer",
    :float_lit         => "float",
    :integer_exp_lit   => "integer exp",
    :float_exp_lit     => "float exp",
    :hex_lit           => "hexnum lit",
    :bin_lit           => "binary lit",
    :single_string_lit => "'...' string",
    :double_string_lit => "\"...\" string"
  }.merge(LITERAL_KEYWORDS)

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
  }

  DESCRIPTORS = {
    :invalid           => "invalid",
    :newline           => "\\n",
    :id                => "identifier",
    :line_comment      => "// comment",
    :block_comment     => "/* comment */"
  }.merge!(PUNCTUATION).merge!(LITERALS)

  attr_accessor :kind
  attr_accessor :position
  attr_accessor :from
  attr_accessor :to
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
    @value    = value || ''
  end

  def descriptor
    DESCRIPTORS[@kind]
  end

  def id?
    @kind == :id
  end

  def boolean?
    @kind == :true_kw || @kind == :false_kw
  end

  def null?
    @kind == :null_kw
  end

  def literal?
    LITERALS.include? @kind
  end

  def integer?
    @kind == :integer_lit || @kind == :integer_exp_lit || @kind == :hex_lit || @kind == :bin_lit
  end

  def float?
    @kind == :float_lit || @kind == :float_exp_lit
  end

  def string?
    @kind == :double_string_lit || @kind == :single_string_lit
  end

  def comment?
    @kind == :line_comment || @kind == :block_comment
  end

  def punctuation?
    PUNCTUATION.include? @kind
  end

  def newline?
    @kind == :newline
  end

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

  def to_s
    @value
  end

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
