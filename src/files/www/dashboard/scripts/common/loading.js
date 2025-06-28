function loading(show,message,errorStyle) {
    
    document.getElementById('overlay').style.display = show ? 'flex' : 'none';
    var message_element = document.getElementById('overlay_message');

    if(errorStyle)
    {
        message_element.classList.add("text-danger")
        message_element.classList.remove("text-light")
    }
    else{
        message_element.classList.remove("text-danger")
        message_element.classList.add("text-light")
    }
    if (message){
        message_element.textContent = message;
    }else{
        message_element.textContent = "Loading ...";
    }
}


function removeSubstring ( mainStr , substringToRemove ){
    var mainString = mainStr
    // Check if the mainString ends with the substringToRemove
    if (mainString.endsWith(substringToRemove)) {
        // Get the length of the substringToRemove
        let substringLength = substringToRemove.length;
        // Remove the substring from the end of the mainString using slice()
        mainString = mainString.slice(0, -substringLength);
    }
    
    return mainString
}

document.addEventListener("DOMContentLoaded", function() {
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.has('ref') && urlParams.get('ref') === 'dashboard') {
        const previousButtonText = document.getElementById('back-btn-text');
        previousButtonText.textContent = 'Back to Dashboard';
        const previousButtonhref = document.getElementById('back-btn-href');
        previousButtonhref.href = 'dashboard.html';
    }
})

function addCustomAlert(title, message, visibilityTime) {
    const time = visibilityTime || 2000;
    M.toast({html: `<strong>${title}</strong> ${message}`, classes: 'yellow darken-2', displayLength: time});
}




// Language Switching
const englishButton = document.querySelector('.en-btn');
const persianButtons = document.querySelectorAll('.fa-btn');

function switchLanguage(showEnglish) {
    const englishElements = document.querySelectorAll('.english-text');
    const persianElements = document.querySelectorAll('.farsi-text');
    
    englishElements.forEach(el => {
        el.style.display = showEnglish ? 'block' : 'none';
    });
    
    persianElements.forEach(el => {
        el.style.display = showEnglish ? 'none' : 'block';
    });
}

if( englishButton && persianButtons){
    // English button click handler
    englishButton.addEventListener('click', () => {
        switchLanguage(true);
    });

    // Persian buttons click handler
    persianButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            switchLanguage(false);
        });
    });

    // Initialize with Persian text by default
    switchLanguage(false);
}