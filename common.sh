# Some settings and functions common to all scripts
caCertPath=cacerts

sedCmd() {
    local script="$1"
    local file="$2"
    case "$(uname -sr)" in
        Darwin*)
             sed -i .bak "$script" "$file"
             ;;
        Linux*)
             sed -i.bak -e "$script" "$file"
             ;;
        *)
             sed -i.bak -e "$script" "$file"
             ;;
    esac
}

# These are constants which are used either here or in other code areas
validCharacters='[\~\!\@\#\$\%\^\*\_\+\-\=\{\}\[\]\:\,\.\/]'
invalidCharacters='[\`\&\(\)\|\\\"\;\<\>\?]'


# Usage - this example uses pfxPassword as the one to check.
# Password being checked for validity be escaped using this code:
# pfxPassword="$(echo "${3}" | sed -e 's/[]\/$*.^|[]/\\&/g')"
# Then pass it to this function using the following syntax
# if validPassword "$pfxPassword"; then
#    pfxPassword=$(echo "${pfxPassword}" | sed -e 's/\\//g')
#else
#    exit 1
#fi
validPassword() {
    local passwordToCheck="$1"
    local checkPassword
    VALID=true
    secondTry=false
    for (( ;; )); do
        if [[ "$secondTry" == false ]]; then
                checkPassword=$passwordToCheck
            fi
        if grep -q -e "$invalidCharacters" <<< "$(echo "${checkPassword}" | sed -e 's/\\//g')"; then
            VALID=false
        else
            VALID=true
        fi
        if [[ "$VALID" == "true" ]]; then
            # valid password; break out of the loop
            echo "Password accepted."
            return 0
        else
            echo "Invalid password: $checkPassword"
            echo "Your Password contains invalid special characters eg: ${invalidCharacters//\\/}."
            echo "Valid special characters are ${validCharacters//\\/}"
            read -r -s -p "Please re-enter the password: " checkPassword
            checkPassword="$(echo "${checkPassword}" | sed -e 's/[]\/$*.^|[]/\\&/g')"
            secondTry=true
        fi
        echo
    done
    return 1
}



# Usage
# Password being checked for validity be escaped using this code:
# caPassword="$(echo "${2}" | sed -e 's/[]\/$*.^|[]/\\&/g')"
# Then pass it to this function using the following syntax
# if checkCAPassword "$caPassword"; then
     # this line reverts the password so you can use it in your code later
#    caPassword=$(echo "${caPassword}" | sed -e 's/\\//g')
#else
#    exit 1
#fi
checkCAPassword() {
    local caPassword="$1"
    VALID=true
    myCAPrivateKey=( "$caCertPath"/*.key )
    command="openssl rsa -check -in ${myCAPrivateKey[0]} -passin pass:${caPassword} &> /dev/null"
    secondTry=false
    for (( ;; )); do
        if ! eval "$command" || false
        then
            VALID=false
        else
            VALID=true
        fi
        if [[ "$VALID" == "true" ]]; then
            # valid password; break out of the loop
            echo "CA Password accepted."
            return 0
        else
            echo "Invalid password for CA private key."
            echo "Please try again."
            echo
            read -r -s -p "Please enter the password for your CA to issue certificates: " checkCAPassword
            checkCAPassword="$(echo "${checkCAPassword}" | sed -e 's/[]\/$*.^|[]/\\&/g')"
            command="openssl rsa -check -in ${myCAPrivateKey[0]} -passin pass:${checkCAPassword} &> /dev/null"
            echo
            secondTry=true
        echo
        fi
        echo
    done

}

