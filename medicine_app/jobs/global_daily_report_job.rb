class GlobalDailyReportJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Workflows::GlobalDailyReport.send_report
  end

end
