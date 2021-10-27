# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KeProject::Transforms::Locations::LocNameReverser do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  let(:input) do
    [
      {loc_name: 'bat'},
      {loc_name: nil},
      {loc_name: ''},
      {loc_name: 'pop'}
    ]
  end

  context 'when replace = false' do
    let(:transforms) do
      Kiba.job_segment do
        transform KeProject::Transforms::Locations::LocNameReverser, replace: false
      end
    end

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
    let(:transforms) do
      Kiba.job_segment do
        transform KeProject::Transforms::Locations::LocNameReverser
      end
    end

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
