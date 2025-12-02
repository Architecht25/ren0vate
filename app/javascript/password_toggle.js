/**
 * Password Toggle Functionality
 * Permet d'afficher/masquer le mot de passe avec un bouton œil
 */

document.addEventListener('DOMContentLoaded', function() {
  initPasswordToggle();
});

// Re-initialiser sur les navigations Turbo
document.addEventListener('turbo:load', function() {
  initPasswordToggle();
});

function initPasswordToggle() {
  const toggleButtons = document.querySelectorAll('.password-toggle-btn');

  toggleButtons.forEach(function(button) {
    // Supprimer les anciens event listeners pour éviter les doublons
    button.removeEventListener('click', togglePasswordVisibility);
    button.addEventListener('click', togglePasswordVisibility);
  });
}

function togglePasswordVisibility(event) {
  event.preventDefault();
  event.stopPropagation();
  
  const button = event.currentTarget;
  const passwordContainer = button.closest('.password-input-container');
  const passwordInput = passwordContainer.querySelector('input[type="password"], input[type="text"]');
  const icon = button.querySelector('i');

  if (!passwordInput || !icon) {
    console.error('Password input or icon not found');
    console.log('Container:', passwordContainer);
    console.log('Input:', passwordInput);
    console.log('Icon:', icon);
    return;
  }

  const isPasswordVisible = passwordInput.type === 'text';

  if (isPasswordVisible) {
    // Masquer le mot de passe
    passwordInput.type = 'password';
    icon.className = 'bi bi-eye';
    button.setAttribute('aria-label', 'Afficher le mot de passe');
    button.setAttribute('title', 'Afficher le mot de passe');
  } else {
    // Afficher le mot de passe
    passwordInput.type = 'text';
    icon.className = 'bi bi-eye-slash';
    button.setAttribute('aria-label', 'Masquer le mot de passe');
    button.setAttribute('title', 'Masquer le mot de passe');
  }

  // Maintenir le focus sur l'input après le toggle
  passwordInput.focus();
}
