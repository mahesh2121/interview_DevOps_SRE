Bash Scripting Notes
1. Introduction to Bash Scripting

    Purpose: Automate repetitive tasks in Linux.

    Common Use Cases: File management, system monitoring, backups, sending emails, etc.

    Advantages: Built-in on Linux systems, no additional tools required.

2. Basics of Bash Scripting

    Shell: A command-line interface that interprets user commands and communicates with the operating system.

    Bash Shell: The most commonly used shell in Linux.

    Script: A text file containing a sequence of commands and logic to automate tasks.

3. Creating a Bash Script

    Shebang: The first line of a script, #!/bin/bash, tells the system to use the Bash shell.

    File Extension: Scripts typically end with .sh (e.g., script.sh).

    Permissions: Use chmod +x script.sh to make the script executable.

4. Running a Bash Script

    Relative Path: ./script.sh

    Absolute Path: /path/to/script.sh

    Using Bash: bash script.sh (does not require execute permission).

    Adding to PATH: Add the script's directory to the PATH variable to run it from anywhere.

5. Variables

    Definition: A variable stores a value in memory for later use.

    Syntax: variable_name=value

        Strings: Use quotes (name="Adam").

        Numbers: No quotes needed (age=30).

    Retrieving Values: Use $variable_name (e.g., echo $name).

    Scope:

        Local Variables: Available only within the script.

        Environment Variables: Available in the parent and child shells (use export).

6. Special Variables

    $0: Name of the script.

    1,1,2, ...: Positional parameters (arguments passed to the script).

    $#: Total number of arguments.

    $@: All arguments passed to the script.

    $$: Process ID of the current script.

    $?: Exit status of the last command (0 = success, non-zero = error).

7. Operators

    Arithmetic Operators: +, -, *, /, % (use expr for calculations).

        Example: result=$(expr $a + $b)

    Relational Operators: -eq, -ne, -gt, -lt, -ge, -le (used in conditions).

    String Operators: =, !=, -z (check if string is empty), -n (check if string is not empty).

    File Test Operators: -r (readable), -w (writable), -x (executable), -f (file exists), -d (directory exists), -s (file size > 0).

8. Decision Making (Conditionals)

    If Statement:
    bash
    Copy

    if [ condition ]; then
      # code to execute if condition is true
    fi

    If-Else Statement:
    bash
    Copy

    if [ condition ]; then
      # code if true
    else
      # code if false
    fi

    If-Elif-Else:
    bash
    Copy

    if [ condition1 ]; then
      # code if condition1 is true
    elif [ condition2 ]; then
      # code if condition2 is true
    else
      # code if all conditions are false
    fi

    Case Statement:
    bash
    Copy

    case $variable in
      pattern1)
        # code for pattern1
        ;;
      pattern2)
        # code for pattern2
        ;;
      *)
        # default code
        ;;
    esac

9. Loops

    For Loop:
    bash
    Copy

    for i in 1 2 3; do
      echo $i
    done

    While Loop:
    bash
    Copy

    while [ condition ]; do
      # code to execute
    done

    Until Loop:
    bash
    Copy

    until [ condition ]; do
      # code to execute
    done

10. Functions

    Definition:
    bash
    Copy

    function_name() {
      # code to execute
    }

    Calling a Function: function_name

    Arguments: Use $1, $2, etc., to access function arguments.

11. Input and Output Redirection

    Input Redirection: < (read from a file).

    Output Redirection: > (overwrite), >> (append).

    Example:
    bash
    Copy

    echo "Hello" > output.txt  # Writes "Hello" to output.txt
    cat input.txt              # Reads from input.txt

12. Debugging

    Verbose Mode: Use set -x to print each command before execution.

    Disable Debugging: Use set +x.

13. Advanced Topics

    Shift Command: Used to shift positional parameters (e.g., shift removes the first argument).

    Boolean Operators: -a (AND), -o (OR).

    Command Substitution: Use backticks or $(...) to capture command output.

        Example: result=$(ls)

14. Example Script
bash
Copy

#!/bin/bash

# Function to add two numbers
add() {
  result=$(expr $1 + $2)
  echo "Sum: $result"
}

# Main script
echo "Enter operation (add/subtract/multiply):"
read operation

echo "Enter first number:"
read num1

echo "Enter second number:"
read num2

case $operation in
  add)
    add $num1 $num2
    ;;
  subtract)
    result=$(expr $num1 - $num2)
    echo "Difference: $result"
    ;;
  multiply)
    result=$(expr $num1 \* $num2)
    echo "Product: $result"
    ;;
  *)
    echo "Invalid operation"
    ;;
esac

15. Best Practices

    Use meaningful variable names.

    Add comments to explain complex logic.

    Test scripts in a safe environment before deployment.

    Use set -e to exit on errors and set -u to treat unset variables as errors.

These notes summarize the core concepts of Bash scripting, including variables, operators, conditionals, loops, functions, and debugging techniques. Use these to automate tasks and improve efficiency in Linux environments.