#!/bin/bash

# Скрипт: clear-content-skeleton.sh
# Очищает .tex-файлы от текстового содержимого, оставляя только структуру (section/chapter и т.д.)
# НЕ удаляет служебные файлы и не трогает библиографию, макросы, настройки.

set -euo pipefail

# Каталоги для обработки
DIRS=("Dissertation" "Synopsis" "Presentation")

# Файлы, которые НЕЛЬЗЯ очищать (служебные)
PROTECTED_FILES=(
  "setup.tex"
  "dispackages.tex"
  "userpackages.tex"
  "disstyles.tex"
  "userstyles.tex"
  "renames.tex"
  "lists.tex"
  "contents.tex"
  "title.tex"
  "preamble.tex"
  "prespackages.tex"
  "styles.tex"
  "synpackages.tex"
  "synstyles.tex"
)

# Создаём резервную копию, если ещё не создана
BACKUP_DIR=".skeleton_backup_$(date +%Y%m%d_%H%M%S)"
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "📦 Создаём резервную копию в $BACKUP_DIR..."
  mkdir -p "$BACKUP_DIR"
  for dir in "${DIRS[@]}"; do
    [[ -d "$dir" ]] && cp -r "$dir" "$BACKUP_DIR/"
  done
  echo "✅ Резервная копия создана."
fi

# Функция: проверить, содержит ли файл структуру разделов
has_structure() {
  grep -qE '\\(chapter|section|subsection|subsubsection|paragraph|subparagraph)\{' "$1"
}

# Функция: очистить файл, оставив только структуру
clean_tex_file() {
  local file="$1"
  echo "🧹 Обрабатываю: $file"

  # Сохраняем строки:
  # - содержащие \chapter, \section и т.д.
  # - пустые строки (для читаемости)
  # - команды вроде \tableofcontents, \begin{appendices}, \end{document} и т.д.
  # - комментарии, начинающиеся с % (если они на отдельной строке)
  #
  # Удаляем всё остальное: абзацы, формулы, цитаты, текст.

  awk '
  {
    line = $0
    # Удаляем пробелы в начале и конце для проверки
    gsub(/^[ \t]+|[ \t]+$/, "", line)
  }
  # Пропускаем пустые строки
  line == "" { print $0; next }

  # Пропускаем комментарии (на отдельной строке)
  /^%/ { print $0; next }

  # Пропускаем команды структуры
  /\\(chapter|section|subsection|subsubsection|paragraph|subparagraph)\{/ { print $0; next }

  # Пропускаем важные команды документа
  /\\(tableofcontents|listoffigures|listoftables|printbibliography|bibliography)/ { print $0; next }

  # Пропускаем окружения структуры
  /\\begin\{[a-zA-Z]*appendix/ { print $0; next }
  /\\end\{[a-zA-Z]*appendix/ { print $0; next }
  /\\begin\{document\}/ { print $0; next }
  /\\end\{document\}/ { print $0; next }

  # Всё остальное — удаляем (не печатаем)
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

# Основной цикл
for dir in "${DIRS[@]}"; do
  [[ ! -d "$dir" ]] && continue
  echo "📁 Обрабатываю каталог: $dir"
  while IFS= read -r -d '' file; do
    # Пропускаем защищённые файлы
    basename_file=$(basename "$file")
    skip=false
    for pf in "${PROTECTED_FILES[@]}"; do
      if [[ "$basename_file" == "$pf" ]]; then
        skip=true
        break
      fi
    done
    if [[ "$skip" == true ]]; then
      echo "🔒 Пропускаю (защищён): $file"
      continue
    fi

    # Обрабатываем только если есть структура
    if has_structure "$file"; then
      clean_tex_file "$file"
    else
      echo "ℹ️  Пропускаю (нет структуры): $file"
    fi
  done < <(find "$dir" -name "*.tex" -print0)
done

echo "✅ Готово! Содержимое очищено, оглавление сохранено."
echo "Резервная копия: $BACKUP_DIR"
