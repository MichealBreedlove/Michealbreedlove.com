/*!
* Start Bootstrap - Personal v1.0.1 (https://startbootstrap.com/template-overviews/personal)
* Copyright 2013-2023 Start Bootstrap
* Licensed under MIT (https://github.com/StartBootstrap/startbootstrap-personal/blob/master/LICENSE)
*/
// This file is intentionally blank
// Use this file to add JavaScript to your project


// Smooth Scrolling
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener("click", function (e) {
        e.preventDefault();
        document.querySelector(this.getAttribute("href")).scrollIntoView({
            behavior: "smooth"
        });
    });
});

// Dark Mode Toggle
const toggleDarkMode = () => {
    document.body.classList.toggle("dark-mode");
    localStorage.setItem("darkMode", document.body.classList.contains("dark-mode"));
};

window.addEventListener("DOMContentLoaded", () => {
    const darkModeSetting = localStorage.getItem("darkMode") === "true";
    if (darkModeSetting) {
        document.body.classList.add("dark-mode");
    }

    const toggleBtn = document.createElement("button");
    toggleBtn.innerText = "🌙 Toggle Dark Mode";
    toggleBtn.className = "btn btn-sm btn-outline-dark position-fixed bottom-0 end-0 m-4 z-3";
    toggleBtn.onclick = toggleDarkMode;
    document.body.appendChild(toggleBtn);
});
