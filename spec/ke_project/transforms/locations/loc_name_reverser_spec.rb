# frozen_string_literal: true

RSpec.describe KeProject::Transforms::Locations::LocNameReverser do
  subject(:xform){ described_class.new(**params) }

  describe '#process' do
    let(:result){ input.map{ |row| xform.process(row) } }
    let(:input) do
      [
        {loc_name: 'bat'},
        {loc_name: nil},
        {loc_name: ''},
        {loc_name: 'pop'}
      ]
    end

    context 'when replace = false' do
      let(:params){ {replace: false} }
      let(:expected) do
        [
          {loc_name: 'bat', loc_name_reversed: 'tab'},
          {loc_name: nil, loc_name_reversed: nil},
          {loc_name: '', loc_name_reversed: nil},
          {loc_name: 'pop', loc_name_reversed: 'pop'}
        ]
      end
      
      it 'cleans field as expected' do
        expect(result).to eq(expected)
      end
    end

    context 'when replace = true (the default)' do
      let(:params){ {} }
      let(:expected) do
        [
          {loc_name: 'tab'},
          {loc_name: nil},
          {loc_name: nil},
          {loc_name: 'pop'}
        ]
      end
      
      it 'cleans field as expected' do
        expect(result).to eq(expected)
      end
    end
  end
end
