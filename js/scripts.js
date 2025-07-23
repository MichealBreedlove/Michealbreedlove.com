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
    const isDarkMode = document.body.classList.contains("dark-mode");
    localStorage.setItem("darkMode", document.body.classList.contains("dark-mode"));
    
    // Update button text
    const toggleBtn = document.getElementById("darkModeToggle");
    if (toggleBtn) {
        toggleBtn.innerHTML = isDarkMode ? "☀️ Light Mode" : "🌙 Dark Mode";
    }
};

window.addEventListener("DOMContentLoaded", () => {
    const darkModeSetting = localStorage.getItem("darkMode") === "true";
    if (darkModeSetting) {
        document.body.classList.add("dark-mode");
    }

    const toggleBtn = document.createElement("button");
    toggleBtn.id = "darkModeToggle";
    toggleBtn.innerHTML = darkModeSetting ? "☀️ Light Mode" : "🌙 Dark Mode";
    toggleBtn.className = "btn btn-sm btn-outline-primary position-fixed bottom-0 end-0 m-4 z-3 shadow";
    toggleBtn.style.borderRadius = "25px";
    toggleBtn.onclick = toggleDarkMode;
    document.body.appendChild(toggleBtn);
});

// Add typing animation to hero text
document.addEventListener("DOMContentLoaded", function() {
    const heroText = document.querySelector(".display-3 .text-gradient");
    if (heroText) {
        const text = heroText.textContent;
        heroText.textContent = "";
        heroText.style.borderRight = "2px solid";
        heroText.style.animation = "blink 1s infinite";
        
        let i = 0;
        const typeWriter = () => {
            if (i < text.length) {
                heroText.textContent += text.charAt(i);
                i++;
                setTimeout(typeWriter, 100);
            } else {
                setTimeout(() => {
                    heroText.style.borderRight = "none";
                    heroText.style.animation = "none";
                }, 1000);
            }
        };
        
        setTimeout(typeWriter, 1000);
    }
});

// Add CSS for typing animation
const style = document.createElement('style');
style.textContent = `
    @keyframes blink {
        0%, 50% { border-color: transparent; }
        51%, 100% { border-color: #0d6efd; }
    }
`;
document.head.appendChild(style);