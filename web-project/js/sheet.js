var socket;

function placeCaretAtEnd(el) {
    el.focus();
    if (typeof window.getSelection != 'undefined'
      && typeof document.createRange != 'undefined') {
      var range = document.createRange();
      range.selectNodeContents(el);
      range.collapse(false);
      var sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(range);
    }
}

function initSocket() {
    var host = 'ws://10.0.1.25:9000/echobot'; // SET THIS TO YOUR SERVER
    try {
        socket = new WebSocket(host);
        log('WebSocket - status '+socket.readyState);
        socket.onopen    = function(msg) {
                                log('Welcome - status '+this.readyState);
                                requestData();
                            };
        socket.onmessage = function(msg) {
                                log('Received: '+msg.data);
                                try {
                                    let received = JSON.parse(msg.data);
                                    handleMessage(received);
                                } catch(ex) {
                                    log(ex);
                                }
                            };
        socket.onclose   = function(msg) {
                                log('Disconnected - status '+this.readyState);
                           };
    }
    catch(ex) {
        log(ex);
    }
}

function sendSocketMessage(message) {
    try {
        let msg = JSON.stringify(message);
        socket.send(msg);
        log('Sent: '+msg);
    } catch(ex) {
        log(ex);
    }
}

function closeSocket() {
    if (socket != null) {
        log('Goodbye!');
        socket.close();
        socket = null;
    }
}

function reconnectSocket() {
    closeSocket();
    initSocket();
}

function loadTable() {
    let table = $('main-sheet')

    let tableHead = document.createElement('thead');
    let tableRow = document.createElement('tr');

    for (let col = 0; col < 6; col++) {
        let cell = document.createElement('th');
        cell.innerHTML = '' + col;
        // cell.contentEditable = true;
        tableRow.appendChild(cell);
    }
    tableHead.appendChild(tableRow);
    table.appendChild(tableHead);

    let tableBody = document.createElement('tbody');

    for (let row = 0; row < 6; row++) {

        let tableRow = document.createElement('tr');

        for (let col = 0; col < 6; col++) {
            let cell = document.createElement('td');

            cell.contentEditable = true;

            cell.oninput = function () { onCellChange(cell); };

            tableRow.appendChild(cell);
        }

        tableBody.appendChild(tableRow);
    }

    table.appendChild(tableBody);

    table.border = 2;
}

function load() {
    if (!isDebug()) {
        $('debug').innerHTML = '';
    }
    loadTable();
    loadTitle();
    initSocket();
}

function loadTitle() {
    $('mainTitle').innerText = getID();
}

function requestData() {
    sendSocketMessage({
        'type': 'init',
        'id': getID()
    })
}

function onCellFocus() {
    // for future use
}

function onCellChange(cell) {
    let row = cell.parentNode.rowIndex;
    let col = cell.cellIndex;

    // console.log('' + row + ' ' + col + ' changed');
    sendSocketMessage({
        'type': 'cellUpdate',
        'row': row,
        'col': col,
        'newValue': cell.innerText
    });
}

function handleMessage(received) {
    if (received.type == 'cellUpdate') {
        let table = $('main-sheet');
        let cell = table.rows[received.row].cells[received.col];

        cell.innerText = received.newValue;
        if (document.activeElement === cell) {
            placeCaretAtEnd(cell);
        }
    } else if (received.type == 'initResponse') {
        for (var i = 0; i < received.data.length; i++) {
            let entry = received.data[i];
            let row = parseInt(entry[0]);
            let col = parseInt(entry[1]);
            let value = entry[2];

            let table = $('main-sheet');
            let cell = table.rows[row].cells[col];
            cell.innerText = value;
        }
    }
}

// Utilities
function $(id) { return document.getElementById(id); }
function log(msg) { if ($('log')) $('log').innerHTML+='<br>'+msg; }
function onkey(event) { if(event.keyCode==13){ send(); } }
function getID() { return (new URL(window.location)).searchParams.get('id'); }
function isDebug() { return (new URL(window.location)).searchParams.get('debug') == 'true'; }
