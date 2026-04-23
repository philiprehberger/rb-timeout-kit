# frozen_string_literal: true

module Philiprehberger
  module TimeoutKit
    # A cooperative deadline that tracks remaining time and supports nesting.
    #
    # Deadlines do not use Thread.raise. Instead, callers must explicitly
    # call {#check!} at safe cancellation points.
    class Deadline
      # @return [Float] the absolute monotonic time when the deadline expires
      attr_reader :expires_at

      # @return [String, nil] the human-readable name for this deadline
      attr_reader :name

      # Create a new deadline.
      #
      # @param seconds [Numeric] the number of seconds until the deadline expires
      # @param name [String, nil] optional human-readable name for the deadline
      # @param grace [Numeric, nil] optional grace period in seconds after the primary deadline
      # @param on_expire [Proc, nil] optional callback that fires once when expiry is detected
      def initialize(seconds, name: nil, grace: nil, on_expire: nil)
        @started_at = now
        @expires_at = @started_at + seconds
        @name = name
        @grace_seconds = grace
        @grace_expires_at = @grace_seconds ? @expires_at + @grace_seconds : nil
        @on_expire = on_expire
        @expire_callback_fired = false
      end

      # Register a callback that fires once when expiry is detected.
      #
      # @yield the block to call on expiry
      # @return [void]
      def on_expire(&block)
        @on_expire = block
      end

      # Check whether the deadline has expired.
      #
      # @raise [DeadlineExceeded] if the deadline has passed (and grace period, if any, has also passed)
      # @return [void]
      def check!
        return unless expired?

        fire_expire_callback

        # If we have a grace period and are still within it, don't raise
        return if in_grace?

        message = @name ? "Deadline '#{@name}' exceeded" : 'Deadline exceeded'
        raise DeadlineExceeded, message
      end

      # Return the remaining time in seconds until the primary deadline.
      # Can be negative during the grace period.
      #
      # @return [Float] seconds remaining (negative if past primary deadline)
      def remaining
        r = @expires_at - now
        if @grace_seconds
          r
        else
          r.negative? ? 0.0 : r
        end
      end

      # Return the number of seconds elapsed since the deadline was created.
      # This is a pure wall-clock reading from the monotonic clock and continues
      # to increase past the original budget after expiration. Independent of
      # {#expired?} and {#in_grace?}.
      #
      # @return [Float] seconds elapsed since creation
      def elapsed
        now - @started_at
      end

      # Return the remaining time in the grace period.
      #
      # @return [Float] seconds remaining in grace period (0.0 if no grace period or grace expired)
      def grace_remaining
        return 0.0 unless @grace_expires_at

        r = @grace_expires_at - now
        r.negative? ? 0.0 : r
      end

      # Whether the primary deadline has expired.
      #
      # @return [Boolean]
      def expired?
        now >= @expires_at
      end

      # Whether the deadline is currently in the grace period.
      # True only when the primary deadline has expired but the grace period has not.
      #
      # @return [Boolean]
      def in_grace?
        return false unless @grace_expires_at

        expired? && now < @grace_expires_at
      end

      private

      def fire_expire_callback
        return if @expire_callback_fired || @on_expire.nil?

        @expire_callback_fired = true
        @on_expire.call
      end

      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
