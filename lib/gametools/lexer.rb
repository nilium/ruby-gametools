module GT ; end
class GT::Lexer ; end

require 'gametools/lexer/token'
require 'gametools/lexer/position'

#
# A simple string lexer.
#
class GT::Lexer

  #
  # Punctuation string hash. Based on Token::PUNCTUATION.
  #
  PUNCTUATION_STRINGS = Token::PUNCTUATION.invert

  #
  #---
  # This assumes little endian, so it might be necessary to adjust for big
  # endian systems.
  #+++
  @@Marker = Struct.new(:token_index, :source_index, :character, :position)

  attr_reader :tokens
  attr_reader :error

  def self.isxdigit(char)
    ('0' <= char && char <= '9') ||
    ('a' <= char && char <= 'f') ||
    ('A' <= char && char <= 'F')
  end

  def initialize
    @reader        = nil
    @skip_comments = false
    @skip_newlines = false
    @at_end        = false
    reset()
  end

  def reset()
    @error  = nil
    @marker = @@Marker[
      0,    # token_index
      -1,   # source_index
      ?\0,  # character
      Position[1, 0] # position
    ]
    @tokens = []
  end

  def run(source, until_token = :invalid, token_count = nil)
    @at_end = false
    @source = source
    @reader = source.each_char

    read_next()

    while token_count == nil || token_count > 0
      skip_whitespace()
      current = @marker.character
      break unless current

      token          = Token.new
      token.kind     = :invalid
      token.from     = @marker.source_index
      token.position = @marker.position.dup

      case current
      when ?", ?'
        read_string(token)

      when ?0
        case peek_next()
        when ?x, ?X, ?b, ?B then read_base_number(token)
        else                     read_number(token)
        end

      when ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9
        read_number(token)

      # dot, double dot, triple dot, and floats beginning with a dot
      when ?.
        token.kind = :dot
        case peek_next()
        when ?0, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9 then read_number(token)
        when ?.
          read_next()
          token.kind = :double_dot

          if peek_next() == ?.
            read_next()
            token.kind = :triple_dot
          end

          token.value = Token::DESCRIPTORS[token.kind]
        else
          token.value = Token::DESCRIPTORS[token.kind]
        end

      when ?_, ?a, ?b, ?c, ?d, ?e, ?f, ?g, ?h, ?i, ?j, ?k, ?l, ?m, ?n, ?o, ?p,
        ?q, ?r, ?s, ?t, ?u, ?v, ?w, ?x, ?y, ?z, ?A, ?B, ?C, ?D, ?E, ?F, ?G, ?H,
        ?I, ?J, ?K, ?L, ?M, ?N, ?O, ?P, ?Q, ?R, ?S, ?T, ?U, ?V, ?W, ?X, ?Y, ?Z
        read_word(token)

      when ?\n
        token.value = current
        token.kind = :newline

      when ??, ?#, ?@, ?$, ?%, ?(, ?), ?[, ?], ?{, ?}, ?^, ?~, ?`, ?\\, ?,, ?;
        token.value = current
        token.kind = PUNCTUATION_STRINGS[current]

      when ?=, ?|, ?&, ?:, ?+, ?*
        current << read_next() if peek_next() == current
        token.value = current
        token.kind = PUNCTUATION_STRINGS[current]

      when ?!
        current << read_next() if peek_next() == ?=
        token.value = current
        token.kind = PUNCTUATION_STRINGS[current]

      when ?>, ?<
        case peek_next()
        when ?=, current then current << read_next()
        end
        token.value = current
        token.kind = PUNCTUATION_STRINGS[current]

      when ?-
        case peek_next()
        when ?>, current then current << read_next()
        end
        token.value = current
        token.kind = PUNCTUATION_STRINGS[current]

      when ?/
        case peek_next()
        when ?/ then read_line_comment(token)
        when ?* then read_block_comment(token)
        else
          token.value = Token::DESCRIPTORS[token.kind = :slash]
          read_next()
        end

      end # case current

      token.to = @marker.source_index
      last_kind = token.kind
      if !(@skip_comments && token.comment?) && !(@skip_newlines && token.newline?)
        if last_kind != :invalid
          @tokens << token
          yield token if block_given?
        else
          raise RuntimeError, "#{token.position} Invalid token: #{token.inspect}"
        end
      end

      break if until_token == last_kind

      read_next()
      token_count -= 1 unless token_count.nil?
    end # while current && token_count > 0

    @source = nil
    @reader = nil

    self
  end

  def skip_comments?
    @skip_comments
  end

  def skip_comments=(bool)
    @skip_comments = bool
  end

  def skip_newlines?
    @skip_newlines
  end

  def skip_newlines=(bool)
    @skip_newlines = bool
  end


  private

  def peek_next()
    return nil if @at_end

    begin
      @reader.peek
    rescue StopIteration
      nil
    end
  end

  def read_next()
    return nil if @at_end

    begin
      pos = @marker.position

      if @marker.character == ?\n
        pos.line += 1
        pos.column = 0
      end

      @marker.character = @reader.next
      @marker.source_index += 1
      pos.column += 1
    rescue StopIteration
      @at_end = true
      @marker.character = nil
    end

    @marker.character
  end

  def skip_whitespace()
    current = @marker.character
    (current = read_next()) while current == ' ' || current == ?\t || current == ?\r
  end

  DOT_TOKENS = [:dot, :double_dot, :triple_top]

  def read_base_number(token)
    current = read_next()

    case current
    when ?b, ?B
      token.kind = :bin_lit
      read_next() while (current = peek_next()) == ?1 || current == ?0
    when ?x, ?X
      token.kind = :hex_lit
      read_next() while self.class::isxdigit(current = peek_next())
    end

    token.value = @source[(token.from .. @marker.source_index)]
  end

  def read_number(token)
    current = @marker.character
    is_float = current == ?.
    is_exponent = false
    token.kind = is_float ? :float_lit : :integer_lit

    while (current = peek_next())
      case current
      # Float lit
      when ?.
        break if is_float == true
        is_float = true
        token.kind = :float_lit
        read_next()

      # Digit
      when ?0, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9
        read_next()

      # Exponent
      when ?e, ?E
        if is_exponent
          token.kind = :invalid
          raise_error(:duplicate_exponent,
            "Malformed number literal: exponent already provided")
        end

        is_exponent = true
        token.kind = is_float ? :float_exp_lit : :integer_exp_lit

        read_next()
        current = read_next()
        current = read_next() if current == ?- || current == ?+

        if current < ?0 || current > ?9
          raise_error(:malformed_exponent, "Malformed number literal: exponent expected but not provided")
        end

      else break
      end
    end

    token.value = @source[(token.from .. @marker.source_index)]
  end

  def read_word(token)
    while (current = peek_next())
      break unless current == '_' ||
        ('0' <= current && current <= '9') ||
        ('a' <= current && current <= 'z') ||
        ('A' <= current && current <= 'Z')
      read_next()
    end

    token.value = @source[token.from .. @marker.source_index]

    token.kind = case token.value
    when 'true'  then :true_kw
    when 'false' then :false_kw
    when 'null'  then :null_kw
    else              :id
    end
  end

  def read_string(token)
    opening_char = @marker.character
    token.kind = case opening_char
    when ?' then :single_string_lit
    when ?" then :double_string_lit
    end

    escape = false
    chars = []

    while current = read_next()
      if escape
        current = case current
        when ?x, ?X
          # unicode hex escape
          peeked = peek_next()
          if !self.class::isxdigit(peeked)
            raise_error(:malformed_unicode_escape,
              "Malformed unicode literal in string - no hex code provided.")
          end

          hexnums = current == ?x ? 4 : 8

          current = 0
          begin
            current = current << 4 | (case peeked
              when ?A, ?a then 0xA
              when ?B, ?b then 0xB
              when ?C, ?c then 0xC
              when ?D, ?d then 0xD
              when ?E, ?e then 0xE
              when ?F, ?f then 0xF
              when ?0 then 0x0
              when ?1 then 0x1
              when ?2 then 0x2
              when ?3 then 0x3
              when ?4 then 0x4
              when ?5 then 0x5
              when ?6 then 0x6
              when ?7 then 0x7
              when ?8 then 0x8
              when ?9 then 0x9
              end)
            read_next()
            peeked = peek_next()
            hexnums -= 1
          end while self.class::isxdigit(peeked) && hexnums > 0
          current.chr(Encoding::UTF_8)

        when ?r then ?\r
        when ?n then ?\n
        when ?t then ?\t
        when ?0 then ?\0
        when ?b then ?\b
        when ?a then ?\a
        when ?f then ?\f
        when ?v then ?\v
        else         current
        end
        escape = false
      else
        if current == opening_char
          break
        elsif current == ?\\
          escape = true
          next
        end
      end

      chars << current
    end

    raise_error(:unterminated_string, "Unterminated string") if !current

    token.value = chars.join('')
  end

  def read_line_comment(token)
    token.kind = :line_comment
    read_next() while (current = peek_next()) && current != ?\n
    token.value = @source[token.from .. @marker.source_index] if !@skip_comments
  end

  def read_block_comment(token)
    token.kind = :block_comment

    read_next()
    while (current = read_next())
      if current == ?* && peek_next() == ?/
        current = read_next()
        break
      end
    end

    raise_error(:unterminated_block_comment, "Unterminated block comment") if !current
    token.value = @source[token.from .. @marker.source_index] if !@skip_comments
  end

  def raise_error(code, error, position = nil)
    position ||= @marker.position
    @error = {
      :code => code,
      :description => error,
      :position => position.dup()
    }
    raise "#{position} (#{code}) #{error}"
  end

end
