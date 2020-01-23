require_relative 'formatter'
require_relative 'parallel_report'

module ReportPortal
  module Cucumber
    class ParallelFormatter < Formatter
      # @api private
      def initialize(config)
        @start_launch_time = ReportPortal.now
        super(config)
      end

      private

      def initialize_report
        @report = ReportPortal::Cucumber::ParallelReport.new(@start_launch_time)
      end
    end
  end
end
