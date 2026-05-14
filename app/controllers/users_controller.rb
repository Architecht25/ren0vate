class UsersController < ApplicationController
  before_action :authenticate_user!

  def profile
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to profile_path, notice: "Profil mis à jour avec succès."
    else
      flash.now[:alert] = "Erreur lors de la mise à jour."
      render :profile
    end
  end

  # RGPD art. 20 — Droit à la portabilité : export JSON des données personnelles
  def export_data
    user = current_user

    data = {
      exported_at: Time.current.iso8601,
      account: {
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        phone: user.phone,
        street: user.street,
        number: user.number,
        postal_code: user.postal_code,
        city: user.city,
        region: user.region,
        situation_familiale: user.situation_familiale,
        nombre_enfants: user.nombre_enfants,
        created_at: user.created_at.iso8601
      },
      properties: user.properties.map { |p|
        {
          id: p.id,
          adresse: [p.rue || p.adresse, p.numero, p.code_postal, p.commune].compact.join(', '),
          titre: p.titre,
          type_bien: p.type_bien_wallonie || p.type_bien_flandre || p.type_bien_bruxelles,
          region: p.region,
          annee_construction: p.annee_construction,
          created_at: p.created_at.iso8601,
          projects: p.projects.map { |pr|
            {
              id: pr.id,
              nom: pr.nom,
              description: pr.description,
              statut: pr.statut,
              created_at: pr.created_at.iso8601
            }
          }
        }
      },
      simulations: user.simulations.map { |s|
        {
          id: s.id,
          region: s.region,
          created_at: s.created_at.iso8601
        }
      },
      documents: user.documents.map { |d|
        {
          id: d.id,
          filename: d.file.attached? ? d.file.filename.to_s : nil,
          type_document: d.type_document,
          created_at: d.created_at.iso8601
        }
      }
    }

    send_data data.to_json(pretty: true),
              filename: "ren0vate-mes-donnees-#{Date.today.iso8601}.json",
              type: "application/json",
              disposition: "attachment"
  end

private

  def user_params
  params.require(:user).permit(
    :first_name, :last_name, :email, :phone, :iban, :national_number,
    :street, :number, :postal_code, :city, :region,
    :protected_client,
    :situation_familiale, :revenu_demandeur, :annee_revenus_demandeur,
    :revenu_conjoint, :annee_revenus_conjoint, :nombre_enfants,
    :personnes_60_ans_et_plus, :femme_enceinte
    )
  end
end
