#!/bin/bash
set -e

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
    echo "PACKAGE_MANAGER=$PACKAGE_MANAGER" > .env
}

# Function to initialize the project
initialize_project() {

    echo "🏗️ Initializing CDK project..."
    PROJECT_DIR=$(pwd)
    TEMP_DIR_CDK=$(mktemp -d)
    cd $TEMP_DIR_CDK
    mkdir -p myApp
    cd myApp
    cdk init app --language typescript --generate-only
    cp -r . $PROJECT_DIR
    cd $PROJECT_DIR
    rm -rf $TEMP_DIR_CDK


    echo "🚀 Preparing package manager: $PACKAGE_MANAGER@latest"
    corepack use "${PACKAGE_MANAGER}@latest"
    corepack up

    echo "🔧 Adding scripts to package.json..."
    jq '.scripts += {
        "clean": "rm -rf dist cdk.out && rm -rf node_modules && rm -rf .pnpm-store/*"
    }' package.json > "$(mktemp)" && mv "$(mktemp)" package.json
    
    echo "🔧 Installing CDK dependencies..."
    $PACKAGE_MANAGER install
}

# Main script
# if ! jq -e '.packageManager' package.json > /dev/null 2>&1; then
if [ -f ".bootstrap" ]; then
    echo "📝 Bootstrapping project..."
    select_package_manager
    initialize_project
    echo "✨ Project initialization complete!"
    rm -f .bootstrap
else
    echo "✨ Project already bootstrapped!"
fi