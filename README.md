# Tester

The purpose of the tester program is to run a given program for a given set of inputs (text files, by default in the ```tests``` directory) and compare the results to a given set of expected answers (text files, by default in the ```answers``` directory, with names corresponding to the test names). Information whether the program succeeded, failed (by wrong answer), ended with an error or timed-out is given.

## How to use

To run the program, the tested program name should be given as one of the arguments, along with possible options:

```-a```, ```--answers-directory``` - set answers directory to the directory specified after this option

```-d```, ```--tests-directory``` - set tests directory to the directory specified after this option

```-f```, ```--filter``` - filter tests according to grep filter specified after this option

```-F```, ```--formatting``` - set formatting to one defined by the string following this option see details in Formatting section

```-h```, ```--help``` - display help and exit

```-m```, ```--memory``` - report memory use (in kB)

```-M```, ```--memory-limit``` - limit memory available to the program to amount specified after this option in kB, if the limit is exceeded the program execution will end with an error

```-n```, ```--newline``` - end report from each test with a newline

```-s```, ```--short``` - skip error information and Received/Expected message

```-t```, ```--time``` - report execution time, in [hours:]minutes:seconds

```-T```, ```--time-limit``` - set time limit to value specified after this option in seconds, if the time limit is exceeded timeout message is reported

### Formatting

Default formatting is bold green for success, bold yellow for timeout, bold red for failure or error, bold white for other important information.
If formatting option is set, no formatting is applied by the default and all formatting must be specified in the string following the option.

Each message type has its code in formatting string:

```%e``` - error

```%i``` - additional important information (time, memory, Received/Expected)

```%f``` - failure

```%s``` - success

```%t``` - timeout

The fomatting string should contain the codes of message type followed by SGR (Select Graphic Rendition) parameters specifying formatting. The '\033[' escape sequence and 'm' closing literal should be ommitted.

### Example

To test a ```prog``` program using tests from ```input``` directory compared to answers from ```expected``` directory with reported time and memory use, time limit set to 1s and memory limit set to 8000 kB (using only tests containing a digit, given formatting of blue text for success, bold yellow for failure, underlined magenta for timeout and red backgound for failure) following command should be used:

```
./tester.sh prog -d input -a expected -t -m -T 1 -M 8000 -f [0-9] -F "%s34%f1;33%t4;35%e41"
```


