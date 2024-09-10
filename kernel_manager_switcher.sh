#!/bin/bash

# Function to detect the package manager
detect_package_manager() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ $ID == "ubuntu" || $ID == "debian" ]]; then
            PACKAGE_MANAGER="apt"
        elif [[ $ID == "centos" || $ID == "rhel" || $ID == "almalinux" || $ID == "rocky" ]]; then
            if command -v yum &> /dev/null; then
                PACKAGE_MANAGER="yum"
            elif command -v dnf &> /dev/null; then
                PACKAGE_MANAGER="dnf"
            else
                echo "Neither yum nor dnf found. Exiting."
                exit 1
            fi
        elif [[ $ID == "fedora" ]]; then
            PACKAGE_MANAGER="dnf"
        else
            echo "Unsupported OS. Exiting."
            exit 1
        fi
    else
        echo "/etc/os-release not found. Exiting."
        exit 1
    fi
}

# Function to show running kernel
show_running_kernel() {
    echo ""
    echo "----------------------------------------------------------------------------------------"
    echo "Current running kernel:"
    echo
    uname -r
    echo
    uname -a
    echo "----------------------------------------------------------------------------------------"
    echo ""
}

# Function to list available kernels
list_available_kernels() {
    echo ""
    echo "Available kernels:"
    echo
    if [ "$PACKAGE_MANAGER" == "apt" ]; then
        apt-cache search linux-image
    elif [ "$PACKAGE_MANAGER" == "yum" ]; then
        yum list available 'kernel*' | grep kernel
    elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
        dnf list available 'kernel*' | grep kernel
    fi
    echo ""
}

# Function to search for kernels
search_kernels() {
    echo ""
    echo "Search for kernels:"
    echo
    echo "1. List all available kernels"
    echo "2. Filter kernels by regular expression"
    echo "- <---- 'b' To go back to main menu"
    echo "-----------------------------------------------------"
    echo -n "Choose an option: "
    read search_option
    echo ""

    # Check if the user pressed enter without providing input
    if [[ -z "$search_option" ]]; then
        echo "Invalid option. Press enter to return to the search menu."
        read -p "" enter
        search_kernels
    fi

    if [ "$search_option" == "1" ]; then
        list_available_kernels
    elif [ "$search_option" == "2" ]; then
        echo
        echo -n "Enter the regular expression to filter kernels: "
        read regex
        echo ""

        if [[ -z "$regex" ]]; then
            echo "No input was passed."
            echo
            read -p "Press enter to go back to the search menu: " enter
            search_kernels
        else
            if [ "$PACKAGE_MANAGER" == "apt" ]; then
                output=$(apt-cache search linux-image | grep -E "$regex")
            elif [ "$PACKAGE_MANAGER" == "yum" ]; then
                output=$(yum --showduplicates list kernel | grep -E "$regex")
            elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
                output=$(dnf --showduplicates list kernel | grep -E "$regex")
            else
                echo "Package manager not recognized."
                return
            fi

            if [[ -z "$output" ]]; then
                echo "No results found for the specified pattern."
                echo
                read -p "Press enter to go back to the search menu: " enter
                search_kernels
            else
                echo "Found linux kernels with regex: $regex"
                echo
                echo "$output"
                echo "--------------------------------------------------------------------------------------"
            fi
        fi
    elif [ "$search_option" == "b" ]; then
        read -p "Press enter to go back to the main menu: " enter
        main_menu
    else
        echo "Invalid option. Press enter to return to the search menu."
        read -p "" enter
        search_kernels
    fi
}

