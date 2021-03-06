class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  attr_writer :breadcrumb
  helper_method :admin?
  helper_method :dnssec?

  def admin?
    return false if params.key?('user')
    return false if current_user.nil?

    current_user.admin
  end

  def admin_only!
    return if admin?

    redirect_to root_path, alert: 'Admin only area!'
  end

  def dnssec?
    WebDNS.settings[:dnssec]
  end

  private

  def group
    @group ||= edit_group_scope.find(params[:group_id] || params[:id])
  end

  def domain
    @domain ||= edit_domain_scope.find(params[:domain_id] || params[:id])
  end

  def record
    @record ||= record_scope.find(params[:record_id] || params[:id] || params[:pk])
  end

  def show_group_scope
    @show_group_scope ||= current_user.groups
  end

  def edit_group_scope
    @edit_group_scope ||= admin? ? Group.all : show_group_scope
  end

  def show_domain_scope
    @show_domain_scope ||= Domain.where(group: show_group_scope)
  end

  def edit_domain_scope
    @edit_domain_scope ||= admin? ? Domain.all : Domain.where(group: show_group_scope)
  end

  def record_scope
    @record_scope ||= domain.records
  end

  def notification
    Notification.instance if WebDNS.settings[:notifications]
  end
end
