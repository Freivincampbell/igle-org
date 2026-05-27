require "rails_helper"

RSpec.describe "User sessions" do
  it "renders the login page" do
    get new_user_session_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Iniciar sesion")
  end

  it "logs an active user in" do
    user = create(:user, password: "password123", password_confirmation: "password123")

    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }

    expect(response).to redirect_to(root_path)
  end

  it "renders localized invalid credential errors" do
    post user_session_path, params: {
      user: {
        email: "missing@example.test",
        password: "wrong-password"
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Email o contrasena no validos.")
    expect(response.body).not_to include("Translation missing")
  end
end
