#!/data/data/com.termux/files/usr/bin/bash

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\033[0;34m"
RESET="\e[0m"

clear
echo -e "${BLUE}📦 Checking & installing dependencies...${RESET}"

# Update Termux packages & Install fastboot (termux package)
echo -e "${YELLOW}thanks for offici5l developers for fastboot adb.${RESET}"
read -p "Do you want to install adb-fastboot connection driver? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" || "$choice" == "" ]]; then
    curl -s https://raw.githubusercontent.com/offici5l/termux-adb-fastboot/main/install | bash
    else
       echo -e "${YELLOW}Continuing without adb-fastboot driver${RESET}"
    fi

# Check again
clear
if command -v adb >/dev/null 2>&1; then
    echo -e "${GREEN}[✔] ADB installed successfully.${RESET}"
    adb --version
    fastboot --version
else
    echo -e "${RED}[✘] Failed to install ADB and Fastboot. Try again manually.${RESET}"
fi

sleep 6

echo -e "${BLUE}Updating packages....${RESET}"
read -p "Do you want update termux driver? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" || "$choice" == "" ]]; then
    yes | pkg update && upgrade
    else
       echo -e "${YELLOW}Continuing without updated termux driver${RESET}"
    fi

echo -e "${BLUE}git installation...${RESET}"
yes | pkg install git

echo -e "${BLUE}setting api.....${RESET}"
pkg install termux-api

echo -e"${BLUE}Giving storage permission.......${RESET}"
termux-setup-storage -y

echo -e "${YELLOW}Done....${RESET}"

# Sleep to give time for connection
sleep 6

# Optional: Check if device is connected in fastboot mode
echo -e "${YELLOW}[~] Checking connected device (fastboot mode)...${RESET}"

# Sleep to give time for connection
sleep 6

# Check device in fastboot mode
echo -e "${YELLOW}Verification Checks......${RESET}"
echo -e "${BLUE}FIRST CONNECT YOUR DEVICE IN FASTBOOT..${RESET}"
read -p "Do you want to check fastboot serial number? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" || "$choice" == "" ]]; then
       echo -e "${BLUE}☑️ Device Detected Here If You Unable To See Device Serial Number or stuck with empty Then Check Your Device Otg Or Cable.${RESET}"
       echo -e "${YELLOW}fastboot serial number.......${RESET}"
       fastboot devices
    fi

# Sleep to give time for connection
sleep 2

clear
echo -e "${YELLOW}\n====== Created By @sukuna567 ======${RESET}"

# Source folders
SOURCE_DIRS=("/sdcard/Download" "/sdcard/Download/Telegram")
DEST_DIR="/sdcard/flasher"

# Ensure destination exists
[ -d "$DEST_DIR" ] || mkdir -p "$DEST_DIR"

# Flag to track if anything is found
found_any=false

# Loop through source directories
for dir in "${SOURCE_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo -e "${BLUE}📂 Searching in: $dir${RESET}"

    # Find files matching keywords (case-insensitive)
    matches=$(find "$dir" -maxdepth 1 -type f \( \
      -iname "*recovery*" -o \
      -iname "*magisk*.apk" -o \
      -iname "*magisk*.img" -o \
      -iname "*fastboot*.tgz" -o \
      -iname "*global*.tgz" -o \
      -iname "*fastboot*.zip" -o \
      -iname "*fastboot*.tar.gz" -o \
      -iname "*global*.tar.gz" -o \
      -iname "*global*" -o \
      -iname "*global_images*" -o \
      -iname "*images*" -o \
      -iname "*orangefox*" -o \
      -iname "*pitchblack*" -o \
      -iname "*shrp*" -o \
      -iname "*ofox*" -o \
      -iname "*twrp*" -o \
      -iname "*boot*.img" \
    \))

    # Move found files
    for file in $matches; do
      echo -e "${BLUE}📦 Found: $(basename "$file")${RESET}"
      mv -v "$file" "$DEST_DIR/"
      found_any=true
    done
  fi
done

# Final message
if [ "$found_any" = false ]; then
  echo -e "${RED}❌ No matching files found IN Download or Telegram folder🗂️📂."
else
  echo -e "${GREEN}✅ Matching files moved to $DEST_DIR${RESET}"
fi

sleep 6

