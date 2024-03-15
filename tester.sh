#! /bin/bash

help_message="Usage: $0 [OPTIONS] PROGRAM [OPTIONS]

Run the PROGRAM with inputs from tests directory and compare them
with expected results from answers directory, information about test status is given
(suceeded / failed / timed out / ended with an error)

Additional information may be displayed under test status

Default tests directory is 'tests', default answers directory is 'answers'.

Options:

  -a, --answers-directory  set answers directory to the directory specified after this option
  -d, --tests-directory    set tests directory to the directory specified after this option
  -f, --filter             filter tests according to grep filter specified after this option
  -F, --formatting         set formatting to one defined by the string following this option
                           see details in Formatting section
  -h, --help               display this help and exit
  -m, --memory             report memory use (in kB)
  -M, --memory-limit       limit memory available to the PROGRAM to amount specified after this option
                           in kB, if the limit is exceeded the program execution will end with an error
  -n, --newline            end report from each test with a newline
  -s, --short              skip error information and Received/Expected message
  -t, --time               report execution time, in [hours:]minutes:seconds
  -T, --time-limit         set time limit to value specified after this option in seconds,
                           if the time limit is exceeded timeout message is reported


Formatting

Default formatting is bold green for success, bold yellow for timeout,
bold red for failure or error, bold white for other important information.
If formatting option is set, no formatting becomes the default.

Each message type has its code in formatting string:
  %e  error
  %i  additional important information (time, memory, Received/Expected)\n
  %f  failure
  %s  success
  %t  timeout

The fomatting string should contain the codes of message type followed
by SGR (Select Graphic Rendition) parameters specifying formatting.

The '\\\\033[' escape sequence and 'm' closing literal should be ommitted.


Exit codes:
  0 - program executed correctly
  1 - invalid option
  2 - required argument ommited
  3 - failed to run a test
  4 - failed to print output (possible formatting error)
  5 - failed to filter tests
  6 - failed to limit memory
  11 - no program to test specified
  12 - program to test not found
  13 - no tests directory specified
  14 - tests directory not found
  15 - no answers directory specified
  16 - answers directory not found
  21 - invalid message type code in formatting string
  22 - invalid characters as SGR parameters in formatting string
"

# $1 - last exit code
# $2 - error message
# $3 - with what code to exit
error () {
    if [ $1 -ne 0 ] ; then
        echo -e $2 >&2
        exit $3
    fi
}


args=$(getopt -u -o htT:mM:d:a:snf:F: -l 'help,time,time-limit:,memory,memory-limit:,\
tests-directory:,answers-directory:,short,newline,filter:,formatting:' -- "$@")
error $? "Invalid option\nType '$0 --help' for help" 1

# variables
program=""
time_measure=false
time_limit=0
mem_measure=false
mem_limit=0
tests="tests"
answers="answers"
full_feedback=true
newline=false
do_filtering=false
filter=""
do_formatting=false

# style strings
success_style='\033[1;32m'
failure_style='\033[1;31m'
timeout_style='\033[1;33m'
error_style='\033[1;31m'
info_style='\033[1m'
reset_style='\033[0m'

digit_regex="^[0-9]$"
set_styles () {
    style_string=$1
    chars=$(echo $style_string | fold -w1)
    style_code=0
    # codes
    # 1 - success
    # 2 - fail
    # 3 - timeout
    # 4 - error
    # 5 - info
    for char in $chars; do
        if [ $char = "%" ]; then
            style_code=0
        else
            if [ $style_code -eq 0 ]; then
                case $char in
                    s)
                        success_str=""
                        style_code=1 ;;
                    f)
                        failure_str=""
                        style_code=2 ;;
                    t)
                        timeout_str=""
                        style_code=3 ;;
                    e)
                        error_str=""
                        style_code=4 ;;
                    i)
                        info_str=""
                        style_code=5 ;;
                    *)
                        echo "Invalid message type code in formatting string" >&2
                        exit 21
                esac
            elif [[ $char =~ $digit_regex ]] || [ $char == ";" ]; then
                case $style_code in
                    1)
                        success_str+=$char ;;
                    2)
                        failure_str+=$char ;;
                    3)
                        timeout_str+=$char ;;
                    4)
                        error_str+=$char ;;
                    5)
                        info_str+=$char ;;
                esac
            else
                echo "Invalid characters as SGR parameters in formatting string" >&2
                exit 22
            fi
        fi
    done

    success_style="\033[${success_str}m"
    failure_style="\033[${failure_str}m"
    timeout_style="\033[${timeout_str}m"
    error_style="\033[${error_str}m"
    info_style="\033[${info_str}m"
}


possible_args=( "-h" "-t" "-m" "-s" "-n" "--help" "--time" "--memory" "--short" "--newline" \
"--" "-T" "-M" "-d" "-a" "-f" "-F" "--time-limit" "--memory-limit" \
"--tests-directory" "--answers-directory" "--filter" "--formatting" )

