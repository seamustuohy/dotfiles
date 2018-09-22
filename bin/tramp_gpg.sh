#!/bin/bash



#==========================
# For writing to help file.
#==========================
write_help_header()
{
    echo "\n" >> $TMPDIR/README.md
    echo "## $1" >> $TMPDIR/README.md
}

write_help()
{
    echo "$1" >> $TMPDIR/README.md
}

log()
{
    echo "$(date) : $1" >> $TMPDIR/logfile
}

#==========================
# Utilities
#==========================
check_installed() {
    log "check_installed"
    # Check for gnupg and install if not already
    dpkg -l gnupg|grep -q gnupg||sudo apt-get install -y gnupg

    # Check for secure-delete and install if not already
    dpkg -l secure-delete|grep -q secure-delete||sudo apt-get install -y secure-delete
}


#==========================
# GPG Environment Functions
#==========================
enter_temporary_home() {
    log "enter_temporary_home"
    # Create & enter temporary gpg directory
    mkdir "${TMPDIR}/gpg"

    # Change tmpDir permissions to work with gpg
    chmod 700 "${TMPDIR}/gpg"

    # Temporaraly set GNUPG directory to our temp directory
    # export GNUPGHOME="${TMPDIR}/gpg"

    # enter temporary home directory
    cd "${TMPDIR}/gpg"
}

exit_temporary_home() {
    log "exit_temporary_home"
    #Unset the GPG home from this directory so it does not mess with your current key setup
    # unset GNUPGHOME
    cd $TMPDIR
}

import_temporary_keys() {
    log "import_temporary_keys"
    # Import our keys to manipulate them
    gpg --homedir "${TMPDIR}/gpg" --import ${EMAIL_ADDR}.sec
}

#==========================
# GPG Key Manipulation
#==========================
create_keys() {
    log "create_keys"
    # Create Keys
    #
    # Using http://ekaia.org/blog/2009/05/10/creating-new-gpgkey/ as a starting place
    #
    # Key Characteristics
    # - Primary Key: RSA Signing Key 4096 bits long
    # - Sub-Key: RSA Encryption Sub-Key 4096 bits long
    #
    # Why we create a primary signature key and an encryption sub-key
    # - https://security.stackexchange.com/questions/8559/digital-certificate-deployment-using-two-certs-for-each-user/8563#8563
    # - https://security.stackexchange.com/questions/43590/gpg-why-have-separate-encryption-subkey/43591#43591

    gpg --homedir "${TMPDIR}/gpg" --batch --gen-key <<EOF
    %echo Generating Key
    %echo Primary Key = 4096 RSA Signing Key
    Key-Type: RSA
    Key-Length: 4096
    Key-Usage: sign
    %echo Sub-Key = 4096 RSA Encryption Key
    Subkey-Type: RSA
    Subkey-Length: 4096
    Subkey-Usage: encrypt
    %echo Name = ${NAME}
    Name-Real: ${NAME}
    %echo Email = ${EMAIL_ADDR}
    Name-Email: ${EMAIL_ADDR}
    %echo Expiration = ${EXPIRE_DATE_HUMAN_READ}
    Expire-Date: ${EXPIRE_DATE_GPG}
    Passphrase: ${GPG_PW}
    # Do a commit here, so that we can later print "done" :-)
    %commit
    %echo done
EOF
}

get_key_id() {
    log "get_key_id"
    log "======="
    log $1
    log "======="
    #If it ends in 'ub' then it is public
    if [[ "ub" = ${1:1} ]]
    then
        local KEY_TYPE="keys"
    else
        local KEY_TYPE="secret-keys"
    fi
    # Capture private key & sub-key id's
    local KEY=$(gpg --homedir "${TMPDIR}/gpg" --list-${KEY_TYPE} --with-colons |grep ${1} | grep -Eo "[A-F0-9]{16}")
    log $KEY_TYPE
    log $(gpg --homedir "${TMPDIR}/gpg" --list-${KEY_TYPE} --with-colons |grep ${1}  | grep -Eo "[A-F0-9]{16}")
    log $(gpg --homedir "${TMPDIR}/gpg" --list-${KEY_TYPE} --with-colons |grep ${1})
    log $(gpg --homedir "${TMPDIR}/gpg" --list-${KEY_TYPE} --with-colons)
    log $KEY
    echo "$KEY"
}

