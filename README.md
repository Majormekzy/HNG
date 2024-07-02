# HNG
# Linux User Management Script

## Introduction

Managing users and groups on a Linux system can be a time-consuming task, especially when dealing with multiple new employees. This script automates the creation of users and groups, sets up home directories, generates random passwords, logs actions, and securely stores the passwords. This project aims to simplify the user and group management process, making it efficient and consistent.

## Features
- Reads a text file containing usernames and group names.
- Creates users and groups as specified.
- Sets up home directories with appropriate permissions.
- Generates random passwords for the users.
- Logs all actions to `/var/log/user_management.log`.
- Stores generated passwords securely in `/var/secure/user_passwords.csv`.

## Prerequisites
- **Root Privileges:** The script must be run with root privileges to manage users and groups.
- **User List File:** The script reads from a text file (`users.txt`) containing usernames and groups. Each line in the file should be formatted as `username;group1,group2,...`.

## Usage
**1. Clone the Repository:**
   ```bash
   git clone https://github.com/yourusername/linux-user-management.git
   cd linux-user-management
   ```
**2. Create the `create_users.sh` Script:**
   Create a file named `create_users.sh` and make it executable:
   ```bash
   touch create_users.sh
   chmod +x create_users.sh
   ```

3. **Add the Script Content:**
   Copy the following content into the `create_users.sh` file:

   ```bash
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
   ```

4. **Create the User List File:**
   Create a file named `users.txt` with the following content:
   ```plaintext
   john; admin,developers
   jane; admin,designers
   doe; developers,designers
   ```

5. **Run the Script:**
   Ensure you have the `users.txt` file in the same directory as your script. Then, run the script:
   ```bash
   sudo ./create_users.sh users.txt
   ```

6. **Verify the Results:**
   - Check the log file: `cat /var/log/user_management.log`
   - Check the password file: `sudo cat /var/secure/user_passwords.csv`

## Technical Article

For a detailed explanation of the script, please read [this article](https://medium.com/@emmyjones4u/automating-user-and-group-management-on-linux-with-a-bash-script-05ec604cd5c2) on Medium.

## Links

- [HNG Internship](https://hng.tech/internship)
- [HNG Hire](https://hng.tech/hire)

## Author

Emeka Machie

```
By following these steps, your `README.md` file will be updated with comprehensive information and the link to your detailed article on Medium. If you need further assistance, feel free to ask!
