require 'spec_helper'
require 'rails_helper'

describe Api::V1::UsersController, type: :controller do
  render_views

  context 'authentication' do
    it '-- request without identifier' do
      process :auth, method: :post
      expect(response.status).to eq 400
      expect(response).to match_response_schema('identifier_not_present')
    end

    it '-- successful request' do
      session_key = FactoryGirl.create(:session_key)
      user = FactoryGirl.create(:user)

      data = {}
      data[:email]      = user.email
      data[:password]   = '123456'

      process :auth, method: :post, params: {
          identifier: session_key.identifier,
          data: data.to_json
      }

      expect(response.status).to eq 200
      expect(response).to match_response_schema('users/create/auth')
    end
  end

  context 'index action' do
    it '-- request without identifier' do
      process :index, method: :get
      expect(response.status).to eq 400
      expect(response).to match_response_schema('identifier_not_present')
    end

    it '-- request without token' do
      session_key = FactoryGirl.create(:session_key)
      process :index, method: :get, params: {
          identifier: session_key.identifier
      }

      expect(response.status).to eq 403
    end

    it '-- get all users' do
      # generate users
      FactoryGirl.create(:user)
      FactoryGirl.create(:user)

      session_key = FactoryGirl.create(:session_key)
      token = FactoryGirl.create(:token)

      data = {}
      data[:token] = token.value

      process :index, method: :get, params: {
          identifier: session_key.identifier,
          data: data.to_json
      }

      result = JSON.parse(response.body, object_class: OpenStruct)

      expect(result.cipher_message.users.count).to eq 2
      expect(response.status).to eq 200
      expect(response).to match_response_schema('users/index')
    end

    it '-- search' do
      # generate users
      FactoryGirl.create(:user)
      FactoryGirl.create(:user)

      session_key = FactoryGirl.create(:session_key)
      token = FactoryGirl.create(:token)

      data = {}
      data[:token] = token.value
      data[:query] = 'first_name'

      process :index, method: :get, params: {
          identifier: session_key.identifier,
          data: data.to_json
      }

      result = JSON.parse(response.body, object_class: OpenStruct)

      expect(result.cipher_message.users.count).to eq 2
      expect(response.status).to eq 200
      expect(response).to match_response_schema('users/index')
    end
  end

  context 'device tokens' do
    it '-- successful request' do
      user = FactoryGirl.create(:user, :with_token)
      session_key = FactoryGirl.create(:session_key)

      data = {}
      data[:token] = user.token
      data[:value] = 'example'
      data[:type]  = 'google'

      process :device_token, method: :post, params: {
          identifier: session_key.identifier,
          data: data.to_json
      }

      expect(response.status).to eq 200
    end

    it '-- without token' do
      user = FactoryGirl.create(:user, :with_token)
      session_key = FactoryGirl.create(:session_key)

      data = {}
      data[:value] = 'example'
      data[:type]  = 'google'

      process :device_token, method: :post, params: {
          identifier: session_key.identifier,
          data: data.to_json
      }

      expect(response.status).to eq 403
    end

    it '-- without value' do
      user = FactoryGirl.create(:user, :with_token)
      session_key = FactoryGirl.create(:session_key)

      data = {}
      data[:token] = user.token
      data[:type]  = 'google'

      process :device_token, method: :post, params: {
          identifier: session_key.identifier,
          data: data.to_json
      }

      expect(response.status).to eq 400
    end

    it '-- without type' do
      user = FactoryGirl.create(:user, :with_token)
      session_key = FactoryGirl.create(:session_key)

      data = {}
      data[:token] = user.token
      data[:value]  = 'example'

      process :device_token, method: :post, params: {
          identifier: session_key.identifier,
          data: data.to_json
      }

      expect(response.status).to eq 400
    end

    it '-- without type & token' do
      user = FactoryGirl.create(:user, :with_token)
      session_key = FactoryGirl.create(:session_key)

      data = {}
      data[:token] = user.token

      process :device_token, method: :post, params: {
          identifier: session_key.identifier,
          data: data.to_json
      }

      expect(response.status).to eq 400
    end


    it '-- with not valid type' do
      user = FactoryGirl.create(:user, :with_token)
      session_key = FactoryGirl.create(:session_key)

      data = {}
      data[:token] = user.token
      data[:value] = 'example'
      data[:type]  = 'not valid'

      process :device_token, method: :post, params: {
          identifier: session_key.identifier,
          data: data.to_json
      }

      expect(response.status).to eq 400
    end
  end
end
