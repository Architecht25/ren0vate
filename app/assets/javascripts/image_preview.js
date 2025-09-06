// Fonction pour prévisualiser une image avant upload
function previewImage(input) {
  const preview = document.getElementById('image-preview');
  const previewImg = document.getElementById('preview-img');

  if (input.files && input.files[0]) {
    const reader = new FileReader();

    reader.onload = function(e) {
      previewImg.src = e.target.result;
      preview.style.display = 'block';
    };

    reader.readAsDataURL(input.files[0]);
  } else {
    preview.style.display = 'none';
  }
}

// Validation de la taille du fichier (5MB max)
document.addEventListener('DOMContentLoaded', function() {
  const photoInputs = document.querySelectorAll('input[type="file"][name*="photo"]');

  photoInputs.forEach(function(input) {
    input.addEventListener('change', function() {
      const file = this.files[0];
      if (file) {
        const maxSize = 5 * 1024 * 1024; // 5MB en bytes

        if (file.size > maxSize) {
          alert('La taille du fichier ne peut pas dépasser 5MB. Veuillez choisir une image plus petite.');
          this.value = '';
          document.getElementById('image-preview').style.display = 'none';
          return;
        }

        // Vérifier le type de fichier
        const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
        if (!allowedTypes.includes(file.type)) {
          alert('Seuls les fichiers JPG, PNG et GIF sont autorisés.');
          this.value = '';
          document.getElementById('image-preview').style.display = 'none';
          return;
        }
      }
    });
  });
});
