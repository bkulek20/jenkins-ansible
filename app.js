console.log("Saved theme in localStorage:", localStorage.getItem('theme'));

document.addEventListener("DOMContentLoaded", function() {
    const body = document.body;
    const toggleButton = document.getElementById('toggle-theme');

   
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme) {
        body.classList.add(savedTheme);
    } else {
        body.classList.add('light-mode'); 
    }

  

    toggleButton.addEventListener('click', function() {
        if (body.classList.contains('dark-mode')) {
            body.classList.remove('dark-mode');
            body.classList.add('light-mode');
            localStorage.setItem('theme', 'light-mode');
            console.log("Switched to light mode");
        } else {
            body.classList.remove('light-mode');
            body.classList.add('dark-mode');
            localStorage.setItem('theme', 'dark-mode');
            console.log("Switched to dark mode");
        }
      
    });

   
});