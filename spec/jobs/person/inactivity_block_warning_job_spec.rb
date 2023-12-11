# encoding: utf-8

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::InactivityBlockWarningJob do
  subject(:job) { described_class.new }
  subject(:people_scope) { job.people_scope(warning_period&.ago) }
  let!(:person) { people(:bottom_member) }
  let(:warning_period) { 18.months }
  before do
    allow(Settings).to receive_message_chain(:inactivity_block, :warning_after).and_return(warning_period.to_s)
    person.update(last_sign_in_at: (warning_period && warning_period.ago - 1.month),
                  inactivity_block_warning_sent_at: nil)
  end

  context 'with inactive person' do
    let(:block_service){ double("BlockService") }

    it 'sends the inactivity_block_warning' do
      expect(Person::BlockService).to receive(:new).with(person).and_return(block_service)
      expect(block_service).to receive(:inactivity_warning!)
      expect(people_scope).to include(person)
      expect(job.perform).to be_truthy
    end
  end

  context 'with already blocked person' do
    before { Person::BlockService.new(person).block! }

    it 'ignores person' do
      expect(Person::BlockService).not_to receive(:new)
      expect(people_scope).not_to include(person)
      expect(job.perform).to be_truthy
    end
  end

  context 'with active person' do
    before { person.touch(:last_sign_in_at) }

    it 'ignores person' do
      expect(Person::BlockService).not_to receive(:new)
      expect(people_scope).not_to include(person)
      expect(job.perform).to be_truthy
    end
  end

  context 'with warning already sent' do
    before { person.touch(:inactivity_block_warning_sent_at) }

    it 'ignores person' do
      expect(Person::BlockService).not_to receive(:new)
      expect(people_scope).not_to include(person)
      expect(job.perform).to be_truthy
    end
  end

  context 'with no warning_period set' do
    let(:warning_period) { nil }

    it 'returns early' do
      expect(Person::BlockService).not_to receive(:new)
      expect(job.perform).to be_falsy
    end
  end
end
