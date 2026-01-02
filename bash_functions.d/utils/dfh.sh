#!/bin/bash
dfh() {
    df -h | grep -E '^(Filesystem|/dev/)' | column -t
}
