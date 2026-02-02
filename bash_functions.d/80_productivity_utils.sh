#!/bin/bash
# ============================================================================
# Productivity Utilities
# ============================================================================
# Helpful tools to boost productivity and efficiency

# Quick note taking
note() {
    local notes_dir="$HOME/.notes"
    mkdir -p "$notes_dir"
    
    local note_file="$notes_dir/notes_$(date +%Y%m%d).md"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    if [ -z "$1" ]; then
        # Open notes file in editor
        $EDITOR "$note_file"
    else
        # Append note with timestamp
        echo "## $timestamp" >> "$note_file"
        echo "$*" >> "$note_file"
        echo "" >> "$note_file"
        echo -e "${COLOR_GREEN}Note added to $note_file${COLOR_RESET}"
    fi
}

# Show recent notes
shownotes() {
    local notes_dir="$HOME/.notes"
    local days="${1:-7}"
    
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Recent Notes (last $days days):${COLOR_RESET}"
    echo ""
    
    find "$notes_dir" -name "notes_*.md" -mtime -"$days" -exec cat {} \; 2>/dev/null || echo "No notes found"
}

# Search notes
searchnotes() {
    if [ -z "$1" ]; then
        echo "Usage: searchnotes <keyword>"
        return 1
    fi
    
    local notes_dir="$HOME/.notes"
    
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Searching notes for: $1${COLOR_RESET}"
    echo ""
    
    grep -r --color=always -i "$1" "$notes_dir" 2>/dev/null || echo "No matches found"
}

# Quick calculator
calc() {
    if [ -z "$1" ]; then
        echo "Usage: calc <expression>"
        echo "Example: calc '2 + 2'"
        return 1
    fi
    
    python3 -c "print($*)"
}

# Convert currency (requires internet)
convert_currency() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: convert_currency <amount> <from_currency> <to_currency>"
        echo "Example: convert_currency 100 USD EUR"
        return 1
    fi
    
    local amount="$1"
    local from="$2"
    local to="$3"
    
    curl -s "https://api.exchangerate-api.com/v4/latest/${from}" | \
        python3 -c "import sys, json; data=json.load(sys.stdin); print(f'${amount} ${from} = {${amount} * data[\"rates\"][\"${to}\"]} ${to}')"
}

# Weather report (requires internet)
weather() {
    local location="${1:-}"
    
    if [ -z "$location" ]; then
        curl -s "wttr.in?format=3"
    else
        curl -s "wttr.in/${location}?format=3"
    fi
}

# Detailed weather
weather_full() {
    local location="${1:-}"
    curl -s "wttr.in/${location}"
}

# Timer - countdown timer
timer() {
    if [ -z "$1" ]; then
        echo "Usage: timer <seconds>"
        return 1
    fi
    
    local seconds="$1"
    local start=$(date +%s)
    local end=$((start + seconds))
    
    while [ $(date +%s) -lt $end ]; do
        local remaining=$((end - $(date +%s)))
        printf "\rTime remaining: %02d:%02d:%02d" $((remaining/3600)) $(((remaining%3600)/60)) $((remaining%60))
        sleep 1
    done
    
    echo -e "\n${COLOR_GREEN}${COLOR_BOLD}Timer finished!${COLOR_RESET}"
    
    # Try to make a sound
    printf '\a'
}

# Stopwatch
stopwatch() {
    echo -e "${COLOR_CYAN}Stopwatch started. Press Ctrl+C to stop.${COLOR_RESET}"
    echo ""
    
    local start=$(date +%s)
    
    while true; do
        local elapsed=$(($(date +%s) - start))
        printf "\rElapsed: %02d:%02d:%02d" $((elapsed/3600)) $(((elapsed%3600)/60)) $((elapsed%60))
        sleep 1
    done
}

