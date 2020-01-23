require_relative 'report'

module ReportPortal
  module Cucumber
    class Formatter
      # @api private
      def initialize(config)
        ENV['REPORT_PORTAL_USED'] = 'true'

        @thread = Thread.new do
          initialize_report
          loop do
            method_arr = queue.pop
            report.public_send(*method_arr)
          end
        end
        if @thread.respond_to?(:report_on_exception) # report_on_exception defined only on Ruby 2.4 +
          @thread.report_on_exception = true
        else
          @thread.abort_on_exception = true
        end

        @io = config.out_stream

        handle_cucumber_events(config)
      end

      def puts(message)
        queue.push([:puts, message, ReportPortal.now])
        @io.puts(message)
        @io.flush
      end

      def embed(*args)
        queue.push([:embed, *args, ReportPortal.now])
      end

      private

      def queue
        @queue ||= Queue.new
      end

      def initialize_report
        @report = ReportPortal::Cucumber::Report.new
      end

      attr_reader :report

      def handle_cucumber_events(config)
        [:test_case_started, :test_case_finished, :test_step_started, :test_step_finished].each do |event_name|
          config.on_event(event_name) do |event|
            queue.push([event_name, event, ReportPortal.now])
          end
        end
        config.on_event :test_run_finished, &method(:on_test_run_finished)
      end

      def on_test_run_finished(_event)
        queue.push([:done, ReportPortal.now])
        sleep 0.03 while !queue.empty? || queue.num_waiting == 0 # TODO: how to interrupt launch if the user aborted execution
        @thread.kill
      end

      def process_message(report_method_name, *method_args)
        args = [report_method_name, *method_args, ReportPortal.now]
        if use_same_thread_for_reporting?
          report.public_send(*args)
        else
          @queue.push(args)
        end
      end

      def use_same_thread_for_reporting?
        ReportPortal::Settings.instance.formatter_modes.include?('use_same_thread_for_reporting')
      end
    end
  end
end
