#!/data/data/com.termux/files/usr/bin/bash

# Colors
RED="\e[31m"
RED='\033[1;31m'
PINK='\033[38;5;201m'
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\033[0;34m"
PURPLE="\e[35m"
CYAN="\e[36m"
RESET="\e[0m"
BOLD="\e[1m"


# Show progress bar
show_progress() {
    local duration=$1
    local message="${2:-Processing...}"
    local sleep_time=0.1
    local steps=$((duration * 10))
    
    echo -ne "${BLUE}${message} ${RESET}"
    for ((i=0; i<steps; i++)); do
        printf "${PURPLE}▓${RESET}"
        sleep $sleep_time
    done
    printf "${GREEN} ✅\n${RESET}"
}

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

# Custom command
CUSTOM_COMMAND() {
    echo -e "${YELLOW}Enter custom fastboot command:${RESET}"
    echo -e "${CYAN}Examples:${RESET}"
    echo -e "  getvar all"
    echo -e "  reboot"
    echo -e "  oem device-info"
    
    read -p "Command: " custom_cmd
    if [ -n "$custom_cmd" ]; then
        echo -e "${BLUE}Executing: fastboot $custom_cmd${RESET}"
        fastboot $custom_cmd
    fi
}

# Unlock bootloader (WARNING: wipes data)
UNLOCK_BOOTLOADER() {
    echo -e "${RED}════════════════════════════════════════════════${RESET}"
    echo -e "${RED}   ⚠️  DANGER: UNLOCK BOOTLOADER ⚠️   ${RESET}"
    echo -e "${RED}════════════════════════════════════════════════${RESET}"
    echo -e "${YELLOW}This will:${RESET}"
    echo -e "${YELLOW}• Wipe ALL data (factory reset)${RESET}"
    echo -e "${YELLOW}• Void warranty on some devices${RESET}"
    echo -e "${YELLOW}• Potentially brick if interrupted${RESET}"
    echo -e "${RED}════════════════════════════════════════════════${RESET}"
    
    read -p "Type 'UNLOCK' to confirm: " confirm
    if [[ "$confirm" != "UNLOCK" ]]; then
        echo -e "${GREEN}❌ Unlock cancelled${RESET}"
        return
    fi
    
    echo -e "${YELLOW}Unlocking bootloader...${RESET}"
    fastboot flashing unlock || fastboot oem unlock
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Bootloader unlocked${RESET}"
        echo -e "${YELLOW}Device will reboot and wipe data${RESET}"
    else
        echo -e "${RED}❌ Unlock failed${RESET}"
    fi
}

# Show device info
SHOW_DEVICE_INFO() {
    echo -e "${YELLOW}\n📊 DEVICE INFORMATION${RESET}"
    echo -e "${CYAN}─────────────────────────${RESET}"
    
    # Fastboot info
    echo -e "${BLUE}Fastboot Variables:${RESET}"
    fastboot getvar all 2>/dev/null | head -20
    
    # Slot info
    current_slot=$(fastboot getvar current-slot 2>/dev/null | grep -o 'current-slot:.*' | cut -d: -f2 | xargs)
    echo -e "${GREEN}Current Slot: $current_slot${RESET}"
    
    # Device model from fastboot
    device_fb=$(fastboot getvar product 2>/dev/null | grep 'product:' | cut -d: -f2 | xargs)
    echo -e "${GREEN}Fastboot ID: $device_fb${RESET}"
    
    echo -e "${CYAN}─────────────────────────${RESET}"
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
    echo -e "${BOLD}㊗️ Clearing Previous directory if available......${RESET}"
    # Check if the $HOME/ROM directory exists
    if [ -d "$HOME/ROM" ]; then
       echo -e "${BLUE}Directory $HOME/ROM found. Removing it...${RESET}"
       rm -rf "$HOME/ROM"
       echo -e "${YELLOW}Directory removed...${RESET}"
    else
       echo -e "${BLUE}Directory $HOME/ROM not found. Continuing execution...${RESET}"
    fi
    
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
    sleep 6
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

CHECK_DEVICE_COMPATIBILITY() {
     echo -e "${PURPLE}NOT AVAILABLE COMMING SOON${RESET}"
     sleep 4
     
}

CLEAN_CACHE() {
     echo -e "${PURPLE}NOT AVAILABLE COMMING SOON${RESET}"
     sleep 4
     
}

BACKUP_PARTITIONS() {
     echo -e "${PURPLE}NOT AVAILABLE COMMING SOON${RESET}"
     sleep 4
     
}

# ============================================
# ADVANCED MENU
# ============================================

ADVANCED_MENU() {
    while true; do
        clear
        echo -e "${PURPLE}╔══════════════════════════════════════════╗${RESET}"
        echo -e "${PURPLE}║         🛠️  ADVANCED OPTIONS         ║${RESET}"
        echo -e "${PURPLE}╚══════════════════════════════════════════╝${RESET}"
        echo -e "${CYAN}1) 🔓 Unlock Bootloader [OnePlus] (Wipes Data!)${RESET}"
        echo -e "${CYAN}2) 📊 Device Information${RESET}"
        echo -e "${CYAN}3) 🧹 Clean Cache & Temp Files${RESET}"
        echo -e "${CYAN}4) 💾 Backup Partitions${RESET}"
        echo -e "${CYAN}5) ⚙️  Custom Fastboot Command${RESET}"
        echo -e "${CYAN}6) 🔧 Check Device Connection${RESET}"
        echo -e "${CYAN}7) ↩️  Back to Main Menu${RESET}"
        echo -e "${CYAN}──────────────────────────────────────${RESET}"
        
        read -p "Choose option [1-7]: " adv_choice
        
        case $adv_choice in
            1) UNLOCK_BOOTLOADER ;;
            2) SHOW_DEVICE_INFO ;;
            3) CLEAN_CACHE ;;
            4) BACKUP_PARTITIONS ;;
            5) CUSTOM_COMMAND ;;
            6) CHECK_DEVICE_COMPATIBILITY ;;
            7) return ;;
            *) echo -e "${RED}❌ Invalid option${RESET}" ;;
        esac
        
        echo -e "\n${YELLOW}Press Enter to continue...${RESET}"
        read
    done
}

