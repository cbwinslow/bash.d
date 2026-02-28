#!/usr/bin/env python3
"""
RAG (Retrieval-Augmented Generation) System for bash.d
Stores and retrieves conversations and logs using ChromaDB.
"""

import os
import json
from datetime import datetime
from typing import List, Dict, Any, Optional
import chromadb
from chromadb.config import Settings
import hashlib

# ChromaDB settings
CHROMA_HOST = os.getenv("CHROMA_HOST", "localhost")
CHROMA_PORT = int(os.getenv("CHROMA_PORT", "8000"))

class RAGSystem:
    """RAG system using ChromaDB."""
    
    def __init__(self, persist_directory: str = "./chroma_data"):
        """Initialize RAG system."""
        # Connect to ChromaDB server
        self.client = chromadb.HttpClient(
            host=CHROMA_HOST,
            port=CHROMA_PORT,
            settings=Settings(anonymized_telemetry=False)
        )
        
        self.persist_directory = persist_directory
        
        # Collections
        self.conversations = None
        self.logs = None
        self.system_docs = None
        
        self._init_collections()
    
    def _init_collections(self):
        """Initialize or get collections."""
        # Conversations collection
        try:
            self.conversations = self.client.get_or_create_collection(
                "conversations",
                metadata={"description": "AI conversations for RAG"}
            )
        except Exception as e:
            print(f"Error creating conversations collection: {e}")
        
        # Logs collection
        try:
            self.logs = self.client.get_or_create_collection(
                "system_logs",
                metadata={"description": "System logs for RAG"}
            )
        except Exception as e:
            print(f"Error creating logs collection: {e}")
        
        # System docs collection
        try:
            self.system_docs = self.client.get_or_create_collection(
                "system_docs",
                metadata={"description": "System documentation"}
            )
        except Exception as e:
            print(f"Error creating docs collection: {e}")
    
    def _generate_id(self, text: str, prefix: str = "") -> str:
        """Generate a unique ID for a document."""
        hash_obj = hashlib.md5(text.encode())
        return f"{prefix}{hash_obj.hexdigest()[:16]}"
    
    # ====================
    # Conversations
    # ====================
    
    def add_conversation(self, tool: str, prompt: str, response: str, 
                        model: str = None, session_id: str = None,
                        metadata: dict = None) -> str:
        """Add a conversation to the vector DB."""
        if not self.conversations:
            return None
        
        # Create combined text for embedding
        text = f"Tool: {tool}\nPrompt: {prompt}\nResponse: {response}"
        
        # Generate ID
        doc_id = self._generate_id(text, f"conv_")
        
        # Metadata
        meta = {
            "tool": tool,
            "model": model or "unknown",
            "session_id": session_id or "default",
            "timestamp": datetime.utcnow().isoformat(),
            "type": "conversation"
        }
        if metadata:
            meta.update(metadata)
        
        try:
            self.conversations.add(
                documents=[text],
                ids=[doc_id],
                metadatas=[meta]
            )
            return doc_id
        except Exception as e:
            print(f"Error adding conversation: {e}")
            return None
    
    def search_conversations(self, query: str, n_results: int = 5, 
                            tool: str = None) -> List[Dict]:
        """Search conversations by semantic similarity."""
        if not self.conversations:
            return []
        
        # Build where clause for filtering
        where = {"type": "conversation"}
        if tool:
            where["tool"] = tool
        
        try:
            results = self.conversations.query(
                query_texts=[query],
                n_results=n_results,
                where=where if tool else None
            )
            
            return self._format_results(results)
        except Exception as e:
            print(f"Error searching conversations: {e}")
            return []
    
    # ====================
    # System Logs
    # ====================
    
    def add_log(self, source: str, message: str, level: str = "info",
                metadata: dict = None) -> str:
        """Add a log entry to the vector DB."""
        if not self.logs:
            return None
        
        text = f"[{level.upper()}] {source}: {message}"
        
        doc_id = self._generate_id(text, f"log_")
        
        meta = {
            "source": source,
            "level": level,
            "timestamp": datetime.utcnow().isoformat(),
            "type": "log"
        }
        if metadata:
            meta.update(metadata)
        
        try:
            self.logs.add(
                documents=[text],
                ids=[doc_id],
                metadatas=[meta]
            )
            return doc_id
        except Exception as e:
            print(f"Error adding log: {e}")
            return None
    
    def search_logs(self, query: str, n_results: int = 10,
                   level: str = None, source: str = None) -> List[Dict]:
        """Search logs by semantic similarity."""
        if not self.logs:
            return []
        
        # Build where clause
        where = {"type": "log"}
        if level:
            where["level"] = level
        if source:
            where["source"] = source
        
        try:
            results = self.logs.query(
                query_texts=[query],
                n_results=n_results,
                where=where if (level or source) else None
            )
            
            return self._format_results(results)
        except Exception as e:
            print(f"Error searching logs: {e}")
            return []
    
    # ====================
    # System Documentation
    # ====================
    
    def add_doc(self, title: str, content: str, doc_type: str = "general",
                metadata: dict = None) -> str:
        """Add documentation to the vector DB."""
        if not self.system_docs:
            return None
        
        text = f"{title}\n\n{content}"
        
        doc_id = self._generate_id(text, f"doc_")
        
        meta = {
            "title": title,
            "doc_type": doc_type,
            "timestamp": datetime.utcnow().isoformat(),
            "type": "doc"
        }
        if metadata:
            meta.update(metadata)
        
        try:
            self.system_docs.add(
                documents=[text],
                ids=[doc_id],
                metadatas=[meta]
            )
            return doc_id
        except Exception as e:
            print(f"Error adding doc: {e}")
            return None
    
    def search_docs(self, query: str, n_results: int = 5,
                   doc_type: str = None) -> List[Dict]:
        """Search documentation by semantic similarity."""
        if not self.system_docs:
            return []
        
        where = {"type": "doc"}
        if doc_type:
            where["doc_type"] = doc_type
        
        try:
            results = self.system_docs.query(
                query_texts=[query],
                n_results=n_results,
                where=where if doc_type else None
            )
            
            return self._format_results(results)
        except Exception as e:
            print(f"Error searching docs: {e}")
            return []
    
    # ====================
    # General Search
    # ====================
    
    def search_all(self, query: str, n_results: int = 10) -> Dict[str, List[Dict]]:
        """Search across all collections."""
        return {
            "conversations": self.search_conversations(query, n_results),
            "logs": self.search_logs(query, n_results),
            "docs": self.search_docs(query, n_results)
        }
    
    # ====================
    # Utilities
    # ====================
    
    def _format_results(self, results: dict) -> List[Dict]:
        """Format ChromaDB results."""
        formatted = []
        
        if not results or not results.get("documents"):
            return formatted
        
        for i, doc in enumerate(results["documents"][0]):
            formatted.append({
                "id": results["ids"][0][i] if results.get("ids") else None,
                "document": doc,
                "metadata": results["metadatas"][0][i] if results.get("metadatas") else None,
                "distance": results["distances"][0][i] if results.get("distances") else None
            })
        
        return formatted
    
    def get_stats(self) -> Dict:
        """Get collection stats."""
        stats = {}
        
        for name, collection in [
            ("conversations", self.conversations),
            ("logs", self.logs),
            ("docs", self.system_docs)
        ]:
            if collection:
                try:
                    stats[name] = collection.count()
                except:
                    stats[name] = 0
            else:
                stats[name] = 0
        
        return stats
    
    def clear_all(self):
        """Clear all collections."""
        for collection in [self.conversations, self.logs, self.system_docs]:
            if collection:
                try:
                    collection.delete()
                except:
                    pass
        
        self._init_collections()


