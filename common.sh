
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
#validCharacters='[\~\!\@\#\$\%\^\*\_\+\-\=\{\}\[\]\:\,\.\/]'
validCharacters='[\~\!\@\#\$\%\^\*\_\+]'
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

#compare version numbers of two OS versions or floating point numbers including ascii characters
compare_numbers() {
    #echo "Comparing $1 and $2"
    IFS='.' read -r -a os1 <<< "$1"
    IFS='.' read -r -a os2 <<< "$2"

    counter=0

    if [[ "${#os1[@]}" -gt "${#os2[@]}" ]]; then
        counter="${#os1[@]}"
    else
        counter="${#os2[@]}"
    fi

    for (( k=0; k<counter; k++ )); do

        # If the arrays are different lengths and we get to the end, then whichever array is longer is greater
        if [[ "${os1[$k]:-}" ]] && ! [[ "${os2[$k]:-}" ]]; then
            echo "gt"
            return 0
        elif [[ "${os2[$k]:-}" ]] && ! [[ "${os1[$k]:-}" ]]; then
            echo "lt"
            return 0
        fi

        if [[ "${os1[$k]}" != "${os2[$k]}" ]]; then
            t1="${os1[$k]}"
            t2="${os2[$k]}"

            alphat1=${t1//[^a-zA-Z]}; alphat1=${#alphat1}
            alphat2=${t2//[^a-zA-Z]}; alphat2=${#alphat2}

            # replace alpha characters with ascii value and make them smaller for comparison
            if [[ "$alphat1" -gt 0 ]]; then
                temp1=""
                for (( j=0; j<${#t1}; j++ )); do
                    if [[ ${t1:$j:1} = *[[:alpha:]]* ]]; then
                        g=$(LC_CTYPE=C printf '%d' "'${t1:$j:1}")
                        g=$((g-40))
                        temp1="$temp1$g"
                    else
                        temp1="$temp1${t1:$j:1}"
                    fi

                done
                t1="$temp1"
            fi
            # replace alpha characters with ascii value and make them smaller for comparison
            if [[ "$alphat2" -gt 0 ]]; then
                temp2=""
                for (( j=0; j<${#t2}; j++ )); do
                    if [[ ${t2:$j:1} = *[[:alpha:]]* ]]; then
                        g=$(LC_CTYPE=C printf '%d' "'${t2:$j:1}")
                        g=$((g-40))
                        temp2="$temp2$g"
                    else
                        temp2="$temp2${t2:$j:1}"
                    fi

                done
                t2="$temp2"
            fi

            if [[ "$t1" -gt "$t2" ]]; then
                echo "gt"
                return 0
            elif [[ "$t1" -lt "$t2" ]]; then
                echo "lt"
                return 0
            fi
        fi
    done

    echo "eq"
    return 0

}

# compares two numbers n1 > n2 including floating point numbers
gt() {
    result=$(compare_numbers "$1" "$2")
    if [[ "$result" == "gt" ]]; then
        return 0
    else
        return 1
    fi
}

# compares two numbers n1 > n2 including floating point numbers
lt() {
    result=$(compare_numbers "$1" "$2")
    if [[ "$result" == "lt" ]]; then
        return 0
    else
        return 1
    fi
}

# compares two numbers n1 >= n2 including floating point numbers
ge() {
    result=$(compare_numbers "$1" "$2")
    if [[ "$result" == "gt" ]]; then
        return 0
    elif [[ "$result" == "eq" ]]; then
        return 0
    else
        return 1
    fi
}

# compares two numbers n1 >= n2 including floating point numbers
le() {
    result=$(compare_numbers "$1" "$2")
    if [[ "$result" == "lt" ]]; then
        return 0
    elif [[ "$result" == "eq" ]]; then
        return 0
    else
        return 1
    fi
}

# compares two numbers n1 == n2 including floating point numbers
eq() {
    result=$(compare_numbers "$1" "$2")
    if [[ "$result" == "eq" ]]; then
        return 0
    else
        return 1
    fi
}

