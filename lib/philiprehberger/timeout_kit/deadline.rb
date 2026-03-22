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

      # Create a new deadline.
      #
      # @param seconds [Numeric] the number of seconds until the deadline expires
      def initialize(seconds)
        @expires_at = now + seconds
      end

      # Check whether the deadline has expired.
      #
      # @raise [DeadlineExceeded] if the deadline has passed
      # @return [void]
      def check!
        raise DeadlineExceeded, "Deadline exceeded" if expired?
      end

      # Return the remaining time in seconds.
      #
      # @return [Float] seconds remaining (0.0 if expired)
      def remaining
        r = @expires_at - now
        r.negative? ? 0.0 : r
      end

      # Whether the deadline has expired.
      #
      # @return [Boolean]
      def expired?
        now >= @expires_at
      end

      private

      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
