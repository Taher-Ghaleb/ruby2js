# convert a JSX expression into wunderbar statements
#
# Once the syntax is converted to pure Ruby statements,
# it can then be converted into either React or Vue
# rendering instructions.

module Ruby2JS
  def self.jsx2_rb(string)
    state = :text
    text = ''
    result = []
    element = ''
    attrs = {}
    attr_name = ''
    attr_value = ''

    for c in string.chars
      case state
      when :text
        if c == '<'
          result << "_ #{text.strip.inspect}" unless text.strip.empty?
          state = :element
          element = ''
          attrs = {}
        else
          text += c
        end

      when :element
        if c == '/'
          if element == ''
            state = :close
            element = ''
          else
            state = :void
          end
        elsif c == '>'
          result << "_#{element} do"
          state = :text
          text = ''
        elsif c == ' '
          state = :attr_name
          attr_name = ''
          attrs = {}
        elsif c == '-'
          element += '_'
        elsif c =~ /^\w$/
          element += c
        else
          raise SyntaxError.new("invalid character in element name: #{c.inspect}")
        end

      when :close
        if c == '>'
          result << 'end'
          state = :text
          text = ''
        elsif c =~ /^\w$/
          element += c
        elsif c != ' '
          raise SyntaxError.new('invalid character in element: "/"')
        end

      when :void
        if c == '>'
          if attrs.empty?
            result << "_#{element}"
          else
            result << "_#{element} #{attrs.map {|name, value| "#{name}: #{value}"}.join(' ')}"
          end

          state = :text
          text = ''
        elsif c != ' '
          raise SyntaxError.new('invalid character in element: "/"')
        end

      when :attr_name
        if c =~ /^\w$/
          attr_name += c
        elsif c == '='
          state = :attr_value
          attr_value = ''
        elsif c == '/' and attr_name == ''
          state = :void
        elsif c == ' ' or c == '>'
          if not attr_name.empty?
            raise SyntaxError.new("missing \"=\" after attribute #{attr_name.inspect} " +
              "in element #{element.inspect}")
          elsif c == '>'
            result << "_#{element} #{attrs.map {|name, value| "#{name}: #{value}"}.join(' ')} do"
            state = :text
            text = ''
          end
        else
          raise SyntaxError.new("invalid character in attribute name: #{c.inspect}")
        end

      when :attr_value
        if c == '"'
          state = :dquote
        elsif c == "'"
          state = :squote
        elsif c == '{'
          state = :attr_expr
        else
          raise SyntaxError.new("invalid value for attribute #{attr_name.inspect} " +
            "in element #{element.inspect}")
        end

      when :dquote
        if c == '"'
          attrs[attr_name] = attr_value.inspect
          state = :attr_name
          attr_name = ''
        else
          attr_value += c
        end

      when :squote
        if c == "'"
          attrs[attr_name] = attr_value.inspect
          state = :attr_name
          attr_name = ''
        else
          attr_value += c
        end

      when :attr_expr
        if c == "}"
          attrs[attr_name] = attr_value
          state = :attr_name
          attr_name = ''
        else
          attr_value += c
        end

      else
        raise RangeError.new("internal state error in JSX: #{state.inspect}")
      end
    end

    case state
    when :text
      result << "_ #{text.strip.inspect}\n" unless text.strip.empty?
    end

    result.join("\n")
  end
end