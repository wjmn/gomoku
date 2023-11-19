# Remove previous builds
rm -rf build
rm -f build.zip

# Create a new build directory
mkdir build

# Copy all public assets to build
cp public/* build/

# Renam index.html to iframe.html
mv build/index.html build/iframe.html

# Copy all css from src directory to build
cp src/*.css build/

# Compile application to build/main.js
elm-app make src/Main.elm --optimize --output build/main.js