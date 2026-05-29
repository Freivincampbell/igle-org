class ServiceDirectoryPolicy < ApplicationPolicy
  def index?
    super_admin? || permission?("service_directory", "read")
  end
end
