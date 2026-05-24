class TenantsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_property
  before_action :set_tenant, only: [:show, :edit, :update, :destroy]

  def new
    @tenant = @property.tenants.build
  end

  def create
    @tenant = @property.tenants.build(tenant_params)
    @tenant.user = current_user

    if @tenant.save
      redirect_to property_gestion_locative_path(@property),
                  notice: 'Locataire ajouté avec succès.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @leases = @tenant.leases.order(start_date: :desc)
  end

  def edit; end

  def update
    if @tenant.update(tenant_params)
      redirect_to property_gestion_locative_path(@property),
                  notice: 'Locataire mis à jour.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @tenant.destroy
    redirect_to property_gestion_locative_path(@property),
                notice: 'Locataire supprimé.'
  end

  private

  def set_property
    @property = current_user.properties.find(params[:property_id])
  end

  def set_tenant
    @tenant = @property.tenants.find(params[:id])
  end

  def tenant_params
    params.require(:tenant).permit(:first_name, :last_name, :email, :phone, :national_number_ciphertext, :notes)
  end
end
