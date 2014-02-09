# frozen_string_literal: true

module Philiprehberger
  module TimeoutKit
    class Error < StandardError; end

    # Raised when a deadline or cooperative timeout expires.
    class DeadlineExceeded < Error; end

    # Execute a block with a deadline. The block receives a {Deadline} object
    # that can be used to check remaining time and whether the deadline has passed.
    #
    # Deadlines can be nested. The innermost deadline is always the tightest
    # constraint, but outer deadlines are also checked.
    #
    # @param seconds [Numeric] the number of seconds for the deadline
    # @yield [deadline] the block to execute within the deadline
    # @yieldparam deadline [Deadline] the deadline context
    # @return the block's return value
    # @raise [DeadlineExceeded] if the deadline is exceeded and {Deadline#check!} is called
    def self.deadline(seconds, &block)
      dl = Deadline.new(seconds)

      # Support nested deadlines: use the tightest constraint
      parent = current_deadline
      effective = if parent && parent.expires_at < dl.expires_at
                   parent
                 else
                   dl
                 end

      push_deadline(effective)
      begin
        block.call(effective)
      ensure
        pop_deadline
      end
    end

    # Execute a block with a cooperative timeout. The block receives a timeout
    # context that can be checked at safe cancellation points.
    #
    # Unlike {.deadline}, this is a simpler wrapper that does not support nesting.
    #
    # @param seconds [Numeric] the number of seconds for the timeout
    # @yield [timeout] the block to execute within the timeout
    # @yieldparam timeout [Deadline] a deadline-like context for checking timeout
    # @return the block's return value
    # @raise [DeadlineExceeded] if the timeout is exceeded and {Deadline#check!} is called
    def self.cooperative(seconds)
      dl = Deadline.new(seconds)
      yield dl
    end

    # Return the current innermost deadline, or nil if none is active.
    #
    # @return [Deadline, nil]
    def self.current_deadline
      stack = Thread.current[:philiprehberger_timeout_kit_deadlines]
      stack&.last
    end

    # @api private
    def self.push_deadline(deadline)
      Thread.current[:philiprehberger_timeout_kit_deadlines] ||= []
      Thread.current[:philiprehberger_timeout_kit_deadlines].push(deadline)
    end
    private_class_method :push_deadline

    # @api private
    def self.pop_deadline
      stack = Thread.current[:philiprehberger_timeout_kit_deadlines]
      stack&.pop
      Thread.current[:philiprehberger_timeout_kit_deadlines] = nil if stack&.empty?
    end
    private_class_method :pop_deadline
  end
end

require_relative "timeout_kit/version"
require_relative "timeout_kit/deadline"
