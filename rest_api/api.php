<?php

header("Content-Type: application/json; charset=UTF-8");

const email_regex_rfc2822 = "/(?:[a-z0-9!#$%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+\/=?^_`{|}~-]+)*|\"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*\")[@](?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/";

const name_regex = "/^[a-zA-z]{1,100}$/";

const db_server = "127.0.0.1";
const db_username = "root";
const db_password = "";
const db_name = "rest_api";

$method = $_SERVER["REQUEST_METHOD"];
$path =  parse_url($_SERVER["REQUEST_URI"], PHP_URL_PATH);

// php does not have easy way to normalize paths, every adequate standart library handles this automatically
$path = dirname($path) . "/" . basename($path);

function is_email_valid($email)
{
    // no need to run patter matching on empty emails or ones over the limit(100 chars is still too small in my opinion)
    if (empty($email) || strlen($email) > 100) {
        return false;
    }
    // regex to match RFC 2822 email
    preg_match(email_regex_rfc2822, $email, $matches);
    return !empty($matches);
}

function is_name_valid($name)
{
    if (empty($name)) {
        return false;
    }
    preg_match(name_regex, $name, $matches);
    return !empty($matches);
}

function is_password_valid($password)
{
    if (empty($password) || strlen($password) > 2056) {
        return false;
    }
    return true;
}

function sha256($input_data) {
    return hash('sha256', $input_data);
}

function get_db_connection() {
    // Create connection
    $conn = new mysqli(db_server, db_username, db_password, db_name);
    // Check connection
    if ($conn->connect_error) {
        return null;
    }
    return $conn;
}

function return_error($code, $error) {
    http_response_code($code);
    $response = [
        "error" => $error
    ];
    echo json_encode($response);
}

function not_found_error() {
    return_error(404, "Not found");
}

function internal_server_error() {
    return_error(500, "Internal server error");
}

// 1 has user, 0 no user, 1 error
function has_registered_user($email) {
    $conn = get_db_connection();
    $stmt = $conn->prepare("SELECT email FROM users WHERE email = ?");
    $stmt->bind_param("s", $email);
    if (!$stmt->execute()) {
        return -1;
    }

    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        return 1;
    }
    return 0;
}

function get_user($email) {
    $conn = get_db_connection();
    $stmt = $conn->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->bind_param("s", $email);
    if (!$stmt->execute()) {
        internal_server_error();
        return;
    }
    $result = $stmt->get_result()->fetch_assoc();

    // remove passowrd from return
    unset($result["password_hash"]);

    if (!empty($result)) {
        return json_encode($result);
    }
    return null;
}

function register_user($email, $firstname, $lastname, $password) {
    $conn = get_db_connection();

    // not very clever design decision to keep type of user as string
    $stmt = $conn->prepare("INSERT INTO users VALUES (?, ?, ?, ?, 'User')");
    $stmt->bind_param("ssss", $email, $firstname, $lastname, sha256($password));
    if (!$stmt->execute()) {
        return false;
    }
    return true;
}

function register($data) {
    // parse input
    $email = $data["email"];
    $firstname = $data["firstname"];
    $lastname = $data["lastname"];
    // not the best idea to hash the passwords server-side, because MITM attacks could leak them
    $password = $data["password"];

    // validate
    $is_valid = is_email_valid($email) &&
                is_name_valid($firstname) &&
                is_name_valid($lastname) &&
                is_password_valid($password);

    if (!$is_valid) {
        return_error(400, "Invalid registration data");
        return;
    }

    // check if user exists
    switch (has_registered_user($email)) {
        case 1:
            return_error(409, "Already registered");
            return;
        case -1:
            internal_server_error();
            return;
    }

    // register
    if (!register_user($email, $firstname, $lastname, $password)) {
        internal_server_error();
        return;
    }

    if (has_registered_user($email) != 1) {
        internal_server_error();
        return;
    }

    $stored_data = get_user($email);

    if (empty($stored_data)) {
        internal_server_error();
        return;
    }
    echo $stored_data;
}

function users() {
    $conn = get_db_connection();
    $stmt = $conn->prepare("SELECT email FROM users");
    if (!$stmt->execute()) {
        internal_server_error();
        return;
    }
    $result = $stmt->get_result()->fetch_all();

    function prepare_result($element) {
        return array_values($element)[0];
    }

    $result = array_map("prepare_result", $result);

    if (!empty($result)) {
        echo json_encode($result);
    }
}

function delete_user($user) {
    if (empty($user)) {
        return_error(400, 'Missing user email');
        return;
    }

    if (!has_registered_user($user)) {
        return_error(400, 'User not registered');
        return;
    }

    $stored_data = get_user($user);

    if (empty($stored_data)) {
        internal_server_error();
        return;
    }

    $conn = get_db_connection();
    $stmt = $conn->prepare("DELETE FROM users WHERE email = ?");
    $stmt->bind_param("s", $user);
    if (!$stmt->execute()) {
        internal_server_error();
        return;
    }

    echo $stored_data;
}


if ($method === "POST") {

    switch ($path) {
        case "/api.php/register":
            $input_data = json_decode(file_get_contents('php://input'), true);
            register($input_data);
            break;
        default:
            not_found_error();
            return;
    }

} else if ($method === "GET") {

    switch ($path) {
        case "/api.php/users":
            users();
            break;

        default:
            not_found_error();
            return;
    }

} else if ($method === "DELETE") {

    if (strpos($path, "/api.php/user/") !== false) {
        $user = str_replace("/api.php/user/", "", $path);
        error_log('user: ' . $user);
        delete_user($user);
    } else {
        not_found_error();
        return;
    }

} else {
    not_found_error();
    return;
}



?>
