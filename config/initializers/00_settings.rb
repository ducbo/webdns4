WebDNS.settings[:soa_defaults] = {
  primary_ns: 'ns1.example.com',
  contact: 'domainmaster@example.com',
  serial: 1,
  refresh: 10_800,
  retry: 3600,
  expire: 604_800,
  nx: 3600
}
WebDNS.settings[:default_ns] = [
  'ns1.example.com',
  'ns2.example.com'
]

WebDNS.settings[:dnssec] = true
WebDNS.settings[:dnssec_parent_authorities] = ['webdns', 'papaki']

WebDNS.settings[:serial_strategy] = Strategies::Date

WebDNS.settings[:prohibit_records_types] = []
WebDNS.settings[:prohibit_domain_types] = ['NATIVE']

WebDNS.settings[:contact_mail] = 'webdns@example.com'
WebDNS.settings[:mail_from] = 'webdns@example.com'
WebDNS.settings[:admin_group] = 'admin'

WebDNS.settings[:saml] = false
WebDNS.settings[:saml_required_entitlement] = 'webdns'
WebDNS.settings[:saml_login_text] = 'Login with SAML'

# Allow local overrides
local_settings = File.expand_path('../../local_settings.rb', __FILE__)
require_relative local_settings if File.exist?(local_settings)
