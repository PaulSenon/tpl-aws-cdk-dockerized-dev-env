#!/bin/bash
set -e

create_env_file() {
    echo "🔧 Creating .env file..."
    cp .env.example .env
}

select_node_version() {
    echo "📦 Select node major version"
    
    # Initialize NODE_VERSION with default
    NODE_VERSION="lts"
    
    # Prompt for input
    echo "Enter node version (lts):"
    read choice
    
    # Only override default if user entered something
    if [ ! -z "$choice" ]; then
        NODE_VERSION="$choice"
    fi

    echo "Selected Node version: $NODE_VERSION"
    
    # append to .env file
    echo "NODE_VERSION=$NODE_VERSION" >> .env
}


# Function to prompt for package manager selection
select_package_manager() {
    echo "📦 Select your preferred package manager:"
    echo -e "\t- pnpm"
    echo -e "\t- yarn"
    echo -e "\t- npm"
    
    while true; do
        read -p "Enter choice (pnpm): " choice
        case $choice in
            ""|pnpm)
                PACKAGE_MANAGER="pnpm"
                break
                ;;
            yarn)
                PACKAGE_MANAGER="yarn"
                break
                ;;
            npm)
                PACKAGE_MANAGER="npm"
                break
                ;;
            *)
                echo "❌ Invalid choice. Please select pnpm, yarn, or npm"
                ;;
        esac
    done

    echo "saving package manager .env file"
    echo "PACKAGE_MANAGER=$PACKAGE_MANAGER" >> .env
}

bootstrap_from_container() {
    echo "🏗️ Bootstrapping from container..."
    NODE_VERSION=${NODE_VERSION} docker compose --file .bootstrap/docker-compose.bootstrap.yml run --rm --service-ports bootstrap /app/bootstrap.docker.sh
}

prompt_make_install() {
    echo "🔧 Bootstrap complete!"
    echo "you can now run 'make install' to install the project and start developing"    
}

clean_up() {
    echo "🧹 Cleaning up..."
    NODE_VERSION=${NODE_VERSION} docker compose --file .bootstrap/docker-compose.bootstrap.yml down --rmi all --volumes --remove-orphans
    rm -rf ./.bootstrap
    rm -f ./README.md
    mv ./README.final.md ./README.md
    rm -rf .git
    echo ".pnpm-store" >> .gitignore
    echo ".env.*.local" >> .gitignore
    echo ".env.local" >> .gitignore
}

bootstrap() {
    create_env_file
    select_node_version
    select_package_manager
    bootstrap_from_container
    clean_up
    prompt_make_install
}

bootstrap