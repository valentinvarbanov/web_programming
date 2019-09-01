#!/usr/bin/env php
<?php

require_once("./websockets.php");

const db_server = "127.0.0.1";
const db_username = "root";
const db_password = "";
const db_name = "sheets";

function get_db_connection() {
    // Create connection
    $conn = new mysqli(db_server, db_username, db_password, db_name);
    // Check connection
    if ($conn->connect_error) {
        return null;
    }
    return $conn;
}

// 1 has user, 0 no user, -1 error
function has_table($table_id) {
    $conn = get_db_connection();
    $stmt = $conn->prepare("SELECT id FROM tables WHERE table_id = ?");
    $stmt->bind_param("s", $table_id);
    if (!$stmt->execute()) {
        return -1;
    }

    $result = $stmt->get_result();
    $result_map = $result->fetch_assoc();

    if ($result->num_rows > 0) {
        return $result_map["id"];
    }
    return 0;
}

function get_data($id) {
    $conn = get_db_connection();
    $stmt = $conn->prepare("SELECT row, col, value FROM data WHERE table_id = ?");
    $stmt->bind_param("i", $id);
    if (!$stmt->execute()) {
        return null;
    }

    $result = $stmt->get_result()->fetch_all();

    if (!empty($result)) {
        return $result;
    }
    return null;
}

function has_entry($id, $row, $col) {
    $conn = get_db_connection();
    $stmt = $conn->prepare("SELECT table_id FROM data WHERE table_id = ? AND row = ? AND col = ?");
    $stmt->bind_param("iii", $id, $row, $col);
    if (!$stmt->execute()) {
        return -1;
    }

    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        return 1;
    }
    return 0;
}

function update_cell($id, $row, $col, $value) {

    if (empty($value)) {
        //delete
        $conn = get_db_connection();
        $stmt = $conn->prepare("DELETE FROM data WHERE table_id = ? AND row = ? AND col = ?");
        $stmt->bind_param("iii", $id, $row, $col);

        if (!$stmt->execute()) {
            return false;
        }
        return true;

    } else {

        if (has_entry($id, $row, $col) > 0) {
            // update
            $conn = get_db_connection();
            $stmt = $conn->prepare("UPDATE data SET value = ? WHERE table_id = ? AND row = ? AND col = ?");
            $stmt->bind_param("siii", $value, $id, $row, $col);

            if (!$stmt->execute()) {
                return false;
            }
            return true;
        } else {
            // create new
            $conn = get_db_connection();
            $stmt = $conn->prepare("INSERT INTO data VALUES (?, ?, ?, ?)");
            $stmt->bind_param("iiis", $id, $row, $col, $value);

            if (!$stmt->execute()) {
                return false;
            }
            return true;
        }
    }
    return false;
}

function create_table($id) {
    // create new
    $conn = get_db_connection();
    $stmt = $conn->prepare("INSERT INTO tables (table_id) VALUES (?)");
    $stmt->bind_param("s", $id);
    if (!$stmt->execute()) {
        return false;
    }
    return true;
}

class echoServer extends WebSocketServer {

  function __construct($addr, $port, $bufferLength) {
    parent::__construct($addr, $port, $bufferLength);
    $this->userClass = "MyUser";
  }

  //protected $maxBufferSize = 1048576; //1MB... overkill for an echo server, but potentially plausible for other applications.

  protected function process ($user, $message) {

      $input_data = json_decode($message, true);

     // $this->stdout($input_data["type"]);
      if ($input_data["type"] === "init") {
          // set the id
          $user->sheetID = $input_data["id"];

          $id = has_table($input_data["id"]);


          if ($id > 0) {
              $data = get_data($id);

              $data = array("type" => "initResponse",
                                       "data" => $data);
              $data = json_encode($data);
              $this->send($user, $data);
          } else {
              create_table($user->sheetID);
          }

      } else if ($input_data["type"] === "cellUpdate") {
          // send updates

          update_cell(has_table($user->sheetID), $input_data["row"], $input_data["col"], $input_data["newValue"]);
          foreach ($this->users as $u) {
              if ($user->sheetID === $u->sheetID) {
                  $this->send($u,$message);
              }
          }
      }

  }

  protected function connected ($user) {

  }

  protected function closed ($user) {

  }

}

$echo = new echoServer("0.0.0.0","9000", 1024 * 1024/*1MB*/);

try {
  $echo->run();
}
catch (Exception $e) {
  $echo->stdout($e->getMessage());
}
