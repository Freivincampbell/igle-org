FactoryBot.define do
  factory :permission do
    sequence(:module_key) { |number| Permission::MODULE_KEYS[number % Permission::MODULE_KEYS.size] }
    sequence(:action_key) { |number| Permission::ACTION_KEYS[number % Permission::ACTION_KEYS.size] }
    name { "#{module_key} #{action_key}" }
    position { 0 }
  end
end
