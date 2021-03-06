require 'securerandom'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class SamlAuthenticatable < Authenticatable
      def valid?
        return false unless remote_user.present?
        return false unless mail.present?

        return true if WebDNS.settings[:saml_required_entitlement].nil?

        entitlement.present? &&
          entitlement.include?(WebDNS.settings[:saml_required_entitlement])
      end

      def authenticate!
        if !WebDNS.settings[:saml]
          return fail!('SAML is disabled')
        end

        identifier = ['saml', remote_user].join(':')
        user = mapping.to.find_or_initialize_by(identifier: identifier)

        return fail!('Wrong credentials') unless user

        # Update user attributes
        user.email = mail
        user.password = SecureRandom.hex(15) if user.new_record?
        user.save!

        success!(user)
      end

      private

      def remote_user
        request.headers['HTTP_REMOTE_USER']
      end

      def mail
        request.headers['MAIL']
      end

      def entitlement
        request.headers['ENTITLEMENT']
      end

    end
  end
end

Warden::Strategies.add(:saml, Devise::Strategies::SamlAuthenticatable)
