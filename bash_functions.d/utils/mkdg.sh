#!/bin/bash
mkdg() {
    mkdir -p "$1" && cd "$1" && git init
}
