#!/usr/bin/env bash

COLOR_RED='\033[1;31m'
COLOR_GREEN='\033[1;32m'
COLOR_NONE='\033[0m'


# -s no progress
# -o output to /dev/null
# write response
NO_PROGRESS='-s'
OUPUT_ONLY_RESPONSE_CODE='-s -o /dev/null -w %{http_code}'
JSON_CONTENT_TYPE='-H Content-type:application/json'
CURL='curl'

ASSERT_EQUAL() {
    if [[ "$1" == "$2" ]]; then
        echo -e "[ ${COLOR_GREEN}PASS${COLOR_NONE} ] - $3"
        (( PASSED++ ))
        (( GROUP_PASSED++ ))
    else
        echo -e "[ ${COLOR_RED}FAIL${COLOR_NONE} ] - $3 expected '$2' have '$1'"
        (( FAILED++ ))
        (( GROUP_FAILED++ ))
    fi
}

initialize_data() {
    ./setup.sh &>/dev/null
}

group_begin() {
    GROUP_PASSED=0
    GROUP_FAILED=0
    echo '-------------------------------'
    echo "  group - '$1'"
    echo '-------------------------------'
}

group_end() {
    local TOTAL=$((GROUP_PASSED + GROUP_FAILED))
    echo '-------------------------------'
    # echo "  group  : $1"
    echo "  passed : $GROUP_PASSED / $TOTAL"
    echo '-------------------------------'
    echo
}

begin_statistics() {
    SECONDS=0
    PASSED=0
    FAILED=0
    GROUP_PASSED=0
    GROUP_FAILED=0
}

print_statistics() {
    local TOTAL=$((PASSED + FAILED))
    echo '----------- summary -----------'
    echo "  total        : $TOTAL"
    echo "  passed       : $PASSED"
    echo "  failed       : $FAILED"
    echo "  time elapsed : ${SECONDS}s"
    echo '-------------------------------'
}

test_registration() {
    # register
    group_begin 'registration'
    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XPOST -d '{}' 'localhost:8989/api.php/register' )
    ASSERT_EQUAL $RESULT '400' 'registration with empty json should fail'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XGET -d '{}' 'localhost:8989/api.php/register' )
    ASSERT_EQUAL $RESULT '404' 'registration with GET should fail'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XPOST -d '{
      "email": "invalid-email",
      "firstname": "Name",
      "lastname": "Last",
      "password": "pass"
    }' 'localhost:8989/api.php/register' )
    ASSERT_EQUAL $RESULT '400' 'registration with incorrect email should fail'


    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XPOST -d '{
      "firstname": "Name",
      "lastname": "Last",
      "password": "pass"
    }' 'localhost:8989/api.php/register' )
    ASSERT_EQUAL $RESULT '400' 'registration with missing email should fail'


    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XPOST -d '{
      "email": "test@test.com",
      "lastname": "Last",
      "password": "pass"
    }' 'localhost:8989/api.php/register' )
    ASSERT_EQUAL $RESULT '400' 'registration with missing name should fail'


    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XPOST -d '{
      "email": "test@test.com",
      "firstname": "Name",
      "lastname": "Last",
      "password": ""
    }' 'localhost:8989/api.php/register' )
    ASSERT_EQUAL $RESULT '400' 'registration with empty password should fail'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XPOST -d '{
      "email": "test@test.com",
      "firstname": "Na3me",
      "lastname": "Last",
      "password": "pass"
    }' 'localhost:8989/api.php/register' )
    ASSERT_EQUAL $RESULT '400' 'registration with invalid name should fail'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XPOST -d '{
      "email": "test@test.com",
      "firstname": "Name",
      "lastname": "La1st",
      "password": "pass"
    }' 'localhost:8989/api.php/register' )
    ASSERT_EQUAL $RESULT '400' 'registration with invalid last name should fail'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XPOST -d '{
      "email": "test@test.com",
      "lastname": "Last",
      "password": "pass"
    }' 'localhost:8989/api.php/register' )
    ASSERT_EQUAL $RESULT '400' 'registration with missing name should fail'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XPOST -d '{
      "email": "test@test.com",
      "firstname": "Name",
      "password": "pass"
    }' 'localhost:8989/api.php/register' )
    ASSERT_EQUAL $RESULT '400' 'registration with missing last name should fail'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XPOST -d '{
      "email": "test@test.com",
      "firstname": "Name",
      "lastname": "Last",
      "password": ""
    }' 'localhost:8989/api.php/register' )
    ASSERT_EQUAL $RESULT '400' 'registration with empty password should fail'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XPOST -d '{
      "email": "test@test.com",
      "firstname": "Name",
      "lastname": "Last"
    }' 'localhost:8989/api.php/register' )
    ASSERT_EQUAL $RESULT '400' 'registration with missing password should fail'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XPOST -d '{
      "email": "test@test.com",
      "firstname": "Name",
      "lastname": "Last",
      "password": "pass"
    }' 'localhost:8989/api.php/register' )
    ASSERT_EQUAL $RESULT '200' 'registration with correct data should pass'

    RESULT=$( $CURL $NO_PROGRESS $JSON_CONTENT_TYPE -XPOST -d '{
      "email": "test2@test.com",
      "firstname": "Name",
      "lastname": "Last",
      "password": "pass"
    }' 'localhost:8989/api.php/register' )
    ASSERT_EQUAL $RESULT '{"email":"test2@test.com","firstname":"Name","lastname":"Last","role":"User"}' 'registration with correct data should return user data'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XPOST -d '{
      "email": "test@test.com",
      "firstname": "AnotherName",
      "lastname": "Last",
      "password": "pass"
    }' 'localhost:8989/api.php/register' )
    ASSERT_EQUAL $RESULT '409' 'registration with existing user should fail'

    group_end 'registration'
}

