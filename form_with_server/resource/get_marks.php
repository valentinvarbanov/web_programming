<?php

    $students = [
        [ 'name' => 'Мария Георгиева', 'fn' => 62543, 'mark' => 5.25 ],
        [ 'name' => 'Иван Иванов', 'fn' => 62555, 'mark' => 6.00 ],
        [ 'name' => 'Петър Петров', 'fn' => 62549, 'mark' => 5.00],
        [ 'name' => 'Петя Димитрова', 'fn' => 62559, 'mark' => 6.00]
    ];

    function students_comparator($a, $b) {

        if ($a['mark'] == $b['mark']) {
            return $a['fn'] < $b['fn'] ? -1 : 1;
        }
        return $b['mark'] < $a['mark'] ? -1 : 1;
    }


    usort($students, "students_comparator");


    $result = [ 'students' => $students ];

    echo json_encode($result);
    
?>
