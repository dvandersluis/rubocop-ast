# frozen_string_literal: true

require 'rainbow'

module RuboCop
  module AST
    class NodePattern
      class Compiler
        # Variant of the Compiler with tracing information for nodes
        class Debug < Compiler
          attr_reader :trace, :node_ids

          # @api private
          Colorizer = Struct.new(:compiler) do # rubocop:disable Metrics/BlockLength
            def colorize(ast, color_map: self.color_map(ast))
              ast.loc.expression.source_buffer.source.chars.map.with_index do |char, i|
                Rainbow(char).color((color_map[i] || COLORS[:not_visitable]))
              end.join
            end

            def color_map(ast)
              ast.each_descendant
                 .map { |node| color_map_for(node) }
                 .inject(color_map_for(ast), :merge)
            end

            private

            COLORS = {
              not_visited: :yellow,
              not_visitable: :lightseagreen,
              nil => :red,
              true => :green
            }.freeze

            def color_map_for(node)
              return {} unless (range = node.loc&.expression)

              color = COLORS.fetch(visited(node))
              range.to_a.to_h { |char| [char, color] }
            end

            def visited(node)
              id = compiler.node_ids.fetch(node) { return :not_visitable }
              return :not_visited unless compiler.trace[:enter][id]

              compiler.trace[:success][id]
            end
          end
          def initialize
            super
            @node_ids = Hash.new { |h, k| h[k] = h.size }.compare_by_identity
            @trace = { enter: {}, success: {} }
          end

          def named_parameters
            super << :trace
          end

          def parser
            Parser::WithMeta
          end

          # @api private
          module InstrumentationSubcompiler
            def do_compile
              "#{tracer(:enter)} && #{super} && #{tracer(:success)}"
            end

            private

            def tracer(kind)
              id = compiler.node_ids[node]
              "(trace[:#{kind}][#{id}] ||= true)"
            end
          end

          # @api private
          class NodePatternSubcompiler < Compiler::NodePatternSubcompiler
            include InstrumentationSubcompiler
          end

          # @api private
          class SequenceSubcompiler < Compiler::SequenceSubcompiler
            include InstrumentationSubcompiler
          end
        end
      end
    end
  end
end
