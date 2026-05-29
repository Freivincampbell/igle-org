# Clase virtual para registrar exportaciones de reportes en PaperTrail.
# No corresponde a una tabla de base de datos.
class Report
  include ActiveModel::Model

  def self.current_scope
    nil
  end

  def self.model_name
    ActiveModel::Name.new(self)
  end
end
