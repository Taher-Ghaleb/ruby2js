require 'ruby2js'

# Note care is taken to run all the filters first before camelCasing.
# This ensures that Ruby methods like each_pair can be mapped to
# JavaScript before camelcasing.

module Ruby2JS
  module Filter
    module CamelCase
      include SEXP

      WHITELIST = %w{
        attr_accessor
      }

      def camelCase(symbol)
        symbol.to_s.gsub(/(?!^)_[a-z0-9]/) {|match| match[1].upcase}
      end

      def on_send(node)
        node = super
        return if node.type != :send and node.type != :csend

        if node.children[0] == nil and WHITELIST.include? node.children[1].to_s
          node
        elsif node.children[1] =~ /_.*\w[=!?]?$/
          S(node.type, node.children[0],
            camelCase(node.children[1]), *node.children[2..-1])
        else
          node
        end
      end
      
      def on_csend(node)
        on_send(node)
      end

      def on_def(node)
        node = super
        return if node.type != :def

        if node.children[0] =~ /_.*\w$/
          S(:def , camelCase(node.children[0]), *node.children[1..-1])
        else
          node
        end
      end

      def on_optarg(node)
        node = super
        return if node.type != :optarg

        if node.children[0] =~ /_.*\w$/
          S(:optarg , camelCase(node.children[0]), *node.children[1..-1])
        else
          node
        end
      end

      def on_lvar(node)
        node = super
        return if node.type != :lvar

        if node.children[0] =~ /_.*\w$/
          S(:lvar , camelCase(node.children[0]), *node.children[1..-1])
        else
          node
        end
      end

      def on_arg(node)
        node = super
        return if node.type != :arg

        if node.children[0] =~ /_.*\w$/
          S(:arg , camelCase(node.children[0]), *node.children[1..-1])
        else
          node
        end
      end

      def on_lvasgn(node)
        node = super
        return if node.type != :lvasgn

        if node.children[0] =~ /_.*\w$/
          S(:lvasgn , camelCase(node.children[0]), *node.children[1..-1])
        else
          node
        end
      end

      def on_sym(node)
        node = super
        return if node.type != :sym

        if node.children[0] =~ /_.*\w$/
          S(:sym , camelCase(node.children[0]), *node.children[1..-1])
        else
          node
        end
      end

      def on_defs(node)
        node = super
        return if node.type != :defs

        if node.children[1] =~ /_.*\w$/
          S(:defs , node.children[0],
            camelCase(node.children[1]), *node.children[2..-1])
        else
          node
        end
      end
    end

    DEFAULTS.push CamelCase
  end
end
