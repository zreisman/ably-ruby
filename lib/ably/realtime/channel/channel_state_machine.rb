require 'ably/modules/state_machine'

module Ably::Realtime
  class Channel
    # Internal class to manage channel state for {Ably::Realtime::Channel}
    #
    # @api private
    #
    class ChannelStateMachine
      include Ably::Modules::StateMachine

      # States supported by this StateMachine match #{Channel::STATE}s
      #   :initialized
      #   :attaching
      #   :attached
      #   :detaching
      #   :detached
      #   :failed
      Channel::STATE.each_with_index do |state_enum, index|
        state state_enum.to_sym, initial: index == 0
      end

      transition :from => :initialized,  :to => [:attaching]
      transition :from => :attaching,    :to => [:attached, :detaching, :failed]
      transition :from => :attached,     :to => [:detaching, :failed]
      transition :from => :detaching,    :to => [:detached, :attaching, :failed]
      transition :from => :failed,       :to => [:attaching]

      after_transition do |channel, transition|
        channel.synchronize_state_with_statemachine
      end

      after_transition(to: [:attaching]) do |channel|
        channel.manager.attach
      end

      before_transition(to: [:attached]) do |channel, current_transition|
        channel.manager.sync current_transition.metadata
      end

      after_transition(to: [:detaching]) do |channel, current_transition|
        channel.manager.detach current_transition.metadata
      end

      after_transition(to: [:detached]) do |channel, current_transition|
        channel.manager.emit_error current_transition.metadata if current_transition.metadata
      end

      after_transition(to: [:failed]) do |channel, current_transition|
        channel.manager.emit_error current_transition.metadata
      end

      # Transitions responsible for updating channel#error_reason
      before_transition(to: [:attached, :detached, :failed]) do |channel, current_transition|
        reason = current_transition.metadata if is_error_type?(current_transition.metadata)
        channel.set_failed_channel_error_reason reason
      end

      private
      def channel
        object
      end

      def logger
        channel.logger
      end
    end
  end
end