test_get_users() {
    # users
    group_begin 'get users'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XPOST localhost:8989/api.php/users )
    ASSERT_EQUAL $RESULT '404' 'get users with POST should fail'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XDELETE localhost:8989/api.php/users )
    ASSERT_EQUAL $RESULT '404' 'get users with DELETE should fail'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XGET localhost:8989/api.php/users )
    ASSERT_EQUAL $RESULT '200' 'get users with GET should pass'

    RESULT=$( $CURL $NO_PROGRESS $JSON_CONTENT_TYPE -XGET localhost:8989/api.php/users )
    ASSERT_EQUAL $RESULT '["valentin.varbanov@gmail.com"]' 'get users(initial) with GET should return array with emails'

    IGNORE=$( $CURL $NO_PROGRESS $JSON_CONTENT_TYPE -XPOST -d '{
      "email": "second@test.com",
      "firstname": "Name",
      "lastname": "Last",
      "password": "pass"
    }' 'localhost:8989/api.php/register' )
    RESULT=$( $CURL $NO_PROGRESS $JSON_CONTENT_TYPE -XGET localhost:8989/api.php/users )
    ASSERT_EQUAL $RESULT '["valentin.varbanov@gmail.com","second@test.com"]' 'get users(added user) with GET should return array with emails'

    IGNORE=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XDELETE localhost:8989/api.php/user/second@test.com )
    RESULT=$( $CURL $NO_PROGRESS $JSON_CONTENT_TYPE -XGET localhost:8989/api.php/users )
    ASSERT_EQUAL $RESULT '["valentin.varbanov@gmail.com"]' 'get users(removed user) with GET should return array with emails'

    group_end 'get users'
}

test_delete_user() {
    # delete user
    group_begin 'delete user'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XPOST localhost:8989/api.php/user/test@test.com )
    ASSERT_EQUAL $RESULT '404' 'delete user with POST should fail'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XPUT localhost:8989/api.php/user/test@test.com )
    ASSERT_EQUAL $RESULT '404' 'delete user with PUT should fail'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XGET localhost:8989/api.php/user/test@test.com )
    ASSERT_EQUAL $RESULT '404' 'delete user with GET should fail'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XDELETE localhost:8989/api.php/user/ )
    ASSERT_EQUAL $RESULT '404' 'delete user without username should fail'

    IGNORE=$( $CURL $NO_PROGRESS $JSON_CONTENT_TYPE -XPOST -d '{
      "email": "deleted@test.com",
      "firstname": "Name",
      "lastname": "Last",
      "password": "pass"
    }' 'localhost:8989/api.php/register' )
    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XDELETE localhost:8989/api.php/user/deleted@test.com )
    ASSERT_EQUAL $RESULT '200' 'delete existing user should pass'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XDELETE localhost:8989/api.php/user/deleted@test.com )
    ASSERT_EQUAL $RESULT '400' 'delete non-existing user should fail'

    IGNORE=$( $CURL $NO_PROGRESS $JSON_CONTENT_TYPE -XPOST -d '{
      "email": "deleted2@test.com",
      "firstname": "Name",
      "lastname": "Last",
      "password": "pass"
    }' 'localhost:8989/api.php/register' )
    RESULT=$( $CURL $NO_PROGRESS $JSON_CONTENT_TYPE -XDELETE localhost:8989/api.php/user/deleted2@test.com )
    ASSERT_EQUAL $RESULT '{"email":"deleted2@test.com","firstname":"Name","lastname":"Last","role":"User"}' 'delete existing user should pass'


    group_end 'delete user'
}

test_generel() {
    # generic
    group_begin 'general'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XGET localhost:8989/api.php )
    ASSERT_EQUAL $RESULT '404' 'empty path with GET should fail'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XPOST localhost:8989/api.php )
    ASSERT_EQUAL $RESULT '404' 'empty path with POST should fail'

    RESULT=$( $CURL $OUPUT_ONLY_RESPONSE_CODE $JSON_CONTENT_TYPE -XDELETE localhost:8989/api.php )
    ASSERT_EQUAL $RESULT '404' 'empty path with DELETE should fail'

    group_end 'general'
}


main() {

    initialize_data

    begin_statistics

    # execute tests
    test_generel
    test_get_users
    test_registration
    test_delete_user

    print_statistics
}

main