# Pomodoro timer
pomodoro() {
    local work_time="${1:-25}"  # 25 minutes default
    local break_time="${2:-5}"   # 5 minutes default
    
    echo -e "${COLOR_GREEN}${COLOR_BOLD}Pomodoro Timer${COLOR_RESET}"
    echo -e "${COLOR_CYAN}Work time: ${work_time} minutes${COLOR_RESET}"
    echo -e "${COLOR_CYAN}Break time: ${break_time} minutes${COLOR_RESET}"
    echo ""
    
    # Work session
    echo -e "${COLOR_GREEN}Work session started!${COLOR_RESET}"
    timer $((work_time * 60))
    
    # Break session
    echo -e "${COLOR_YELLOW}Break time!${COLOR_RESET}"
    timer $((break_time * 60))
    
    echo -e "${COLOR_GREEN}Pomodoro complete!${COLOR_RESET}"
}

# QR code generator (requires qrencode)
qrcode() {
    if [ -z "$1" ]; then
        echo "Usage: qrcode <text>"
        return 1
    fi
    
    if ! command -v qrencode &> /dev/null; then
        echo "Error: qrencode not installed. Install with: sudo apt-get install qrencode"
        return 1
    fi
    
    qrencode -t ANSI "$1"
}

# Generate random string
randstr() {
    local length="${1:-16}"
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w "$length" | head -n 1
}

# Generate random number
randnum() {
    local min="${1:-1}"
    local max="${2:-100}"
    
    echo $((RANDOM % (max - min + 1) + min))
}

# Flip a coin
coinflip() {
    if [ $((RANDOM % 2)) -eq 0 ]; then
        echo "Heads"
    else
        echo "Tails"
    fi
}

# Roll a die
diceroll() {
    local sides="${1:-6}"
    echo $((RANDOM % sides + 1))
}

# Color picker - show all available colors
colors() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Terminal Color Reference:${COLOR_RESET}"
    echo ""
    
    echo -e "Regular Colors:"
    echo -e "  \033[0;30m Black   \033[0m  \033[0;90m Bright Black   \033[0m"
    echo -e "  \033[0;31m Red     \033[0m  \033[0;91m Bright Red     \033[0m"
    echo -e "  \033[0;32m Green   \033[0m  \033[0;92m Bright Green   \033[0m"
    echo -e "  \033[0;33m Yellow  \033[0m  \033[0;93m Bright Yellow  \033[0m"
    echo -e "  \033[0;34m Blue    \033[0m  \033[0;94m Bright Blue    \033[0m"
    echo -e "  \033[0;35m Magenta \033[0m  \033[0;95m Bright Magenta \033[0m"
    echo -e "  \033[0;36m Cyan    \033[0m  \033[0;96m Bright Cyan    \033[0m"
    echo -e "  \033[0;37m White   \033[0m  \033[0;97m Bright White   \033[0m"
}

# Translate text (requires internet)
translate() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: translate <from_lang> <to_lang> <text>"
        echo "Example: translate en es 'Hello world'"
        return 1
    fi
    
    local from="$1"
    local to="$2"
    shift 2
    local text="$*"
    
    curl -s "https://translate.googleapis.com/translate_a/single?client=gtx&sl=${from}&tl=${to}&dt=t&q=${text}" | \
        python3 -c "import sys, json; print(json.load(sys.stdin)[0][0][0])"
}

# Show calendar
cal_month() {
    cal
}

# Show calendar for year
cal_year() {
    local year="${1:-$(date +%Y)}"
    cal "$year"
}

# Age calculator
age() {
    if [ -z "$1" ]; then
        echo "Usage: age <YYYY-MM-DD>"
        return 1
    fi
    
    local birthdate="$1"
    local today=$(date +%Y%m%d)
    local birth=$(date -d "$birthdate" +%Y%m%d)
    local age=$(( (today - birth) / 10000 ))
    
    echo "Age: $age years old"
}