code=0
# the next arg is:
# 0 - an option
# 1 - the tested program
# 2 - the time limit
# 3 - the memory limit
# 4 - the tests directory
# 5 - the answers directory
# 6 - the grep filter
# 7 - the formatting rules

# parsing options
for arg in $args
do
    if [ $code -eq 0 ]
    then
        prev_arg="$arg"
        case $arg in
            -h | --help)
                echo -ne "$help_message"
                exit 0
                ;;
            --)
                code=1 ;;
            -t | --time)
                time_measure=true ;;
            -T | --time-limit)
                code=2 ;;
            -m | --memory)
                mem_measure=true ;;
            -M | --memory-limit)
                code=3 ;;
            -d | --tests-directory)
                code=4 ;;
            -a | --answers-directory)
                code=5 ;;
            -s | --short)
                full_feedback=false ;;
            -n | --newline)
                newline=true ;;
            -f | --filter)
                code=6 ;;
            -F | --formatting)
                do_formatting=true
                code=7 ;;
        esac
    else
        if [[ " ${possible_args[*]} " =~ " ${arg} " ]]; then
            echo "Option $prev_arg requires an argument"
            exit 2
        fi
        case $code in
            1)
                program=$arg ;;
            2)
                time_limit=$arg ;;
            3)
                mem_limit=$arg ;;
            4)
                tests=$arg ;;
            5)
                answers=$arg ;;
            6)
                filter=$arg ;;
            7)
                set_styles $arg ;;
        esac
        code=0
    fi
done


# $1 - current name
# $2 - official name
# $3 - base exit status (+1 is used too)
check_existence () {
    if [ "$1" == "" ]; then
        echo "$2 not specified" >&2
        exit $3
    elif [ ! -e "./$1" ]; then
        echo "$2 not found" >&2
        exit $(($3+1))
    fi
}

check_existence "$program" "Program to test" 11
check_existence "$tests" "Tests directory" 13
check_existence "$answers" "Answers directory" 15

tests_list=$(ls $tests/*.txt | grep "$filter")
error $? "Test filtering failed" 5
for test in $tests_list
do
    # running tested program (with optional memory limit)
    if [ $mem_limit != "0" ]; then
        ulimit -S -v $mem_limit
        error $? "Failed to limit memory" 6
    fi

    {
        read -r -d '' errors;
        read -r -d '' output;
    } < <((printf '\0%s\0' "$(/usr/bin/time -f '%M %E' \
    timeout $time_limit ./$program < $test)" 1>&2) 2>&1)
    error $? "Failed to run a test" 3

    
    ulimit -S -v unlimited


    # variables initialization
    exit_code=255
    additional_info=""
    message=""
    # checking exit code of run program
    correct_pattern="^[0-9]+ [0-9]+:[0-9]+.[0-9]+$"
    timeout_pattern=$'^Command exited with non-zero status [0-9]+\n[0-9]+ [0-9]+:[0-9]+.[0-9]+$'
    if [[ $errors =~ $correct_pattern ]]; then
        exit_code=0
        exec_time=$(echo "$errors" | awk '{print $(NF)}')
        mem_use=$(echo "$errors" | awk '{print $(NF-1)}')
    elif [[ $errors =~ $timeout_pattern ]]; then
        exit_code=$(echo "$errors" | head -n 1 | awk '{print $NF}')
        message+="${timeout_style}"
    else
        exit_code=$(echo "$errors" | head -n 1 | awk '{print $NF}')
        additional_info+=$(echo "$errors" | head -n -1)
        additional_info+="\n"
        message+="${error_style}"
    fi


    # checking succes / failure and building feedback
    name=$(basename -- "$test")
    message+="Test $(basename $name .txt)"
    time_info=""
    mem_info=""
    case $exit_code in
        0)
            if test "$(cat $answers/$name)" = $output; then
                message="$success_style$message"
                message+=" succeeded"
            else
                message="$failure_style$message"
                message+=" failed"
                additional_info+="${info_style}Received:\n${reset_style}"
                additional_info+="$output\n"
                additional_info+="${info_style}Expected:\n${reset_style}"
                additional_info+="$(cat $answers/$name)\n"
            fi
            time_info="${info_style}time: $exec_time${reset_style}\n"
            mem_info="${info_style}memory use: ${mem_use}kB${reset_style}\n"
            ;;
        124)
            message+=" timed out" ;;
        *)
            message+=" ended with an error" ;;
    esac
    message+="${reset_style}\n"


    error_content="Failed to print output"
    $do_formatting && error_content+=" (possible formatting error)"

    # printing feedback
    echo -ne "$message"
    if $time_measure; then
        echo -ne "$time_info"
        error $? "$error_content" 4
    fi
    if $mem_measure; then
        echo -ne "$mem_info"
        error $? "$error_content" 4
    fi
    if $full_feedback; then
        echo -ne "$additional_info"
        error $? "$error_content" 4
    fi
    if $newline; then
        echo
    fi
done
