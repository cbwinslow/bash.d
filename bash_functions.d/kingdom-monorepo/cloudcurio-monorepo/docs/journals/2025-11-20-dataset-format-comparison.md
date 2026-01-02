# Dataset Format Comparison — 2025-11-20

## Sources inspected
- Local ChatGPT export at `51d8b490bdbfb31663bc397278ad2e4039a8224a109f462f781884af1fa3527c-2025-11-15-08-16-45-67d5176ed4a74597812e8fab34ef0bdc/`: `conversations.json` (2,373 convos, tree-form `mapping` with `author.role`, `content.parts`), `shared_conversations.json` (ids/titles), no populated `group_chats`.
- Hugging Face reference shapes (schema only, not stored locally):
  - `anon8231489123/ShareGPT_V4.3_unfiltered_cleaned_split`: `{"id": "...","conversations":[{"from":"human","value":"..."},{"from":"gpt","value":"..."}]}`.
  - `HuggingFaceH4/ultrachat_200k`: `{"id": "...","conversations":[{"role":"user","content":"..."},{"role":"assistant","content":"..."}]}`.
  - `OpenAssistant/oasst1`: JSONL with flat messages (`message_id`, `parent_id`, `text`, `role`, `lang`, `message_tree_id`) requiring tree flattening to threads.

## Alignment notes
- The ChatGPT export is a node graph per conversation; it needs flattening into ordered message lists. Each node carries `author.role` (`system`/`user`/`assistant`/tool), `content.content_type` plus `parts` array.
- Common open datasets store linear turns with normalized `role` (`user`/`assistant`) and one text field. Tool calls and attachments are rare; if retained, add optional `tool_calls`/`attachments` fields.
- Titles and timestamps are sometimes absent in public sets; keep ours as metadata fields (`title`, `create_time`, `update_time`, `conversation_id`) to aid filtering but exclude from embedding text.

## Proposed normalized JSONL schema
- One conversation per line: `{"id","source","title","created_at","updated_at","messages":[{"role","content","name","metadata"}],"tags":[],"attachments":[]}`
- `role` constrained to `system|user|assistant|tool`; `content` is a single string (join parts with `\n`), `name` optional (for tool/functions), `metadata` for redaction flags.
- Store under `Organized/Conversations/chatgpt/2025-11-15/clean_conversations.jsonl` and mirror a vector index alongside it.

## Minimal transform sketch (for converter)
1) Load one conversation `mapping`; topologically order by parent/child; ignore `message: null` roots.  
2) For each message, build `{role, content="\\n".join(parts or []), name=author.name, created_at, metadata={model: message.metadata.get('model_slug')}}`.  
3) Drop empty content; collapse consecutive system messages into one block per conversation head.  
4) Redact PII (emails, phones, URLs, names, locations, keys) and strip EXIF from referenced files; keep a private mapping if rehydration is needed.  
5) Emit JSONL with stable `id` (e.g., `conversation_id`), sorted by `created_at` fallback to traversal order.

## Comparison outcome
- Our flattened+redacted schema will match common `messages`-list datasets (ShareGPT/UltraChat) while preserving optional metadata for analytics, so external buyers can consume it without custom loaders.
- No format changes needed beyond flattening and redaction; we should ensure tool calls/attachments are either dropped or stored in optional fields to remain compatible with downstream loaders.
