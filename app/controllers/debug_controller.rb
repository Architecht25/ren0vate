class DebugController < ApplicationController
  def properties
    @all_properties = Property.all
    @users = User.all
    @test_user = User.find_by(email: 'test@example.com')
    
    render plain: debug_info
  end
  
  private
  
  def debug_info
    info = "=== Debug Propriétés ===\n\n"
    
    info += "Nombre total de propriétés: #{@all_properties.count}\n"
    @all_properties.each do |property|
      info += "- ID: #{property.id}, User ID: #{property.user_id}, Nom: #{property.name}\n"
    end
    
    info += "\n=== Utilisateurs ===\n"
    @users.each do |user|
      info += "- ID: #{user.id}, Email: #{user.email}, Propriétés: #{user.properties.count}\n"
    end
    
    if @test_user
      info += "\n=== Propriétés pour test@example.com ===\n"
      @test_user.properties.each do |property|
        info += "- ID: #{property.id}, Nom: #{property.name}, Adresse: #{property.full_address}\n"
      end
      
      info += "\n=== URLs valides ===\n"
      @test_user.properties.each do |property|
        info += "- Vue détaillée: http://localhost:3000/properties/#{property.id}\n"
        info += "- Dashboard: http://localhost:3000/properties/#{property.id}/dashboard\n"
      end
    else
      info += "\nUtilisateur de test non trouvé\n"
    end
    
    info
  end
end
