permission_labels = {
  "church_memberships" => "Usuarios de iglesia",
  "roles" => "Roles",
  "members" => "Miembros",
  "ministries" => "Ministerios",
  "events" => "Eventos",
  "church_settings" => "Configuracion de iglesia",
  "occupations" => "Ocupaciones",
  "skills" => "Habilidades",
  "service_directory" => "Directorio de servicios"
}

action_labels = {
  "read" => "Leer",
  "create" => "Crear/editar",
  "manage" => "Administrar"
}

Permission::ASSIGNABLE_MODULE_KEYS.each_with_index do |module_key, module_index|
  Permission::ACTION_KEYS.each_with_index do |action_key, action_index|
    permission = Permission.find_or_initialize_by(module_key:, action_key:)
    permission.name = "#{permission_labels.fetch(module_key)} - #{action_labels.fetch(action_key)}"
    permission.position = (module_index * 100) + action_index
    permission.save!
  end
end

super_admin_email = ENV["SEED_SUPER_ADMIN_EMAIL"].presence
super_admin_password = ENV["SEED_SUPER_ADMIN_PASSWORD"].presence

if super_admin_email.present? && super_admin_password.present?
  super_admin = User.find_or_initialize_by(email: super_admin_email)
  super_admin.assign_attributes(
    first_name: ENV.fetch("SEED_SUPER_ADMIN_FIRST_NAME", "Super"),
    last_name: ENV.fetch("SEED_SUPER_ADMIN_LAST_NAME", "Admin"),
    platform_role: "super_admin",
    status: "active",
    password: super_admin_password,
    password_confirmation: super_admin_password
  )
  super_admin.save!

  puts "Seeded super admin: #{super_admin.email}"
else
  puts "Skipped super admin seed. Set SEED_SUPER_ADMIN_EMAIL and SEED_SUPER_ADMIN_PASSWORD to create it."
end
