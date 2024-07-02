#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Check if the file argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <user_list_file>"
    exit 1
fi

USER_LIST_FILE=$1

# Check if the file exists
if [ ! -f $USER_LIST_FILE ]; then
    echo "File not found!"
    exit 1
fi

# Log file
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Create the secure directory if it doesn't exist
mkdir -p /var/secure
chmod 700 /var/secure

# Initialize the password file
echo "username,password" > $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

while IFS=';' read -r username groups; do
    # Ignore leading/trailing whitespace
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Create user if not exists
    if id "$username" &>/dev/null; then
        echo "User $username already exists." | tee -a $LOG_FILE
    else
        useradd -m -s /bin/bash "$username"
        echo "User $username created." | tee -a $LOG_FILE

        # Set up home directory permissions
        chmod 700 /home/$username
        chown $username:$username /home/$username

        # Generate a random password
        password=$(openssl rand -base64 12)
        echo "$username:$password" | chpasswd

        # Store the password
        echo "$username,$password" >> $PASSWORD_FILE
        echo "Password for $username stored." | tee -a $LOG_FILE
    fi

    # Create groups and add user to groups
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(echo "$group" | xargs)
        if [ -z "$group" ]; then
            continue
        fi
        if ! getent group "$group" > /dev/null; then
            groupadd "$group"
            echo "Group $group created." | tee -a $LOG_FILE
        fi
        usermod -aG "$group" "$username"
        echo "User $username added to group $group." | tee -a $LOG_FILE
    done
done < "$USER_LIST_FILE"
