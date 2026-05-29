module ChurchAdmin
  class ReportsController < BaseController
    def index
      authorize ReportPolicy, :index?, policy_class: ReportPolicy
      @registry = Reports::Registry::REGISTRY
      @category_labels = Reports::Registry::CATEGORY_LABELS
    end

    def show
      authorize ReportPolicy, :show?, policy_class: ReportPolicy

      entry = Reports::Registry::REGISTRY[params[:report]]
      raise ActiveRecord::RecordNotFound if entry.nil?

      @report = entry[:class].new(church: @church, filters: report_filters)

      respond_to do |format|
        format.html { @rows = @report.rows }
        format.csv  { export(:to_csv, "text/csv") }
        format.xlsx { export(:to_xlsx, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet") }
      end
    end

    private

    def export(method, content_type)
      authorize ReportPolicy, :export?, policy_class: ReportPolicy

      data = Reports::Exporter.new(@report).public_send(method)
      audit_export(method)

      extension = method == :to_csv ? "csv" : "xlsx"
      send_data data,
        type: content_type,
        filename: "#{@report.filename}-#{Date.current.iso8601}.#{extension}",
        disposition: "attachment"
    end

    def audit_export(method)
      object_json = {
        report: params[:report],
        format: method == :to_csv ? "csv" : "xlsx",
        filters: report_filters,
        church_id: @church.id
      }.to_json

      ActiveRecord::Base.connection.execute(
        ActiveRecord::Base.sanitize_sql_array([
          "INSERT INTO versions (event, item_type, item_id, whodunnit, object, created_at) VALUES (?, ?, ?, ?, ?, ?)",
          "export", "Report", @church.id, current_user.id.to_s, object_json, Time.current
        ])
      )
      Rails.logger.info(
        "[report_export] church=#{@church.id} user=#{current_user.id} report=#{params[:report]} format=#{method}"
      )
    end

    def report_filters
      params.permit(:status, :month, :ministry_id, :occupation_id, :skill_id, :event_id).to_h
    end
  end
end
