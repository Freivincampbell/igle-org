class ReportPolicy < ApplicationPolicy
  def index?
    super_admin? || permission?("reports", "read")
  end

  def show?
    index?
  end

  def export?
    super_admin? || permission?("reports", "manage")
  end
end