get_sig_tag() {
    log "get_sig_tag"
    #Takes two word long lower case string "[secret|public] [key|subkey]"
    #Returns the GPG signature tag.

    #Cut human readable into parts
    local SECRECY=$(echo $1 | cut -f1 -d-)
    local KEY_TYPE=$(echo $1 | cut -f2 -d-)
    #Create blank sig tag
    local SIG=""

    # private == secret
    #sec => 'SECret key'
    #ssb => 'Secret SuBkey'
    #pub => 'PUBlic key'
    #sub => 'public SUBkey

    if [[ $SECRECY = "private" ]]
    then #key is a secret key
        SIG+="s"
        if [[ $KEY_TYPE = "key" ]]
        then #key is a primary key
            SIG+="ec"
        else #key is a sub-key
            SIG+="sb"
        fi
    else #key is a public key
        if [[ $KEY_TYPE = "key" ]]
        then #key is a primary key
            SIG+="pub"
        else
            SIG+="sub"
        fi
    fi
    echo $SIG
}

get_key_id_from_description() {
    log "get key id from description"
    local TAG=$(get_sig_tag ${1})
    log $TAG
    local KEY_ID=$(get_key_id ${TAG})
    log $KEY_ID
    echo "$KEY_ID"
}

output_keys() {
    log "output_keys"

    write_help_header "GPG Key file names"
    #Outputs keys to specified directory
    local ENCRYPTION_KEYFILE=${EMAIL_ADDR}.encryption.gpg-key
    local SIGNATURE_KEYFILE=${EMAIL_ADDR}.private.gpg-key
    local PUBLIC_KEYFILE=${EMAIL_ADDR}.public.gpg-key

    log "getting private sub-key"
    # Get private encryption sub-key id
    local SUB_KEY=$(get_key_id_from_description "private subkey")

    log "getting public sub-key"
    # Get private signing key id
    local PRIV_KEY=$(get_key_id_from_description "private key")

    log "Output the encryption sub-key"
    # Output the encryption sub-key
    gpg --homedir "${TMPDIR}/gpg" --export-secret-subkeys $SUB_KEY > $ENCRYPTION_KEYFILE
    write_help "  * Encryption key filename: $ENCRYPTION_KEYFILE"

    log "Output the master signing key (WITH encryption key attached)"
    # Output the master signing key (WITH encryption key attached)
    gpg --homedir "${TMPDIR}/gpg" --export-secret-keys --armor $EMAIL_ADDR > $SIGNATURE_KEYFILE
    write_help "* Private signing key filename:  $SIGNATURE_KEYFILE"

    log "Create ASCII public key for encryption key"
    # Create ASCII public key for encryption key
    # This will be distributed via the auto-responder
    gpg --homedir "${TMPDIR}/gpg" --export --armor $EMAIL_ADDR > $PUBLIC_KEYFILE
    write_help "* Public key filename: $PUBLIC_KEYFILE"

    # TODO GENERATE  REVOCATION CERTIFICATES
    # log "Generate Revocation Certificates"
    # Generate Revocation Certificates
    # log "Generate Revocation Certificates ENCRYPTION"
    # gen_revoke $SUB_KEY 0 "General Revocation Certificate" "Encryption"
    # log "Generate Revocation SIGNING"
    # gen_revoke $PRIV_KEY 0 "General Revocation Certificate" "Signing"
}

# Generate a Revocation Certificate Function
# Copyright 2013 Baird Castleberry
# baird@bairdcastleberry.com
# https://github.com/baird/GPG/blob/master/GPGen/gpgen
gen_revoke() {
    log "gen_revoke"
    local KEYID=$1
    local CODE=$2
    local REASON=$3
    local KEY_TYPE=$4

    # Create temporary command file for revocation cert.
    local INPUTFILE="${PWD}/rev_options.tmp"
    if [ -f "$INPUTFILE" ]
    then
        rm -f "$INPUTFILE"
    fi

    log "writing revocation options to file"
    # Write revocation options to temporary command file
    touch "$INPUTFILE"
    echo "y" > "$INPUTFILE"
    echo "$CODE" >> "$INPUTFILE"
    echo "$REASON" >> "$INPUTFILE"
    echo "$GPG_PW" >> "$INPUTFILE"
    echo "y" >> "$INPUTFILE"
    echo >> "$INPUTFILE"

    log "Creating revocation certificate"
    # Create revocation certificate
    gpg --homedir "${TMPDIR}/gpg" --no-tty --command-fd 0 --status-fd 2 \
        --armor \
        --output "./${KEY_TYPE}_revocation_cert.asc" \
        --gen-revoke $KEYID < "$INPUTFILE"

    log "securely removing options file"
    # Securely remove revocation options file
    srm "$INPUTFILE"
}