# Days until date
daysuntil() {
    if [ -z "$1" ]; then
        echo "Usage: daysuntil <YYYY-MM-DD>"
        return 1
    fi
    
    local target="$1"
    local today=$(date +%s)
    local target_date=$(date -d "$target" +%s)
    local diff_days=$(( (target_date - today) / 86400 ))
    
    if [ $diff_days -gt 0 ]; then
        echo "$diff_days days until $target"
    elif [ $diff_days -eq 0 ]; then
        echo "Today is $target!"
    else
        echo "$((-diff_days)) days since $target"
    fi
}

# Display ASCII art text
banner() {
    if [ -z "$1" ]; then
        echo "Usage: banner <text>"
        return 1
    fi
    
    if command -v figlet &> /dev/null; then
        figlet "$*"
    else
        echo "==========================================="
        echo "  $*"
        echo "==========================================="
    fi
}

# Show motivational quote
motivate() {
    local quotes=(
        "The only way to do great work is to love what you do. - Steve Jobs"
        "Success is not final, failure is not fatal: it is the courage to continue that counts. - Winston Churchill"
        "Believe you can and you're halfway there. - Theodore Roosevelt"
        "Code is like humor. When you have to explain it, it's bad. - Cory House"
        "First, solve the problem. Then, write the code. - John Johnson"
        "Experience is the name everyone gives to their mistakes. - Oscar Wilde"
        "In order to be irreplaceable, one must always be different. - Coco Chanel"
        "The best time to plant a tree was 20 years ago. The second best time is now. - Chinese Proverb"
    )
    
    local random_index=$((RANDOM % ${#quotes[@]}))
    echo -e "${COLOR_CYAN}${quotes[$random_index]}${COLOR_RESET}"
}

# Create TODO list
todo() {
    local todo_file="$HOME/.todo.txt"
    
    if [ -z "$1" ]; then
        # Show current TODO list
        if [ -f "$todo_file" ]; then
            echo -e "${COLOR_BOLD}${COLOR_CYAN}TODO List:${COLOR_RESET}"
            cat -n "$todo_file"
        else
            echo "No TODO items yet. Add one with: todo add <item>"
        fi
    elif [ "$1" = "add" ]; then
        shift
        echo "$*" >> "$todo_file"
        echo -e "${COLOR_GREEN}Added to TODO list${COLOR_RESET}"
    elif [ "$1" = "done" ]; then
        if [ -z "$2" ]; then
            echo "Usage: todo done <line_number>"
            return 1
        fi
        sed -i "${2}d" "$todo_file"
        echo -e "${COLOR_GREEN}Removed item $2 from TODO list${COLOR_RESET}"
    elif [ "$1" = "clear" ]; then
        rm -f "$todo_file"
        echo -e "${COLOR_GREEN}Cleared TODO list${COLOR_RESET}"
    fi
}

# Bookmark directory
bookmark() {
    local bookmarks_file="$HOME/.bookmarks"
    
    if [ -z "$1" ]; then
        # Show bookmarks
        if [ -f "$bookmarks_file" ]; then
            echo -e "${COLOR_BOLD}${COLOR_CYAN}Bookmarks:${COLOR_RESET}"
            cat "$bookmarks_file"
        else
            echo "No bookmarks yet. Add one with: bookmark add <name>"
        fi
    elif [ "$1" = "add" ]; then
        if [ -z "$2" ]; then
            echo "Usage: bookmark add <name>"
            return 1
        fi
        echo "$2=$(pwd)" >> "$bookmarks_file"
        echo -e "${COLOR_GREEN}Bookmarked current directory as '$2'${COLOR_RESET}"
    elif [ "$1" = "go" ]; then
        if [ -z "$2" ]; then
            echo "Usage: bookmark go <name>"
            return 1
        fi
        local path=$(grep "^$2=" "$bookmarks_file" 2>/dev/null | cut -d'=' -f2)
        if [ -n "$path" ]; then
            cd "$path" || echo "Error: Directory not found"
        else
            echo "Bookmark '$2' not found"
        fi
    fi
}
