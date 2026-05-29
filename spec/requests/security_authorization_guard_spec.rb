require "rails_helper"

# Bloquea la defensa en profundidad de autorización: ApplicationController debe
# verificar Pundit en toda acción (verify_authorized) y el scope en index
# (verify_policy_scoped). Si alguien remueve estos callbacks, este spec falla.
RSpec.describe "Authorization defense-in-depth guard" do
  it "registra verify_authorized y verify_policy_scoped como after_action" do
    after_filters = ApplicationController._process_action_callbacks
      .select { |callback| callback.kind == :after }
      .map(&:filter)

    expect(after_filters).to include(:verify_authorized)
    expect(after_filters).to include(:verify_policy_scoped)
  end

  it "una acción index protegida pasa por policy_scope (no expone datos de otra iglesia)" do
    church_a = create(:church)
    church_b = create(:church)
    visible = create(:member, church: church_a, first_name: "VisibleA")
    hidden = create(:member, church: church_b, first_name: "OcultaB")
    membership = create(:church_membership, :owner, church: church_a)

    sign_in membership.user

    get church_admin_members_path(church_a)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(visible.full_name)
    expect(response.body).not_to include(hidden.full_name)
  end
end
