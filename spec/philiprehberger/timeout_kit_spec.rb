# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::TimeoutKit do
  it 'has a version number' do
    expect(Philiprehberger::TimeoutKit::VERSION).not_to be_nil
  end

  describe '.deadline' do
    it 'yields a deadline context' do
      described_class.deadline(5) do |d|
        expect(d).to be_a(Philiprehberger::TimeoutKit::Deadline)
      end
    end

    it "returns the block's return value" do
      result = described_class.deadline(5) { 'done' }
      expect(result).to eq('done')
    end

    it 'provides remaining time' do
      described_class.deadline(5) do |d|
        expect(d.remaining).to be > 0
        expect(d.remaining).to be <= 5
      end
    end

    it 'check! does not raise before deadline' do
      described_class.deadline(5) do |d|
        expect { d.check! }.not_to raise_error
      end
    end

    it 'check! raises DeadlineExceeded after deadline' do
      expect do
        described_class.deadline(0.01) do |d|
          sleep 0.05
          d.check!
        end
      end.to raise_error(Philiprehberger::TimeoutKit::DeadlineExceeded)
    end

    it 'returns 0.0 remaining after deadline expires' do
      described_class.deadline(0.01) do |d|
        sleep 0.05
        expect(d.remaining).to eq(0.0)
      end
    end

    it 'reports expired? correctly' do
      described_class.deadline(0.01) do |d|
        expect(d.expired?).to be(false)
        sleep 0.05
        expect(d.expired?).to be(true)
      end
    end
  end

  describe 'nested deadlines' do
    it 'uses the tighter inner deadline' do
      described_class.deadline(10) do |outer|
        described_class.deadline(1) do |inner|
          expect(inner.remaining).to be <= 1
          expect(inner.remaining).to be < outer.remaining
        end
      end
    end

    it 'uses the tighter outer deadline when inner is longer' do
      described_class.deadline(1) do |_outer|
        described_class.deadline(10) do |effective|
          expect(effective.remaining).to be <= 1
        end
      end
    end

    it 'restores the outer deadline after inner completes' do
      described_class.deadline(5) do |_outer|
        described_class.deadline(1) { |_inner| nil }

        current = described_class.current_deadline
        expect(current.remaining).to be > 1
      end
    end
  end

  describe '.cooperative' do
    it 'yields a timeout context' do
      described_class.cooperative(5) do |t|
        expect(t).to be_a(Philiprehberger::TimeoutKit::Deadline)
      end
    end

    it "returns the block's return value" do
      result = described_class.cooperative(5) { 'result' }
      expect(result).to eq('result')
    end

    it 'check! does not raise before timeout' do
      described_class.cooperative(5) do |t|
        expect { t.check! }.not_to raise_error
      end
    end

    it 'check! raises DeadlineExceeded after timeout' do
      expect do
        described_class.cooperative(0.01) do |t|
          sleep 0.05
          t.check!
        end
      end.to raise_error(Philiprehberger::TimeoutKit::DeadlineExceeded)
    end

    it 'provides remaining time' do
      described_class.cooperative(5) do |t|
        expect(t.remaining).to be > 0
        expect(t.remaining).to be <= 5
      end
    end
  end

  describe '.current_deadline' do
    it 'returns nil when no deadline is active' do
      expect(described_class.current_deadline).to be_nil
    end

    it 'returns the current deadline inside a deadline block' do
      described_class.deadline(5) do |d|
        expect(described_class.current_deadline).to eq(d)
      end
    end

    it 'returns nil after the deadline block completes' do
      described_class.deadline(5) { |_d| nil }
      expect(described_class.current_deadline).to be_nil
    end
  end

  describe 'Deadline' do
    describe '#remaining' do
      it 'returns a value less than or equal to initial seconds' do
        dl = Philiprehberger::TimeoutKit::Deadline.new(10)
        expect(dl.remaining).to be <= 10
      end

      it 'returns a positive value for a fresh deadline' do
        dl = Philiprehberger::TimeoutKit::Deadline.new(10)
        expect(dl.remaining).to be > 0
      end
    end

    describe '#expired?' do
      it 'is false for a fresh deadline' do
        dl = Philiprehberger::TimeoutKit::Deadline.new(10)
        expect(dl.expired?).to be(false)
      end

      it 'is true for a zero-second deadline' do
        dl = Philiprehberger::TimeoutKit::Deadline.new(0)
        expect(dl.expired?).to be(true)
      end
    end

    describe '#check!' do
      it 'does not raise for a fresh deadline' do
        dl = Philiprehberger::TimeoutKit::Deadline.new(10)
        expect { dl.check! }.not_to raise_error
      end

      it 'raises DeadlineExceeded for an already-expired deadline' do
        dl = Philiprehberger::TimeoutKit::Deadline.new(0)
        expect { dl.check! }.to raise_error(Philiprehberger::TimeoutKit::DeadlineExceeded)
      end
    end

    describe '#expires_at' do
      it 'returns a numeric value' do
        dl = Philiprehberger::TimeoutKit::Deadline.new(5)
        expect(dl.expires_at).to be_a(Numeric)
      end

      it 'is greater than the current monotonic time for a fresh deadline' do
        before = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        dl = Philiprehberger::TimeoutKit::Deadline.new(5)
        expect(dl.expires_at).to be > before
      end
    end
  end

  describe 'error class hierarchy' do
    it 'DeadlineExceeded is a subclass of Error' do
      expect(Philiprehberger::TimeoutKit::DeadlineExceeded).to be < Philiprehberger::TimeoutKit::Error
    end

    it 'Error is a subclass of StandardError' do
      expect(Philiprehberger::TimeoutKit::Error).to be < StandardError
    end

    it 'DeadlineExceeded can be rescued as Error' do
      expect do
        raise Philiprehberger::TimeoutKit::DeadlineExceeded, 'test'
      rescue Philiprehberger::TimeoutKit::Error
        nil
      end.not_to raise_error
    end
  end

  describe '.deadline with zero timeout' do
    it 'expires immediately' do
      described_class.deadline(0) do |d|
        expect(d.expired?).to be(true)
        expect(d.remaining).to eq(0.0)
      end
    end

    it 'check! raises immediately' do
      expect do
        described_class.deadline(0, &:check!)
      end.to raise_error(Philiprehberger::TimeoutKit::DeadlineExceeded)
    end
  end

  describe '.deadline with very large timeout' do
    it 'does not expire during the test' do
      described_class.deadline(999_999) do |d|
        expect(d.expired?).to be(false)
        expect(d.remaining).to be > 999_990
      end
    end
  end

  describe '.deadline return value' do
    it 'returns a complex object from the block' do
      result = described_class.deadline(5) { { status: :ok, count: 42 } }
      expect(result).to eq({ status: :ok, count: 42 })
    end

    it 'returns nil when block returns nil' do
      result = described_class.deadline(5) { nil }
      expect(result).to be_nil
    end
  end

  describe '.cooperative with fast loop' do
    it 'allows multiple check! calls before timeout' do
      described_class.cooperative(5) do |t|
        10.times { t.check! }
        expect(t.expired?).to be(false)
      end
    end

    it 'tracks remaining time decreasing' do
      described_class.cooperative(5) do |t|
        first = t.remaining
        expect(t.remaining).to be <= first
      end
    end
  end

  describe 'nested deadlines (three levels)' do
    it 'uses the tightest constraint across three levels' do
      described_class.deadline(10) do |_outer|
        described_class.deadline(5) do |_mid|
          described_class.deadline(1) do |inner|
            expect(inner.remaining).to be <= 1
          end
        end
      end
    end
  end
end
