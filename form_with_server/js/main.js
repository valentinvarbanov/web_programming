(function() {
    const form = document.getElementById('enterMarkForm')
    form.addEventListener('submit', (e) => {
        e.preventDefault();
        var data = {
            name: form['name'].value,
            fn:   form['number'].valueAsNumber,
            mark: form['mark'].valueAsNumber
        };
        const xhttp = new XMLHttpRequest();
        xhttp.open("POST", "resource/submit_mark.php", true);
        xhttp.onreadystatechange = function() {
            if (this.readyState == 4 && this.status == 400) { alert('Bad input data..'); return; }
            if (this.readyState != 4 || this.status != 200) { return; }

            // clean the old data
            form['name'].value   = null;
            form['number'].value = null;
            form['mark'].value   = null;

            try {
                const response = JSON.parse(this.responseText);
                loadResults(response);
            } catch (e) {
                alert('Server error..');
            }

        };
        xhttp.send(JSON.stringify(data));
    });
})()

function loadResults(response) {
    if (!(response.students instanceof Array)) { console.error('Bad response data: ', response); return; }

    const table = document.getElementById('marksTable');

    // delete old rows
    const rows = Array.from(table.rows);
    rows.reduce( (table, row) => {
        table.deleteRow(row);
        return table;
    }, table);

    // add new ones
    response.students.reduce( (table, student) => {
        if (!(typeof(student.name) === 'string' || student.name instanceof String) ||
            !(typeof(student.fn) === 'number' || student.fn instanceof Number)   ||
            !(typeof(student.mark) === 'number' || student.mark instanceof Number)) { return table; }

        const row = table.insertRow(-1);

        var cell = row.insertCell(-1);
        cell.innerHTML = student.name;

        cell = row.insertCell(-1);
        cell.innerHTML = student.fn;

        cell = row.insertCell(-1);
        cell.innerHTML = student.mark;

        return table;
    }, table);
}

(function() {
    const xhttp = new XMLHttpRequest();
    xhttp.open("GET", "resource/get_marks.php", true);
    xhttp.onreadystatechange = function() {
        if (this.readyState != 4 || this.status != 200) { return; }

        try {
            const response = JSON.parse(this.responseText);
            loadResults(response);
        } catch (e) {
            alert('Server error..');
        }
    };
    xhttp.send();
})()
