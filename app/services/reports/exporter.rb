require "csv"

module Reports
  class Exporter
    def initialize(report)
      @report = report
    end

    def to_csv
      CSV.generate do |csv|
        csv << @report.columns.map { |col| col[:label] }
        @report.rows.each do |row|
          csv << @report.columns.map { |col| row[col[:key]] }
        end
      end
    end

    def to_xlsx
      package = Axlsx::Package.new
      package.workbook.add_worksheet(name: sheet_name) do |sheet|
        sheet.add_row(@report.columns.map { |col| col[:label] })
        @report.rows.each do |row|
          sheet.add_row(@report.columns.map { |col| row[col[:key]] })
        end
      end
      package.to_stream.read
    end

    private

    def sheet_name
      @report.title.to_s.first(31).presence || "Reporte"
    end
  end
end
