class RentPaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_property
  before_action :set_tenant
  before_action :set_lease
  before_action :set_rent_payment, only: [:edit, :update, :destroy]

  def new
    # Pré-remplir avec le montant du loyer + charges et la date du prochain mois
    @rent_payment = @lease.rent_payments.build(
      amount: @lease.loyer_total,
      due_date: Date.current.next_month.beginning_of_month,
      status: 'pending'
    )
  end

  def create
    @rent_payment = @lease.rent_payments.build(rent_payment_params)

    if @rent_payment.save
      redirect_to property_tenant_lease_path(@property, @tenant, @lease),
                  notice: 'Paiement enregistré.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @rent_payment.update(rent_payment_params)
      redirect_to property_tenant_lease_path(@property, @tenant, @lease),
                  notice: 'Paiement mis à jour.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @rent_payment.destroy
    redirect_to property_tenant_lease_path(@property, @tenant, @lease),
                notice: 'Paiement supprimé.'
  end

  private

  def set_property
    @property = current_user.properties.find(params[:property_id])
  end

  def set_tenant
    @tenant = @property.tenants.find(params[:tenant_id])
  end

  def set_lease
    @lease = @tenant.leases.find(params[:lease_id])
  end

  def set_rent_payment
    @rent_payment = @lease.rent_payments.find(params[:id])
  end

  def rent_payment_params
    params.require(:rent_payment).permit(:due_date, :paid_date, :amount, :status, :payment_method, :notes)
  end
end
