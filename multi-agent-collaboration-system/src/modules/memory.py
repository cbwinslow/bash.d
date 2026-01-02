"""
A module for managing the shared memory of the agent system.
"""

import json

class Memory:
    """
    A simple file-based memory store.
    """
    def __init__(self, file_path):
        self.file_path = file_path
        self.data = self._load()
        print("Memory module initialized.")

    def _load(self):
        try:
            with open(self.file_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except FileNotFoundError:
            return {}

    def _save(self):
        with open(self.file_path, 'w', encoding='utf-8') as f:
            json.dump(self.data, f, indent=2)

    def set(self, key, value):
        """
        Sets a value in the memory.
        """
        print(f"Memory: Setting '{key}'")
        self.data[key] = value
        self._save()

    def get(self, key):
        """
        Gets a value from the memory.
        """
        print(f"Memory: Getting '{key}'")
        return self.data.get(key)
