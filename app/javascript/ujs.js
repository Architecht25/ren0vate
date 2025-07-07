import Rails from "./rails_ujs";
Rails.start();

document.addEventListener("turbo:load", () => {
  document.querySelectorAll("[data-turbo]").forEach(element => {
    element.setAttribute("data-turbo", "false");
  });
});
