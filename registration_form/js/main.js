function validateForm() {
    const password = document.getElementById('password').value
    const passwordVerification = document.getElementById('password-verify').value
    if (password != passwordVerification) {
        alert('Passwords do not match')
        return false
    }
    return true
}

async function sha256(message) {
    // encode as UTF-8
    const msgBuffer = new TextEncoder('utf-8').encode(message);

    // hash the message
    const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer)

    // convert ArrayBuffer to Array
    const hashArray = Array.from(new Uint8Array(hashBuffer));

    // convert bytes to hex string
    const hashHex = hashArray.map(b => ('00' + b.toString(16)).slice(-2)).join('');
    return hashHex;
}

(function() {
    const form = document.getElementById('registration');
    form.addEventListener('submit', (e) => {
        e.preventDefault()
        if (validateForm()) {
            const password = form.password.value
            const shaPassword = sha256(password)

            shaPassword.then( (shaPassword) => {
                form['password'].value = ''
                form['password-verify'].value = ''
                form.shapassword.value = shaPassword
                form.submit()
            })
        }
    });
})()
