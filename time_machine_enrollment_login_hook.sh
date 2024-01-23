#!/bin/bash

LOG_FILE="/var/log/login_hook.log"
KEY_FILE="/etc/timemachine_key"
NETWORK_SHARE="smb://path.to.share/time_machine"

# Function to log messages
log_message() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

# Function to log error messages
log_error() {
  log_message "ERROR: $1"
}

# Check if Time Machine backups are already configured with the desired settings
check_time_machine_config() {
  existing_destinations=$(tmutil destinationinfo)
  
  # Perform additional checks and comparisons here based on your desired settings
  # For example, check if the existing destinations match the desired network share and encryption key
  if echo "$existing_destinations" | grep -q "YOUR_DESIRED_NETWORK_SHARE" && \
     echo "$existing_destinations" | grep -q "YOUR_DESIRED_ENCRYPTION_KEY"; then
    return 0  # Backup settings match desired settings
  else
    return 1  # Backup settings do not match desired settings
  fi
}

# Read the Time Machine encryption key from the key file
read_encryption_key() {
  if [ -r "$KEY_FILE" ]; then
    TIMEMACHINE_KEY=$(cat "$KEY_FILE")
  else
    log_error "Unable to read the encryption key file."
    exit 1
  fi
}

# Configure Time Machine backups
configure_time_machine() {
  log_message "Configuring Time Machine backups..."

  # Mount the network share using the user's credentials
  log_message "Mounting the network share..."
  if ! mount_smbfs -N "$NETWORK_SHARE" "/time_machine" 2>> "$LOG_FILE"; then
    log_error "Failed to mount the network share."
    exit 1
  fi

  # Set the encryption key for the network share
  log_message "Setting the encryption key..."
  if ! echo "$TIMEMACHINE_KEY" | tmutil setdestination -p "/time_machine" 2>> "$LOG_FILE"; then
    log_error "Failed to set the encryption key for the network share."
    exit 1
  fi

  # Enable Time Machine backups
  log_message "Enabling Time Machine backups..."
  if ! tmutil enable 2>> "$LOG_FILE"; then
    log_error "Failed to enable Time Machine backups."
    exit 1
  fi

  log_message "Time Machine backups configured successfully."
}

# Main script execution

# Check if Time Machine backups are already configured with the desired settings
check_time_machine_config

if [ $? -eq 0 ]; then
  log_message "Time Machine backups are already configured with the desired settings."
else
  read_encryption_key
  configure_time_machine
fi

exit 0
