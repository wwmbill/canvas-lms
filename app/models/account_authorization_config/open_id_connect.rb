#
# Copyright (C) 2015 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class AccountAuthorizationConfig::OpenIDConnect < AccountAuthorizationConfig::Oauth2
  def self.sti_name
    self == OpenIDConnect ? 'openid_connect'.freeze : super
  end

  def self.display_name
    self == OpenIDConnect ? 'OpenID Connect'.freeze : super
  end

  def self.recognized_params
    [ :client_id, :client_secret, :authorize_url, :token_url ].freeze
  end

  def unique_id(token)
    JWT.decode(token.params['id_token'], nil, false).first['sub']
  end

  protected

  def authorize_options
    { scope: 'openid' }
  end
end