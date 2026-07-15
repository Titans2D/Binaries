#!/bin/bash

STRATEGY_DIR="./strategy"
FORMATIONS_DIR="./formations"

# strategyのJSONファイルから .conf ファイル名を抽出（ファイル名のみ）
used_conf_files=$(grep -ohP '[^"/]+\.conf' "$STRATEGY_DIR"/*.json | sort -u)

# formationsディレクトリ以下の .conf ファイル名を取得（ファイル名のみ）
all_conf_files=$(find "$FORMATIONS_DIR" -name "*.conf" -printf "%f\n" | sort -u)

# 使用されていない .conf ファイルを検出
unused_conf_files=$(comm -23 <(echo "$all_conf_files") <(echo "$used_conf_files"))

if [ -n "$unused_conf_files" ]; then
    unused_count=$(echo "$unused_conf_files" | wc -l)
    echo "Unused .conf files (${unused_count}):"
    echo "$unused_conf_files"
else
    echo "All .conf files are used."
fi
