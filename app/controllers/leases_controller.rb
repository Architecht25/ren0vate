class LeasesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_gestion_locative_access!
  before_action :set_property
  before_action :set_tenant
  before_action :set_lease, only: [:show, :edit, :update, :destroy, :terminer, :activer_resiliation]

  def new
    @lease = @tenant.leases.build(
      property: @property,
      start_date: Date.current,
      status: 'actif',
      lease_type: 'residence_principale',
      indexation_month: Date.current.month
    )
  end

  def create
    @lease = @tenant.leases.build(lease_params)
    @lease.property = @property

    if @lease.save
      redirect_to property_tenant_lease_path(@property, @tenant, @lease),
                  notice: 'Bail enregistré avec succès.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @rent_payments = @lease.rent_payments.order(due_date: :desc)
    @prochaine_indexation = @lease.mois_indexation_prochain
    @impaye_total = @lease.montant_impaye
    @lease_documents = @lease.documents.to_a
  end

  def edit; end

  def update
    if @lease.update(lease_params)
      redirect_to property_tenant_lease_path(@property, @tenant, @lease),
                  notice: 'Bail mis à jour.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @lease.destroy
    redirect_to property_tenant_path(@property, @tenant),
                notice: 'Bail supprimé.'
  end

  def terminer
    if @lease.update(status: 'termine', end_date: params[:end_date] || Date.current)
      redirect_to property_tenant_lease_path(@property, @tenant, @lease),
                  notice: 'Bail marqué comme terminé.'
    else
      redirect_to property_tenant_lease_path(@property, @tenant, @lease),
                  alert: 'Erreur lors de la clôture du bail.'
    end
  end

  def activer_resiliation
    if @lease.update(status: 'en_resiliation', notice_given_at: params[:notice_given_at] || Date.current, notice_by: params[:notice_by])
      redirect_to property_tenant_lease_path(@property, @tenant, @lease),
                  notice: 'Préavis enregistré.'
    else
      redirect_to property_tenant_lease_path(@property, @tenant, @lease),
                  alert: 'Erreur lors de l\'enregistrement du préavis.'
    end
  end

  private

  def set_property
    @property = current_user.properties.find(params[:property_id])
  end

  def set_tenant
    @tenant = @property.tenants.find(params[:tenant_id])
  end

  def set_lease
    @lease = @tenant.leases.find(params[:id])
  end

  def lease_params
    params.require(:lease).permit(
      :lease_type, :start_date, :end_date,
      :rent_amount, :charges_amount, :rental_guarantee_amount,
      :indexation_month, :status, :notes
    )
  end
end
