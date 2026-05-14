#!/bin/bash

# keeps your local Ollama models in sync with the desired list in the 'models' array.

# sleepy time
sleep 15

# read models from env var
IFS=',' read -ra models <<< "$OLLAMA_MODELS"

echo "Models to be installed/updated:"
printf '  %s\n' "${models[@]}"

# get currently installed models
mapfile -t current_models < <(ollama ls | awk 'NR>1 {print $1}')

# remove models that are currently installed but are not in the models list
declare -A lookup
models_to_remove=()

for model in "${models[@]}"; do
  lookup["$model"]=1
done

for model in "${current_models[@]}"; do
  if [[ -z "${lookup[$model]}" ]]; then
    models_to_remove+=("$model")
  fi
done

if [ ${#models_to_remove[@]} -gt 0 ]; then
  for model in "${models_to_remove[@]}"; do
    printf 'Removing model: "%s"\n' "$model"
    ollama rm "$model" > /dev/null 2>&1
  done
fi

# install models in models
if [ ${#model[@]} -gt 0 ]; then
  for model in "${models[@]}"; do
      printf 'Installing model: "%s"\n' "$model"
      ollama pull "$model" > /dev/null 2>&1
  done
fi


