#!/usr/bin/sh
find . -type f -name "*.tex" -exec latexindent -m -l indent.yaml -w {} \;
