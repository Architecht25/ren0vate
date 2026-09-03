class AddStatutToPebDonnees < ActiveRecord::Migration[8.1]
  def change
    # 'en_cours' | 'termine' | 'echec' — permet à l'upload de répondre immédiatement
    # pendant que PebExtractionJob tourne en arrière-plan. Le fallback OCR page-par-page
    # (pdftoppm + Tesseract, nécessaire pour les PDFs VEKA en Flandre dont l'encodage de
    # police est incompatible avec pdftotext/PDF::Reader) peut dépasser les 30s de timeout
    # du routeur Heroku (H12) si fait en synchrone dans la requête web.
    # Les lignes déjà en base ont toutes une extraction terminée (ancien flux synchrone)
    # → défaut 'termine' pour ne rien casser à l'affichage.
    add_column :peb_donnees, :statut, :string, default: 'termine', null: false
  end
end