# ====================
# CLI Interface
# ====================

def main():
    """CLI for RAG system."""
    import sys
    
    rag = RAGSystem()
    
    if len(sys.argv) < 2:
        print("Usage: rag.py <command> [args]")
        print("")
        print("Commands:")
        print("  add-conv <tool> <prompt> <response>")
        print("  search <query>")
        print("  stats")
        print("  clear")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "add-conv":
        if len(sys.argv) < 5:
            print("Usage: add-conv <tool> <prompt> <response>")
            sys.exit(1)
        
        tool = sys.argv[2]
        prompt = sys.argv[3]
        response = sys.argv[4]
        
        doc_id = rag.add_conversation(tool, prompt, response)
        print(f"Added conversation: {doc_id}")
    
    elif command == "search":
        if len(sys.argv) < 3:
            print("Usage: search <query>")
            sys.exit(1)
        
        query = " ".join(sys.argv[2:])
        results = rag.search_all(query)
        
        print(f"\n=== Search Results for: {query} ===\n")
        
        for category, items in results.items():
            if items:
                print(f"━━━ {category.upper()} ━━━")
                for item in items:
                    print(f"  {item['document'][:200]}...")
                    print(f"  Metadata: {item.get('metadata')}")
                    print()
    
    elif command == "stats":
        stats = rag.get_stats()
        print("━━━ RAG Stats ━━━")
        for name, count in stats.items():
            print(f"  {name}: {count} documents")
    
    elif command == "clear":
        rag.clear_all()
        print("All collections cleared!")
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()
