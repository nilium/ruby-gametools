require 'gametools/lexer/token'

module GT

  #
  # A class for reading tokens produced by GT::Lexer. Essentially a utility for
  # very simply parsing of tokens.
  #
  class TokenReader

    #
    # Whether to skip whitespace on read by default. This can be overridden in
    # read_token, though no other reading functions allow this. Defaults to
    # true.
    #
    attr_accessor :skip_whitespace_on_read

    #
    # Initializes a new TokenReader with a container of tokens or an enumerator.
    # tokens must respond to #each and return an enumerator if it is not already
    # an enumerator.
    #
    def initialize(tokens)
      @token_enum = tokens.kind_of?(Enumerator) ? tokens : tokens.each
      @current    = nil
      @skip_whitespace_on_read = true
    end

    #
    # Reads a token, optionally only reading the token if conditions are met. If
    # the read succeeds, the token is returned, otherwise either nil is returned
    # or an exception is thrown, depending on the +fail+ argument.
    #
    # If there are no more tokens to be read, a RuntimeError is thrown.
    #
    # === Arguments
    #
    # +kind+ and +kinds+::
    #   Single and plural token kinds to be matched -- if the next token in the
    #   reader does not match either kind or one of kinds (or both, if both are
    #   provided -- recommended you only provide either kind or kinds), the read
    #   fails.
    #
    # +hash+::
    #   The hash of a token's value to match. If the token's value.hash doesn't
    #   match, the read fails.
    #
    # +value+::
    #   If provided, compares the token's value and the provided value. If the
    #   two are not equal, the read fails.
    #
    # +skip_whitespace+::
    #   Overrides the value of skip_whitespace_on_read.
    #
    # +fail+::
    #   If non-nil and non-false, this is the argument or arguments to provide
    #   to Kernel#raise. By default, it simply raises a RuntimeError with a
    #   message saying the read failed.
    #
    def read_token(kind = nil,
                   kinds: nil,
                   hash: nil,
                   value: nil,
                   skip_whitespace: nil,
                   fail: [RuntimeError, "Failed to read token."])

      skip_whitespace = self.skip_whitespace_on_read if skip_whitespace.nil?
      self.skip_whitespace_tokens() if skip_whitespace

      @current = begin
        peeked = @token_enum.peek
        tok = case
              when kind && peeked.kind != kind then            nil
              when kinds && ! kinds.include?(peeked.kind) then nil
              when hash && peeked.value.hash != hash then      nil
              when value && peeked.value != value then         nil
              else @token_enum.next
              end
        if fail && tok.nil?
          case fail
          when Array then raise(*fail)
          else raise fail
          end
        end
        tok
      rescue StopIteration
        raise "Attempt to read past end of tokens"
      end
    end

    #
    # Reads a float literal token and returns the float value of the token read.
    #
    def read_float(hash: nil, fail: ["Expected float literal"])
      tok = read_token(kinds: %i[float_lit float_exp_lit integer_lit integer_exp_lit hex_lit bin_lit], hash: hash, fail: fail)
      tok && tok.to_f
    end

    #
    # Reads an integer literal token and returns the integer value of the token
    # read.
    #
    def read_integer(hash: nil, fail: ["Expected integer literal"])
      tok = read_token(kinds: %i[integer_lit integer_exp_lit hex_lit bin_lit], hash: hash, fail: fail)
      tok && tok.to_i
    end

    #
    # Reads a boolean literal token and returns the boolean value of the token
    # read.
    #
    def read_boolean(hash: nil, fail: ["Expected boolean literal"])
      tok = read_token(kinds: %i[true_kw false_kw], hash: hash, fail: fail)
      tok && tok.kind == :true_kw
    end

    #
    # Reads a string literal token and returns the string value of the token
    # read.
    #
    def read_string(hash: nil, fail: ["Expected string literal"])
      tok = read_token(kinds: %i[single_string_lit double_string_lit], hash: hash, fail: fail)
      tok && tok.value
    end

    #
    # call-seq:
    #   current => Token or nil
    #
    # Returns the current token -- this is the token last returned by
    # read_token.
    #
    def current
      @current
    end

    #
    # call-seq:
    #   peek => Token or nil
    #
    # Peeks the next token from the TokenReader and returns it. If there are no
    # more tokens, returns nil.
    #
    def peek
      begin
        @token_enum.peek
      rescue StopIteration
        nil
      end
    end

    #
    # call-seq:
    #   peek_kind => sym or nil
    #
    # Peeks the next token's kind from the TokenReader and returns it. If there
    # are no more tokens, returns nil.
    #
    def peek_kind
      begin
        @token_enum.peek.kind
      rescue StopIteration
        nil
      end
    end

    #
    # call-seq:
    #   next_is(*kinds, value: nil) => true or false or nil
    #
    # Returns whether the next token in the TokenReader is one of the given
    # kinds and optionally whether it has a specific value. Returns true or
    # false depending on whether the next token matches the criteria. Otherwise,
    # if there are no more tokens, it returns nil.
    #
    def next_is?(*kinds, value: nil)
      tok = peek()
      tok && kinds.include?(tok.kind) && (value.nil? || value == tok.value)
    end

    #
    # call-seq:
    #   skip_token => self
    #
    # Skips a token. Same as read_token with no options, except it returns self.
    #
    # If attempting to skip a token when there are no more tokens, a
    # RuntimeError will be thrown.
    #
    def skip_token
      @current = begin
        @token_enum.next
      rescue StopIteration
        raise "Attempt to skip token with no more tokens"
      end
      self
    end

    #
    # Skips a certain number of tokens or specific kinds of tokens, or a number
    # of a specific kind of tokens. In all cases, the method will end early if
    # there are no more tokens to read.
    #
    # === Arguments
    #
    # +count+::
    #   Skips +count+ number of tokens.
    #
    # +kinds+::
    #   Skips tokens until it encounters a token whose kind is not included in
    #   +kinds+.
    #
    # +count+ and +kinds+::
    #   Skips +count+ number of tokens until it encounters a token whose kind is
    #   not included in +kinds+.
    #
    def skip_tokens(count: nil, kinds: nil)
      if ! (count || kinds)
        raise ArgumentError, "Must provide at least count or kinds to skip_tokens"
      elsif kinds
        if count
          skip_token() until eof? || ! kinds.include?(peek_kind()) || (count -= 1) <= 0
        else
          skip_token() until eof? || ! kinds.include?(peek_kind())
        end
      elsif count
        skip_token() until eof? || (count -= 1) < 0
      end
      self
    end

    #
    # call-seq:
    #   skip_to_token(*kinds, through: false) => self
    #
    # Skips as many tokens as necessary until it finds a token of a kind
    # provided. If +through+ is true, it will skip the matching token as well.
    #
    def skip_to_token(*kinds, through: false)
      raise ArgumentError, "No token kinds provided" if kinds.empty?
      skip_token() until (tok = peek()).nil? || kinds.include?(tok.kind)
      skip_token() if through && ! eof?
      self
    end

    #
    # call-seq:
    #   skip_whitespace_tokens => self
    #
    # Skips newline tokens as well as comments. Comments aren't technically
    # whitespace, but they are basically empty space, so they're skipped as
    # well.
    #
    def skip_whitespace_tokens
      skip_tokens kinds: [:newline, :line_comment, :block_comment]
      self
    end

    #
    # call-seq:
    #   eof? => true or false
    #
    # Returns whether the TokenReader has run out of tokens.
    #
    def eof?
      peek() == nil
    end
  end

end