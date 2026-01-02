"""
A module for interacting with the GitHub API.
"""

import os
import requests

class GitHubClient:
    """
    A client for the GitHub API.
    """
    def __init__(self, api_url, token):
        self.api_url = api_url
        self.token = token
        self.headers = {
            'Authorization': f'token {self.token}',
            'Accept': 'application/vnd.github.v3+json',
        }
        print("GitHubClient initialized.")

    def search_repositories(self, query):
        """
        Searches for repositories on GitHub.
        """
        print(f"Searching for repositories with query: {query}")
        search_url = f"{self.api_url}/search/repositories"
        params = {'q': query}
        response = requests.get(search_url, headers=self.headers, params=params)
        response.raise_for_status()
        return response.json()

def get_github_client_from_config(config):
    """
    Creates a GitHubClient from the application configuration.
    """
    token = os.getenv(config['github']['token_env_var'])
    if not token:
        raise ValueError("GitHub token not found in environment variables.")
    
    return GitHubClient(
        api_url=config['github']['api_url'],
        token=token
    )