clear

# === FUNCTIONS ===

FLASH_RECOVERY() {
    echo -e "${BLUE}🔍 Scanning for recovery images...${RESET}"
    mapfile -t RECOVERY_FILES < <(find /sdcard/flasher -iname "*recovery*.img" -o -iname "*twrp*.img" -o -iname "*shrp*.img" -o -iname "*ofox*.img" -o -iname "*orangefox*.img" -o -iname "*pitchblack*.img")

    if [ ${#RECOVERY_FILES[@]} -eq 0 ]; then
        echo -e "${RED}❌ No recovery image found in /sdcard/flasher/${RESET}"
        return
    elif [ ${#RECOVERY_FILES[@]} -eq 1 ]; then
        RECOVERY_PATH="${RECOVERY_FILES[0]}"
        echo -e "${GREEN}✅ Found: $RECOVERY_PATH${RESET}"
    else
        echo -e "${YELLOW}Multiple recovery images found:${RESET}"
        for i in "${!RECOVERY_FILES[@]}"; do
            echo "$((i+1))) ${RECOVERY_FILES[i]}"
        done
        read -p "Select recovery to flash [1-${#RECOVERY_FILES[@]}]: " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#RECOVERY_FILES[@]} )); then
            RECOVERY_PATH="${RECOVERY_FILES[selection-1]}"
        else
            echo -e "${RED}❌ Invalid selection.${RESET}"
            return
        fi
    fi

    echo -e "${BLUE}🔎 Detecting partition type...${RESET}"
    partition_info=$(fastboot getvar all 2>&1)

    if echo "$partition_info" | grep -q "has-slot:recovery:yes"; then
        echo -e "${GREEN}✅ Detected recovery_$slot partition.${RESET}"
        echo -e "${GREEN}➡️ Flashing recovery to recovery_$slot...${RESET}"
        slot=$(fastboot getvar current-slot 2>&1 | grep -oE 'a|b')
        fastboot flash recovery_$slot "$RECOVERY_PATH" || { echo -e "${RED}❌ Flash failed.${RESET}"; return; }

    elif echo "$partition_info" | grep -q "has-slot:boot:yes"; then
        echo -e "${GREEN}✅ Detected A/B partition device.${RESET}"
        echo -e "${GREEN}➡️ Flashing recovery to boot partition...${RESET}"
        fastboot flash boot "$RECOVERY_PATH" || { echo -e "${RED}❌ Flash failed.${RESET}"; return; }

    elif echo "$partition_info" | grep -q "has-slot:recovery:no"; then
        echo -e "${GREEN}✅ Detected A-only partition device.${RESET}"
        echo -e "${GREEN}➡️ Flashing recovery to recovery partition...${RESET}"
        fastboot flash recovery "$RECOVERY_PATH" || { echo -e "${RED}❌ Flash failed.${RESET}"; return; }

    else
        echo -e "${RED}❌ Unable to detect proper partition layout.${RESET}"
        return
    fi

    echo -e "${BLUE}✅ Flashing completed!${RESET}"
    
    echo -e "${GREEN}if you're using mediatek device then flash vbmeta after recovery flash (vbmeta from current rom). It's for device specific but mandatory that's not giving harm on your device...${RESET}"
}

FLASH_ROM() {
    echo -e "${BLUE}🔍 Scanning for ROM and etc. Files...${RESET}"
    mapfile -t ROM_FILES < <(find /sdcard/flasher -iname "*.apk" -o -iname "*.zip")

    if [ ${#ROM_FILES[@]} -eq 0 ]; then
        echo -e "${RED}❌ No files found in /sdcard/flasher/${RESET}"
        return
    elif [ ${#ROM_FILES[@]} -eq 1 ]; then
        ROM_PATH="${ROM_FILES[0]}"
        echo -e "${GREEN}✅ Found: $ROM_PATH${RESET}"
    else
        echo -e "${YELLOW}Multiple flashable files found:${RESET}"
        for i in "${!ROM_FILES[@]}"; do
            echo "$((i+1))) ${ROM_FILES[i]}"
        done
        read -p "Select files to flash [1-${#ROM_FILES[@]}]: " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#ROM_FILES[@]} )); then
            ROM_PATH="${ROM_FILES[selection-1]}"
        else
            echo -e "${RED}❌ Invalid selection.${RESET}"
            return
        fi
    fi

    echo -e "${BLUE}🔎 Checking ADB sideload...${RESET}"
    device_status=$(adb devices | grep -w "sideload")

    if [ -n "$device_status" ]; then
        echo -e "${GREEN}[✔] Device detected in ADB sideload mode:${RESET}"
        echo "$device_status"
        adb sideload "$ROM_PATH" || { echo -e "${RED}❌ Flash failed.${RESET}"; return; }
        echo -e "${BLUE}✅ Flashing completed!${RESET}"
    else
        echo -e "${RED}❌ No sideload device detected.${RESET}"
        return
    fi
}

FASTBOOT_ROM() {
    echo -e "${BLUE}🔍 Searching fastboot ROMs...${RESET}"
    mapfile -t FASTBOOT_FILES < <(find /sdcard/flasher -iname "*fastboot*.zip" -o -iname "*global*.tgz" -o -iname "*global*.tar.gz" -o -iname "*fastboot*.tgz" -o -iname "*fastboot*.tar.gz")

    if [ ${#FASTBOOT_FILES[@]} -eq 0 ]; then
        echo -e "${RED}❌ No Fastboot ROM found${RESET}"
        return
    elif [ ${#FASTBOOT_FILES[@]} -eq 1 ]; then
        FASTBOOT_PATH="${FASTBOOT_FILES[0]}"
        echo -e "${GREEN}✅ Found: $FASTBOOT_PATH${RESET}"
    else
        echo -e "${YELLOW}Multiple Fastboot ROMs found:${RESET}"
        for i in "${!FASTBOOT_FILES[@]}"; do
            echo "$((i+1))) ${FASTBOOT_FILES[i]}"
        done
        read -p "Select ROM to flash [1-${#FASTBOOT_FILES[@]}]: " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#FASTBOOT_FILES[@]} )); then
            FASTBOOT_PATH="${FASTBOOT_FILES[selection-1]}"
        else
            echo -e "${RED}❌ Invalid selection.${RESET}"
            return
        fi
    fi

    echo -e "${BLUE}Need Free Space In Your Device For Rom Extraction..${RESET}"
    # Get base name (filename) and output folder
    BASENAME=$(basename "$FASTBOOT_PATH")
    OUTPUT_DIR="/sdcard/flasher/ROM"

    # Create output folder
    mkdir -p "$OUTPUT_DIR"

         # Detect and extract
    case "$BASENAME" in
       *.zip)
           echo -e "${YELLOW}📦 Detected ZIP file. Extracting...${RESET}"
           unzip -o "$FASTBOOT_PATH" -d "$OUTPUT_DIR" || { echo -e "${RED}❌ Unzip failed.${RESET}"; return; }
           ;;
       *.tgz|*.tar.gz)
           echo -e "${YELLOW}📦 Detected TGZ file. Extracting...${RESET}"
           tar -xzf "$FASTBOOT_PATH" -C "$OUTPUT_DIR" || { echo -e "${RED}❌ Unzip failed.${RESET}"; return; }
           ;;
       *)
           echo -e "${RED}❌ Unsupported file type: $BASENAME${RESET}"
           return
           ;;
    esac

    echo -e "${GREEN}✅ Extraction completed → $OUTPUT_DIR${RESET}"
    echo -e "${YELLOW}🧭 Transfering Rom folder into termux directory.. It will take time wait until it moved..${RESET}"
    mv /sdcard/flasher/ROM $HOME
    echo -e "${GREEN}✅ Moving completed.${RESET}"
    cd $HOME/ROM
    echo -e "${BLUE}🔍 Searching Flash Scripts...${RESET}"
    mapfile -t FLASH_SCRIPT < <(find -iname "flash_all.sh" -o -iname "flash_all_lock.sh" -o -iname "flash_all_except_data_storage.sh")

    if [ ${#FLASH_SCRIPT[@]} -eq 0 ]; then
        echo -e "${RED}❌ No Flash Script found${RESET}"
        return
    elif [ ${#FLASH_SCRIPT[@]} -eq 1 ]; then
        FLASH_SH="${FLASH_SCRIPT[0]}"
        echo -e "${GREEN}✅ Found: $FLASH_SH${RESET}"
    else
        echo -e "${YELLOW}Multiple Flash Scripts found:${RESET}"
        for i in "${!FLASH_SCRIPT[@]}"; do
            echo "$((i+1))) ${FLASH_SCRIPT[i]}"
        done
        read -p "Select Flash Script to flash [1-${#FLASH_SCRIPT[@]}]: " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#FLASH_SCRIPT[@]} )); then
            FLASH_SH="${FLASH_SCRIPT[selection-1]}"
        else
            echo -e "${RED}❌ Invalid selection.${RESET}"
            return
        fi
    fi

    chmod +x "$FLASH_SH"
    ./"$FLASH_SH"
    echo -e "${BLUE}✅ Fastboot ROM flashing done.${RESET}"
    sleep 3
    echo -e "${YELLOW}Removing Extracted 📂 Folder.....${RESET}"
    echo -e "${BLUE}WAIT FOR MIN....${RESET}"
    rm -rf $HOME/ROM
}

VB_META() {
    echo -e "${BLUE}🔍 Searching vbmeta images...${RESET}"
    mapfile -t META_FILES < <(find /sdcard/flasher -iname "*vbmeta*.img")

    if [ ${#META_FILES[@]} -eq 0 ]; then
        echo -e "${RED}❌ No vbmeta img found${RESET}"
        return
    elif [ ${#META_FILES[@]} -eq 1 ]; then
        META_PATH="${META_FILES[0]}"
        echo -e "${GREEN}✅ Found: $META_FILES${RESET}"
    else
        echo -e "${YELLOW}Multiple vbmeta imgs found:${RESET}"
        for i in "${!META_FILES[@]}"; do
            echo "$((i+1))) ${META_FILES[i]}"
        done
        read -p "Select vbmeta to flash [1-${#META_FILES[@]}]: " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#META_FILES[@]} )); then
            META_PATH="${META_FILES[selection-1]}"
        else
            echo -e "${RED}❌ Invalid selection.${RESET}"
            return
        fi
    fi

    echo -e "${GREEN}⚡flashing vbmeta in active slot.......${RESET}"
    fastboot --disable-verity --disable-verification flash vbmeta "$META_PATH" || { echo -e "${RED}❌ Flash failed.${RESET}"; return; }
    echo -e "${BLUE}✅ vbmeta flashed.${RESET}"
}

BOOT_FLASH() {
    echo -e "${BLUE}🔍 Searching for boot images...${RESET}"
    mapfile -t BOOT_FILES < <(find /sdcard/flasher -iname "*boot*.img" -o -iname "*magisk*.img")

    if [ ${#BOOT_FILES[@]} -eq 0 ]; then
        echo -e "${RED}❌ No boot img found${RESET}"
        return
    elif [ ${#BOOT_FILES[@]} -eq 1 ]; then
        BOOT_PATH="${BOOT_FILES[0]}"
        echo -e "${GREEN}✅ Found: $BOOT_FILES${RESET}"
    else
        echo -e "${YELLOW}Multiple Boot imgs found:${RESET}"
        for i in "${!BOOT_FILES[@]}"; do
            echo "$((i+1))) ${BOOT_FILES[i]}"
        done
        read -p "Select Boot to flash [1-${#BOOT_FILES[@]}]: " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#BOOT_FILES[@]} )); then
            BOOT_PATH="${BOOT_FILES[selection-1]}"
        else
            echo -e "${RED}❌ Invalid selection.${RESET}"
            return
        fi
    fi

    echo -e "${GREEN}⚡flashing Boot in active slot.......${RESET}"
    fastboot flash boot "$BOOT_PATH" || { echo -e "${RED}❌ Flash failed.${RESET}"; return; }
    echo -e "${BLUE}✅ Boot flashed.${RESET}"
}

FLASH_MENU() {

echo -e "${RED}
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⡤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀  
⠀⠀⠀⠀⠀⠀⢀⣤⡶⠁⣠⣴⣾⠟⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀  
⠀⠀⠀⠀⢀⣴⣿⣿⣴⣿⠿⠋⣁⣀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ 
⠀⠀⠀⣰⣿⣿⣿⣿⣿⣷⣾⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀
⠀⣠⣾⣿⡿⠟⠋⠉⠀⣀⣀⣀⣨⣭⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣤⣤⣤⣤⣴⠂  ${RESET}"${GREEN}Name${RESET}""${BLUE} - Flasher [ AUTO ]${RESET}"${RED}
⠈⠉⠁⠀⠀⣀⣴⣾⣿⣿⡿⠟⠛⠉⠉⠉⠉⠉⠛⠻⠿⠿⠿⠿⠿⠿⠟⠋⠁⠀
⠀⠀⠀⢀⣴⣿⣿⣿⡿⠁⠀⢀⣀⣤⣤⣤⣤⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀  ${RESET}"${GREEN}Device${RESET}""${BLUE} - $(getprop ro.product.model)${RESET}"${RED}
⠀⠀⠀⣾⣿⣿⣿⡿⠁⢀⣴⣿⠋⠉⠉⠉⠉⠛⣿⣿⣶⣤⣤⣤⣤⣶⠖⠀⠀⠀
⠀⠀⢸⣿⣿⣿⣿⡇⢀⣿⣿⣇⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⡿⠃⠀⠀⠀⠀  ${RESET}"${GREEN}Version${RESET}""${BLUE} - 1.2.0 ÆLPHA${RESET}"${RED}
⠀⠀⠸⣿⣿⣿⣿⡇⠈⢿⣿⣿⠇⠀⠀⠀⠀⠀⢠⣿⣿⣿⠟⠋⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢿⣿⣿⣿⣷⡀⠀⠉⠉⠀⠀⠀⠀⠀⢀⣾⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀  ${RESET}"${GREEN}Author name${RESET}""${BLUE} - @sukuna567${RESET}"${RED}
⠀⠀⠀⠀⠙⢿⣿⣿⣷⣄⡀⠀⠀⠀⠀⣀⣴⣿⣿⣿⣋⣠⡤⠄⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠈⠙⠛⠛⠿⠿⠿⠿⠿⠿⠟⠛⠛⠛⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀  ${RESET}"${YELLOW}WELCOME IN MY WORLD${RESET}"
"${RED}ORIGINAL${RESET}""
echo -e "${RED}
            ...............................
            [          ${RESET}"${GREEN} WELCOME ${RESET}"${RED}          ]
            ...............................
SOMETHING...............................${RESET}"

    echo -e "${YELLOW}\n=============== Android Flash Menu ===============${RESET}"
    echo -e "${GREEN}1) 🎲 Flash Recovery\n2) 🃏 ADB Sideload(Apk/zip)\n3) 🀄 Flash Fastboot ROM\n4) 🪅 Flash vbmeta\n5) 🪩 Flash Boot\n6) 🧸 Reboot to System\n7) ♦️ Reboot to Recovery\n8) 🧶 fastboot to fastbootd\n9) 🎭 Reboot to Bootloader\n10) 🎼 Check active slot\n11) 📲 Set slot A\n12) 📲 Set slot B\n13) ✂️ Exit${RESET}"
    read -p "Choose an option [1-13]: " choice
    case "$choice" in
        1) FLASH_RECOVERY ;;
        2) FLASH_ROM ;;
        3) FASTBOOT_ROM ;;
        4) VB_META ;;
        5) BOOT_FLASH ;;
        6) fastboot reboot ;;
        7) echo -e "${BLUE}BOOTING.. REC....${RESET}"; fastboot reboot recovery ;;
        8) echo -e "${BLUE}BOOTING.. FASTBOOTD..${RESET}"; fastboot reboot fastboot ;;
        9) echo -e "${BLUE}BOOTING.. FASTBOOT...${RESET}"; adb reboot bootloader || { echo -e "${RED}❌ Device not have in adb mode.${RESET}"; return; } ;;
        10) echo -e "${BLUE}Slot is.....${RESET}"; fastboot getvar current-slot ;;
        11) echo -e "${BLUE}Slot A Activated....${RESET}"; fastboot set_active a ;;
        12) echo -e"${BLUE}Slot B Activated.....${RESET}"; fastboot set_active b ;;
        13) echo -e "${BLUE}👋 Exiting script.${RESET}"; exit 0 ;;
        *) echo -e "${RED}❌ Invalid option.${RESET}" ;;
    esac
}

# === Main Loop ===
while true; do
    FLASH_MENU
done