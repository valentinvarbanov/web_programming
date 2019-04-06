<?php
    $input_data = json_decode(file_get_contents('php://input'), true);

    $name = $input_data['name'];
    $fn = intval($input_data['fn']);
    $mark = floatval($input_data['mark']);

    $input_is_valid = strlen($name) >= 1 && strlen($name) <= 200 &&
                      $fn >= 62000 && $fn <= 62999 &&
                      $mark >= 2.0 && $mark <= 6.0;


    if (!$input_is_valid) {
        http_response_code(400);
        return;
    }

    $students = [
        [ 'name' => 'Мария Георгиева', 'fn' => 62543, 'mark' => 5.25 ],
        [ 'name' => 'Иван Иванов', 'fn' => 62555, 'mark' => 6.00 ],
        [ 'name' => 'Петър Петров', 'fn' => 62549, 'mark' => 5.00],
        [ 'name' => 'Петя Димитрова', 'fn' => 62559, 'mark' => 6.00]
    ];

    array_push($students, [ 'name' => $name, 'fn' => $fn, 'mark' => $mark]);

    function students_comparator($a, $b) {

        if ($a['mark'] == $b['mark']) {
            return $a['fn'] < $b['fn'] ? -1 : 1;
        }
        return $b['mark'] < $a['mark'] ? -1 : 1;
    }


    usort($students, 'students_comparator');

    $result = [ 'students' => $students ];

    echo json_encode($result);
?>