# Function to install a kernel
install_kernel() {
    echo
    echo "Before installing a kernel, you can either list all available, or search for a specific kernel version. "
    search_kernels
    echo "- <---- 'b' To go back to main menu"
    echo
    echo -n "Enter the kernel package name to install: "
    read kernel_package

    if [ "$kernel_package" == 'b' ]; then
        echo
        read -p "Press enter to return to main menu: " enter
        main_menu
    elif [ -z "$kernel_package" ]; then
        echo
        echo "----------------------------------------------------------------"
        read -p "No input was provided. Press enter to return to install kernel menu: " enter
        install_kernel
    elif [ "$PACKAGE_MANAGER" == "apt" ]; then
        echo
        # Run the search command and store the output
        output=$(apt-cache search linux-image | grep kernel)
    elif [ "$PACKAGE_MANAGER" == "yum" ]; then
        echo ""
        output=$(yum list available 'kernel*' | grep kernel)
    elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
        echo ""
        output=$(dnf list available 'kernel*' | grep kernel)
        # Check if the output is empty
    else
        echo "Package manager not recognized. Exiting."
        exit 1
    fi

    if [[ -z "$output" ]]; then
        echo
        echo "No results found for the specified pattern. Unable to install kernel: $kernel_package"
        echo
        read -p "Press enter to go back to the main menu: " enter
        main_menu
    elif [[ -z "$kernel_package" ]]; then
        echo
        echo "No input data was passed."
        echo
        read -p "Press enter to go back to the main menu: " enter
        main_menu
    else
        echo ""
        echo "Installing kernel $kernel_package using "$PACKAGE_MANAGER"..."
        echo
        sudo $PACKAGE_MANAGER install -y "$kernel_package"
        echo ""
    fi

    echo ""
    # Re-list kernels to show the updated list
    KERNELS=$(find /boot -name "vmlinuz-*" ! -name "*rescue*" -type f -print | grep -E "^/boot/vmlinuz-[^/]+$" | xargs ls -1 | sort -V)
    echo
    echo "Updated list of kernels:"
    echo
    echo "$KERNELS"
    echo
}

# Function to uninstall a kernel
uninstall_kernel() {
    echo ""
    echo "Installed kernels:"
    echo
    if [ "$PACKAGE_MANAGER" == "apt" ]; then
        echo ""
        dpkg --list | grep -E "^ii  linux-image"
    elif [ "$PACKAGE_MANAGER" == "yum" ]; then
        echo ""
        yum list installed 'kernel*'
    elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
        echo ""
        dnf list installed 'kernel*'
    fi
    echo
    echo "----------------------------------------------------------------"
    echo "- <---- 'b' To go back to main menu"
    echo
    echo -n "Enter the kernel package name to uninstall: "
    read kernel_package

    if [ "$kernel_package" == 'b' ]; then
        echo
        read -p "Press enter to return to main menu: " enter
        main_menu
    elif [ -z "$kernel_package" ]; then
        echo
        echo "----------------------------------------------------------------"
        read -p "No input was provided. Press enter to return to the uninstall kernel menu: " enter
        uninstall_kernel

    elif [ "$PACKAGE_MANAGER" == "apt" ]; then
        echo ""
        output=$(dpkg --list | grep -E "^ii  linux-image" | grep -E "$kernel_package")
    elif [ "$PACKAGE_MANAGER" == "yum" ]; then
        echo ""
        output=$(yum list installed 'kernel*' | grep -E "$kernel_package")
    elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
        echo ""
        output=$(dnf list installed 'kernel*' | grep -E "$kernel_package")
    else
        echo "Package manager not recognized. Exiting."
        exit 1
    fi
    # Check if the output is empty
    if [[ -z "$output" ]]; then
        echo
        echo "No results found for the specified pattern. Unable to install kernel: $kernel_package"
        echo
        read -p "Press enter to go back to the main menu: " enter
        main_menu
    elif [[ -z "$kernel_package" ]]; then
        echo
        echo "No input data was passed."
        echo
        read -p "Press enter to go back to the main menu: " enter
        main_menu
    else
        echo "Uninstalling kernel $kernel_package using "$PACKAGE_MANAGER"..."
        echo
        if [ "$PACKAGE_MANAGER" == "apt" ]; then
          sudo apt-get remove -y "$kernel_package"

          # Check for residual config files and purge them
          purge_status=$(dpkg --list | grep "^rc" | grep "$kernel_package")
          if [ -n "$purge_status" ]; then
              echo "Purging residual configuration for $kernel_package..."
              echo
              echo "Running apt autoremove to clean up any unused dependencies..."
              echo
              sudo apt autoremove -y
              sudo apt-get purge -y "$kernel_package"
          fi
        elif [ "$PACKAGE_MANAGER" == "yum" ]; then
          echo ""
          echo "Uninstalling kernel $kernel_package using yum..."
          echo
          sudo yum remove -y "$kernel_package"
        elif [ "$PACKAGE_MANAGER" == "dnf" ]; then
          echo ""
          echo "Uninstalling kernel $kernel_package using dnf..."
          echo
          sudo dnf remove -y "$kernel_package"
        fi
    fi

    echo ""
    echo "Kernel $kernel_package uninstalled."
    echo ""
    # Re-list kernels to show the updated list
    KERNELS=$(find /boot -name "vmlinuz-*" ! -name "*rescue*" -type f -print | grep -E "^/boot/vmlinuz-[^/]+$" | xargs ls -1 | sort -V)
    echo
    echo "Updated list of kernels:"
    echo
    echo "$KERNELS"
    echo
}

