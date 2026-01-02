#!/usr/bin/env python3
import sys
import os
import requests

API_KEY = os.getenv('OPENROUTER_API_KEY')
if not API_KEY:
    print("Set OPENROUTER_API_KEY")
    sys.exit(1)

query = ' '.join(sys.argv[1:]) or "Hello"
response = requests.post('https://openrouter.ai/api/v1/chat/completions', json={
    'model': 'openai/gpt-3.5-turbo',
    'messages': [{'role': 'user', 'content': query}]
}, headers={'Authorization': f'Bearer {API_KEY}'})
print(response.json()['choices'][0]['message']['content'])

