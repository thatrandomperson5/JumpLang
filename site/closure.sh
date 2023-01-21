if command -v java &> /dev/null
then
  if [ ! -f "./compiler.jar" ]; then
    echo "Installing deps"
    curl -o compiler.jar "https://repo1.maven.org/maven2/com/google/javascript/closure-compiler/v20230103/closure-compiler-v20230103.jar"
  fi
  echo "Running closure:"
  java -jar ./compiler.jar --js ./app.js --js_output_file ./release.js
  rm ./app.js
else
  mv ./app.js ./release.js
fi