switch_kernel_module() {
    # Check if kexec-tools are installed
  if ! command -v kexec >/dev/null 2>&1; then
    printf "kexec is not installed. " >&2
    if command -v apt-get >/dev/null 2>&1; then
      printf "Try installing it using: sudo DEBIAN_FRONTEND=noninteractive apt-get install kexec-tools\n" >&2
    elif command -v yum >/dev/null 2>&1; then
      printf "Try installing it using: sudo yum -y install kexec-tools\n" >&2
    elif command -v dnf >/dev/null 2>&1; then
      printf "Try installing it using: sudo dnf -y install kexec-tools\n" >&2
    elif command -v pacman >/dev/null 2>&1; then
      printf "Try installing it using: sudo pacman -S kexec-tools\n" >&2
    else
      printf "Please install kexec-tools using your package manager.\n" >&2
    fi
    exit 1
  fi

  # Function to find the initram image for a kernel
  find_initrd() {
    KERNEL_VERSION=$(basename "$1" | sed -e 's/vmlinuz-//')

    # Check common names for initram
    for PREFIX in initrd initrd.img initramfs; do
      for SUFFIX in "" ".img" "-generic" "-current" "-default"; do
        INITRD_PATH="/boot/${PREFIX}-${KERNEL_VERSION}${SUFFIX}"
        if [ -f "$INITRD_PATH" ]; then
          echo "$INITRD_PATH"
          return
        fi
      done
    done
    echo ""
  }

  # Function to load and execute selected kernel
  kexec_kernel() {
    KERNEL=$1
    INITRD=$(find_initrd "$KERNEL")

    if [ -z "$INITRD" ]; then
      echo
      echo "No matching initram file found for kernel: $KERNEL" >&2
      echo
      read -p "Press enter to go back to the menu selector: " enter
      switch_kernel_module
    fi

    # Execute kexec to load the kernel and initram. Remove /boot from name
    echo
    echo "Loading kernel: $(echo "$KERNEL" | sed -e 's|/boot/||')"
    echo
    echo "Loading initrd: $(echo "$INITRD" | sed -e 's|/boot/||')"
    echo
    kexec -l "$KERNEL" --initrd="$INITRD" --reuse-cmdline

    echo
    # Execute kexec to boot into selected kernel
    echo "Booting to selected kernel..."
    kexec -e
  }

  # Check for --latest argument
  if [ "$1" = "--latest" ]; then
    # Find the latest kernel based on version sort
    LATEST_KERNEL=$(find /boot -name "vmlinuz-*" ! -name "*rescue*" -type f -print | grep -E "^/boot/vmlinuz-[^/]+$" | sort -V | tail -n 1)

    if [ -z "$LATEST_KERNEL" ]; then
      echo
      printf "No kernels found in /boot.\n" >&2
      exit 1
    fi

    echo
    printf "The latest kernel found is: %s\n" "$(basename "$LATEST_KERNEL" | sed -e 's/vmlinuz-//')"
    printf "Booting to latest kernel...\n"
    kexec_kernel "$LATEST_KERNEL"
    exit 0
  fi

  # Check for --current argument
  if [ "$1" = "--current" ]; then
    CURRENT_KERNEL=$(find /boot -name "vmlinuz-$(uname -r)")

    if [ -z "$CURRENT_KERNEL" ]; then
      echo
      printf "No matching kernel file found for the current running kernel.\n" >&2
      exit 1
    fi

    echo
    printf "Current running kernel is: %s\n" "$(basename "$CURRENT_KERNEL" | sed -e 's/vmlinuz-//')"
    echo
    printf "Booting to current running kernel...\n"
    echo
    kexec_kernel "$CURRENT_KERNEL"
    exit 0
  fi

  # Check for --install argument
  if [ "$1" = "--install" ]; then
    install_kernel
    exit 0
  fi

  # Check for --uninstall argument
  if [ "$1" = "--uninstall" ]; then
    uninstall_kernel
    exit 0
  fi

  # List the vmlinuz files in /boot, excluding rescue entries
  KERNELS=$(find /boot -name "vmlinuz-*" ! -name "*rescue*" -type f -print | grep -E "^/boot/vmlinuz-[^/]+$" | xargs ls -1 | sort -V)

  # Count number of kernels found
  NUM_KERNELS=$(echo "$KERNELS" | wc -l | tr -d '[:space:]')

  # If no kernels are found, exit script
  if [ "$NUM_KERNELS" -eq 0 ]; then
    echo
    printf "No vmlinuz kernels found in /boot.\n" >&2
    exit 1
  fi

  # Show running kernel
  echo "########################################################"
  echo "              LINUX VERSION KERNEL MANAGER              "
  echo "########################################################"
  echo
  CURRENT_KERNEL=$(uname -r)
  echo
  cat /etc/os-release
  echo
  echo "-----------------------------------------------------------------------"
  printf "The running kernel is: %s\n" "$CURRENT_KERNEL"

  # If only one kernel is installed, ask user to reboot into running kernel
  if [ "$NUM_KERNELS" -eq 1 ]; then
    echo
    printf "Only one kernel found: %s\n" "$(basename "$KERNELS" | sed -e 's/vmlinuz-//')"
    echo
    echo "WARNING: The following prompt will run kexec, and boot into the new kernel. "
    echo "It is recommended to run this locally, as all ssh or remote connections will terminate."
    echo
    printf "Would you like to kexec into this kernel, and switch to it now? (y/n): "
    read ANSWER
    case "$ANSWER" in
      [yY]|[yY][eE][sS])
        kexec_kernel "$KERNELS"
        ;;
      *)
        echo
        echo "Kernel kexec operation aborted."
        echo
        read -p "Press enter to return to the menu: " enter
        main_menu
        ;;
    esac
  else
    # If more than one kernel is found, prompt for user choice
    echo
    date
    echo
    echo "NOTE: The script should be executed locally, not remotely, as it will terminate the session. "
    echo
    printf "Select the kernel to kexec boot into:\n"
    echo
    echo "----------------------------------------------------------------------"
    echo
    INDEX=1
    for KERNEL in $KERNELS; do
      printf "%d) %s\n" "$INDEX" "$(basename "$KERNEL" | sed -e 's/vmlinuz-//')"
      INDEX=$((INDEX + 1))
    done

    # Prompt for user input
    echo
    echo "----------------------------------------------------------------------"
    echo
    echo "WARNING: Providing a valid kernel id, will boot inmediately into the kernel"
    echo
    echo "- <---- 'b' To go back to main menu"
    echo
    printf "Enter kernel line number to boot into it now: "
    read CHOICE

    # Check if the choice is non-empty, numerical, and within the valid range
    case "$CHOICE" in
      ''|*[0-9]*)
        if [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "$NUM_KERNELS" ]; then
          echo
          printf "Please enter a number from 1 to %d.\n" "$NUM_KERNELS"
          echo
          read -p "Press enter to proceed to the menu: " enter
          switch_kernel_module
        else
          echo
          SELECTED_KERNEL=$(echo "$KERNELS" | sed -n "${CHOICE}p")
          echo
          printf "You have selected: %s\n" "$(basename "$SELECTED_KERNEL" | sed -e 's/vmlinuz-//')"
          # Run kexec
          kexec_kernel "$SELECTED_KERNEL"
          switch_kernel_module
          read -p "Invalid input. Press enter to go back to the previous menu: " enter
        fi
        ;;
      *)
        if [ "$CHOICE" == 'b' ]; then
          echo
          read -p "Press enter to go back to main menu: " enter
          main_menu
        else
          echo
          read -p "Invalid input. Press enter to go back to the previous menu: " enter
          switch_kernel_module
        fi
        ;;
    esac
  fi
}

# Main menu loop
main_menu() {
    detect_package_manager
    while true; do
        echo
        date
        echo
        echo "************************************"
        echo "*      Kernel Management Console   *"
        echo "************************************"
        echo ""
        echo "1. Show running kernel"
        echo ""
        echo "2. Install a kernel"
        echo ""
        echo "3. Uninstall a kernel"
        echo ""
        echo "4. Search for kernels"
        echo ""
        echo "5. Show installed kernels | Switch to an existing kernel"
        echo ""
        echo "6. Exit"
        echo ""
        echo -n "Choose an option: "
        read choice
        case $choice in
            1) show_running_kernel ;;
            2) install_kernel ;;
            3) uninstall_kernel ;;
            4) search_kernels ;;
            5) switch_kernel_module ;;
            6) exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac
        echo -n "Press Enter to return to the main menu..."
        read
        echo ""
    done
}

# Run the main menu
main_menu
