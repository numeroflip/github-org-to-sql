#!/bin/bash

if [ -f .env ]; then
    source ./.env
fi

# Use command line argument first, then fall back to environment variable
ORG_NAME_FROM_ENV="${GITHUB_ORG:-${ORG_NAME_ENV}}"
ORG_NAME="${1:-$ORG_NAME_FROM_ENV}"

# GitHub Organization Database Query Runner
# Interactive script to run predefined queries on the DuckDB database

set -e

# Configuration
DB_FILE="$ORG_NAME.db"
QUERIES_DIR="queries"

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if required files exist
check_requirements() {
    if [[ ! -f "$DB_FILE" ]]; then
        echo -e "${RED}Error: Database file '$DB_FILE' not found!${NC}"
        echo "Please run the data collection script first."
        exit 1
    fi
    
    if [[ ! -d "$QUERIES_DIR" ]]; then
        echo -e "${RED}Error: Queries directory '$QUERIES_DIR' not found!${NC}"
        exit 1
    fi
    
    if ! command -v duckdb &> /dev/null; then
        echo -e "${RED}Error: duckdb command not found!${NC}"
        echo "Please install DuckDB first."
        exit 1
    fi
}

# Get all query categories (subdirectories)
get_categories() {
    find "$QUERIES_DIR" -mindepth 1 -maxdepth 1 -type d | sort
}

# Get all SQL files in a category
get_queries_in_category() {
    local category="$1"
    find "$category" -name "*.sql" | sort
}

# Extract query title from SQL file
get_query_title() {
    local file="$1"
    # Get the first comment line after removing the -- prefix
    local title=$(head -1 "$file" | sed 's/^-- *//')
    if [[ -z "$title" ]]; then
        # Fallback to filename without extension
        title=$(basename "$file" .sql | sed 's/^[0-9]*-//' | tr '-' ' ')
    fi
    echo "$title"
}

# Format category name for display
format_category_name() {
    local category="$1"
    basename "$category" | sed 's/^[0-9]*-//' | tr '-' ' ' | sed 's/\b\w/\U&/g'
}

# Run a query file and display results
run_query() {
    local query_file="$1"
    local title="$2"
    
    echo
    echo -e "${CYAN}=== $title ===${NC}"
    echo
    
    # Read and execute the query
    local query=$(cat "$query_file")
    duckdb "$DB_FILE" -c ".mode table" -c ".headers on" -c "$query"
    
    echo
    echo -e "${GREEN}Query completed successfully!${NC}"
    echo
}

# Display main menu
show_main_menu() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                GitHub Organization Database Queries              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}Please select a query category:${NC}"
    echo
    
    local categories=($(get_categories))
    local i=1
    
    for category in "${categories[@]}"; do
        local display_name=$(format_category_name "$category")
        echo -e "  ${GREEN}$i)${NC} $display_name"
        i=$((i + 1))
    done
    
    echo
    echo -e "  ${PURPLE}0)${NC} Exit"
    echo
}

# Display category menu
show_category_menu() {
    local category="$1"
    local display_name="$2"
    
    clear
    echo -e "${CYAN}=== $display_name Queries ===${NC}"
    echo
    
    local queries=($(get_queries_in_category "$category"))
    local i=1
    
    for query_file in "${queries[@]}"; do
        local title=$(get_query_title "$query_file")
        echo -e "  ${GREEN}$i)${NC} $title"
        i=$((i + 1))
    done
    
    echo
    echo -e "  ${PURPLE}0)${NC} Back to main menu"
    echo
}

# Run queries in a category
run_category_queries() {
    local category="$1"
    local display_name="$2"
    
    while true; do
        show_category_menu "$category" "$display_name"
        
        local queries=($(get_queries_in_category "$category"))
        local max_option=${#queries[@]}
        
        read -p "Select a query (0-$max_option): " choice
        
        if [[ "$choice" == "0" ]]; then
            return
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "$max_option" ]]; then
            local query_file="${queries[$((choice - 1))]}"
            local title=$(get_query_title "$query_file")
            run_query "$query_file" "$title"
            read -p "Press Enter to continue..."
        else
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 1
        fi
    done
}

# Main program loop
main() {
    check_requirements
    
    while true; do
        show_main_menu
        
        local categories=($(get_categories))
        local max_option=${#categories[@]}
        
        read -p "Select an option (0-$max_option): " choice
        
        if [[ "$choice" == "0" ]]; then
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "$max_option" ]]; then
            local category="${categories[$((choice - 1))]}"
            local display_name=$(format_category_name "$category")
            run_category_queries "$category" "$display_name"
        else
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 1
        fi
    done
}

# Run the main program
main "$@" 