get_revoker() {
    # Asks user if they would like to use their current GPG key as a revoker
    # NOT IMPLEMENTED FULLY
    # TODO Needs to get the algorithm from the key selected
    # TODO Needs to allow a user to select a private key
    read -p "Do you want to create a revoction certificate using your current key? (y/n)" USE_OLD
    if [ "$USE_OLD" = "y" ] || [ "$USE_OLD" = "Y" ]
    then
        OLD_NAME=$(gpg --homedir "${TMPDIR}/gpg" --list-secret-keys --with-colons |grep  "sec" |sed 's/.*\:\{3\}\(.*\)\:\{3\}/\1/')
        read -p "Is this the pricate key you would like to make the revoker? (y/n)" OLD_NAME_CORRECT
        if [ "$OLD_NAME_CORRECT" = "y" ] || [ "$OLD_NAME_CORRECT" = "Y" ]
        then
            readonly REV_KEY=$(gpg --homedir "${TMPDIR}/gpg" --list-secret-keys --with-colons |grep  "sec" | grep -Eo "[A-F0-9]{16}")
        fi
    fi
}

main() {
    log "main"

    echo "Checking for required packages"
    check_installed

    # echo "Entering temporary GPG build environment."
    enter_temporary_home

    echo "Creating GPG Keys"
    create_keys

    # echo "Import Temporary Keys into GPG build environment"
    # import_temporary_keys

    echo "Outputting GPG Keys & Revocation Certificates"
    echo "Get READY TO COPY PASSWORD NOW"
    sleep 5
    output_keys
    # TODO Iterate through all public keys in HOST public keys and let user pick ones they want

    # TODO Copy over selected keys into your public keyfile
    echo "Exiting temporary GPG build environment."
    exit_temporary_home

    echo "Key Generation Completed!"
    log "Completed"
}

echo "Wecome to the TRAMP GPG key generation system"

readonly TMPDIR=$1

echo "What name do you go by?"
read -e -p "Name:" NAME

echo "What is your travel e-mail for this trip?"
read -e -p "e-mail:" EMAIL_ADDR

echo "How many weeks long is your trip?"
read -e -p "Length of trip (in weeks):" WEEKS
readonly EXPIRE_DATE_HUMAN_READ="${WEEKS} Weeks"
readonly EXPIRE_DATE_GPG="${WEEKS}w"

#Get Users Password
while :; do
    echo "Please enter a passphrase for your GPG key between 0 and 2094597ish chars:"
    echo "WARNING: You cannot use the single quotes char -> ' <- in your passwords."
    read -s -r  -e -p "GPG Key Passphrase:" GPG_PW
    echo ""
    echo -n "Please Re-type your password: "
    read -s -r  -e -p "GPG Key Passphrase:" CONF_GPG_PW
    echo ""
    [ "$GPG_PW" = "$CONF_GPG_PW" ] && break
    echo "Passwords don't match! Try again."
done

#TODO Need to implement the ability for a user to specify a gpg key to use the recover for the temporary key.
#get_revoker

#Run the actual Key Generation program
echo "Don't run this. Go use a decent guide instead."
echo "i.e. https://github.com/drduh/YubiKey-Guide"
echo "This is a VERY old piece of code that should really not be used."
echo "It's just here for posterity"
echo "Exiting before you use this..."
# You can uncomment here to play with this code
exit

main


#----------------------NOTE--------------------------------------------
# If you don't want to change gpp's home dir you can get some of the way with these commands
# List out the private key fingerprints
#gpg --with-fingerprint $EMAIL_ADDR.sec
# Create ASCII public key for encryption key
#gpg --enarmor < $EMAIL_ADDR.pub > $EMAIL_ADDR.publicKey
#----------------------------------------------------------------------
