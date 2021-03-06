# frozen_string_literal: true

RSpec.describe RuboCop::AST::SymbolNode do
  subject(:sym_node) { parse_source(source).ast }

  describe '.new' do
    context 'with a symbol node' do
      let(:source) do
        ':foo'
      end

      it { is_expected.to be_a(described_class) }
    end
  end

  describe '#value' do
    let(:source) do
      ':foo'
    end

    it { expect(sym_node.value).to eq(:foo) }
  end
end
