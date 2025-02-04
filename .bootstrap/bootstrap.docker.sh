#!/bin/bash
set -e

# Function to initialize the project
initialize_cdk_project() {
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
    # Add clean script to package.json using system temp file
    TEMP_FILE=$(mktemp)
    jq '.scripts.clean = "rm -rf dist cdk.out && rm -rf node_modules && rm -rf .pnpm-store/*"' package.json > "$TEMP_FILE" && mv "$TEMP_FILE" package.json
}

# Main script
echo "📝 Bootstrapping cdk project..."
cd /app/bootstrap
initialize_cdk_project
echo "✨ CDK Project initialization complete!"
