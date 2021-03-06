class Job < ActiveRecord::Base
  belongs_to :domain

  scope :pending, -> { where(status: 0) }
  scope :failed, -> { where(status: 2) }
  scope :completed, -> { where(status: [1, 2]) }

  self.per_page = 100

  def failed?
    status == 2
  end

  def done?
    status == 1
  end

  def pending?
    status == 0
  end

  def arguments
    JSON.parse(args)
  end

  def zone
    return domain.name if domain

    arguments['zone']
  end

  def run_event!
    args = arguments
    raise 'Not an event!' unless args['event']

    Domain
      .find_by_name(args['zone'])
      .fire_state_event(args['event'])

    self.status = 1
    self.save!
  end

  class << self
    def add_domain(domain)
      ActiveRecord::Base.transaction do
        jobs_for_domain(domain, :add_domain)

        trigger_event(domain, :installed)
      end
    end

    def shutdown_domain(domain)
      ActiveRecord::Base.transaction do
        job_for_domain(domain, :remove_domain)
        job_for_domain(domain, :opendnssec_remove) if domain.dnssec?

        trigger_event(domain, :cleaned_up)
      end
    end

    def dnssec_sign(domain)
      ActiveRecord::Base.transaction do
        job_for_domain(domain, :opendnssec_add, policy: domain.dnssec_policy.name)
        job_for_domain(domain, :bind_convert_to_dnssec)

        trigger_event(domain, :signed)
      end
    end

    def wait_for_ready(domain)
      jobs_for_domain(domain,
                      :wait_for_ready_to_push_ds)
    end

    def dnssec_push_ds(domain, dss)
      opts = Hash[:dnssec_parent, domain.dnssec_parent,
                  :dnssec_parent_authority, domain.dnssec_parent_authority,
                  :dss, dss]
      keytag = dss.map { |ds| ds.split.first }.first # Both records should have the same keytag

      ActiveRecord::Base.transaction do
        job_for_domain(domain, :publish_ds, opts)
        job_for_domain(domain, :wait_for_active, keytag: keytag)

        trigger_event(domain, :converted)
      end
    end

    def dnssec_rollover_ds(domain, dss)
      opts = Hash[:dnssec_parent, domain.dnssec_parent,
                  :dnssec_parent_authority, domain.dnssec_parent_authority,
                  :dss, dss]

      keytag = dss.map { |ds| ds.split.first }.first # Both records should have the same keytag
      ActiveRecord::Base.transaction do
        job_for_domain(domain, :publish_ds, opts)
        job_for_domain(domain, :wait_for_active, keytag: keytag)

        trigger_event(domain, :complete_rollover)
      end
    end

    def dnssec_drop_ds(domain)
      opts = Hash[:dnssec_parent, domain.dnssec_parent,
                  :dnssec_parent_authority, domain.dnssec_parent_authority,
                  :dss, []]

      ActiveRecord::Base.transaction do
        job_for_domain(domain, :publish_ds, opts)
        # Wait for the change to propagate
        job_for_domain(domain, :wait_until, until: Time.now.to_i + WebDNS.settings[:dnssec_ds_removal_sleep])

        trigger_event(domain, :remove)
      end
    end

    def convert_to_plain(domain)
      ActiveRecord::Base.transaction do
        jobs_for_domain(domain,
                        :remove_domain,
                        :add_domain,
                        :opendnssec_remove)

        trigger_event(domain, :converted)
      end
    end

    private

    def trigger_event(domain, event)
      job_for_domain(domain, :trigger_event, event: event)
    end

    def jobs_for_domain(domain, *job_names)
      job_names.each { |job_name| job_for_domain(domain, job_name) }
    end

    def job_for_domain(domain, job_name, args = {})
      args = { zone: domain.name }.merge!(args)

      create!(domain: domain, job_type: job_name, args: args.to_json)
    end

  end

end
