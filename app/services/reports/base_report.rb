module Reports
  class BaseReport
    attr_reader :church, :filters

    def initialize(church:, filters: {})
      @church = church
      @filters = (filters || {}).to_h.with_indifferent_access
    end

    # [{ key: :symbol, label: "Encabezado" }, ...]
    def columns
      raise NotImplementedError, "#{self.class} debe implementar #columns"
    end

    # Enumerable de hashes { key => valor }, ya scopeado por church
    def rows
      raise NotImplementedError, "#{self.class} debe implementar #rows"
    end

    # Base del nombre de archivo, sin extensión ni fecha
    def filename
      raise NotImplementedError, "#{self.class} debe implementar #filename"
    end

    def title
      raise NotImplementedError, "#{self.class} debe implementar #title"
    end
  end
end
