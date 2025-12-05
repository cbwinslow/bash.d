#!/bin/bash

echo "=== Testing bash initialization ==="

# Test 1: Check if bash can start at all
echo "Test 1: Basic bash functionality"
bash -c "echo 'Basic bash works'" 2>&1
echo "Test 1 result: $?"

# Test 2: Check if current bashrc can be sourced
echo "Test 2: Sourcing current bashrc"
bash -c "source ~/.bashrc 2>&1" | head -10
echo "Test 2 result: $?"

# Test 3: Check for syntax errors in bashrc
echo "Test 3: Checking bashrc syntax"
bash -n ~/.bashrc 2>&1
echo "Test 3 result: $?"

# Test 4: Check if bash_functions.d exists and is accessible
echo "Test 4: Checking bash_functions.d"
ls -la ~/.bash_functions.d 2>&1 | head -5

# Test 5: Check if there are any problematic functions
echo "Test 5: Testing individual components"
bash -c "source ~/.bashrc; echo 'PS1 is: '\"$PS1\" 2>&1" | head -3

echo "=== Tests completed ==="