FLASH_MENU() {

    # Pulsing animation
sukuna_minimal() {
    clear
    for i in {1..10}; do
        clear
        
        # Alternate colors
        if [ $((i % 2)) -eq 0 ]; then
            color=$RED
        else
            color=$PINK
        fi
        
        echo -e "${color}"
        echo ""
        echo "═══════════════════════════════════════════════════"
        echo "      両 面 宿 儺            Name - AutoFlasher"
        echo "═══════════════════════════════════════════════════"
        echo "呪術フラッシャー          Author name - @Sukuna567"
        echo "AUTOFLASHER TERMUX          WELCOME IN MY WORLD"
        echo "═══════════════════════════════════════════════════"
        echo -e "${RESET}"
        
        # Pulsing text
        echo -e "${color}"
        case $((i % 3)) in
            0) echo "                  伏魔御厨子 展開中...";;
            1) echo "                  呪力充填 完了";;
            2) echo "                  フラッシュ準備 OK";;
        esac
        echo -e "${RESET}"
        
        sleep 0.3
    done
    
}

sukuna_minimal

# CONTINUE WITH SCRIPT
echo -e "\033[38;5;46m"
echo "==============================================="
echo "|    ASTHMATIC AUTOFLASHER TERMUX v2.0.0       |"
echo "|       ULTRA EDITION - EXTREME MODE        |"
echo "|            DEVICE - $(getprop ro.product.model | head -c 30)                 |"
echo "==============================================="
echo -e "\033[0m"


    echo -e "${CYAN}══════════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}1) 🎲 Flash Recovery${RESET}"
    echo -e "${GREEN}2) 🃏 ADB Sideload (Apk/zip)${RESET}"
    echo -e "${GREEN}3) 🀄 Flash Fastboot ROM${RESET}"
    echo -e "${GREEN}4) 🪅 Flash vbmeta${RESET}"
    echo -e "${GREEN}5) 🪩 Flash Boot${RESET}"
    echo -e "${CYAN}──────────────────────────────────────────────────${RESET}"
    echo -e "${YELLOW}6) 🔘 Reboot to System${RESET}"
    echo -e "${YELLOW}7) ♦️  Reboot to Recovery${RESET}"
    echo -e "${YELLOW}8) 🧶 Fastboot to fastbootd${RESET}"
    echo -e "${YELLOW}9) 🔲 Reboot to Bootloader${RESET}"
    echo -e "${YELLOW}10) 🔶 Check/Switch Slots${RESET}"
    echo -e "${CYAN}──────────────────────────────────────────────────${RESET}"
    echo -e "${PURPLE}11) 🛠️  Advanced Options${RESET}"
    echo -e "${PURPLE}12) 💠 Exit${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════${RESET}"
    
    read -p "Choose an option [1-12]: " choice
    
    case "$choice" in
        1) FLASH_RECOVERY ;;
        2) FLASH_ROM ;;
        3) FASTBOOT_ROM ;;
        4) VB_META ;;
        5) BOOT_FLASH ;;
        6) echo -e "${BLUE}🔄 Rebooting to system...${RESET}"; fastboot reboot ;;
        7) echo -e "${BLUE}🔄 Rebooting to recovery...${RESET}"; fastboot reboot recovery ;;
        8) echo -e "${BLUE}🔄 Switching to fastbootd...${RESET}"; fastboot reboot fastboot ;;
        9) echo -e "${BLUE}🔄 Rebooting to bootloader...${RESET}"; adb reboot bootloader 2>/dev/null || fastboot reboot bootloader ;;
        10)
            echo -e "${CYAN}Current slot:${RESET}"
            fastboot getvar current-slot 2>/dev/null || echo "Cannot determine slot"
            echo -e "${CYAN}Set slot:${RESET}"
            echo "1) Slot A"
            echo "2) Slot B"
            echo "3) Check slot only"
            read -p "Choose: " slot_choice
            case $slot_choice in
                1) fastboot set_active a ;;
                2) fastboot set_active b ;;
                3) fastboot getvar current-slot ;;
                *) echo -e "${RED}Invalid choice${RESET}" ;;
            esac
            ;;
        11) ADVANCED_MENU ;;
        12) 
            echo -e "${BLUE}👋 Thank you for using Android Flasher!${RESET}"
            echo -e "${YELLOW}Nice to meet you 😇${RESET}"
            exit 0
            ;;
        *) echo -e "${RED}❌ Invalid option. Please choose 1-12.${RESET}" ;;
    esac
    
    echo -e "\n${YELLOW}Press Enter to continue...${RESET}"
    read
}

show_progress 2 "Starting..."

# === Main Loop ===
while true; do
    FLASH_MENU
done