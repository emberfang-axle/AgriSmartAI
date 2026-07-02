"""
Local conversational AI — keyword-scored QA engine.
No external LLM APIs used.
"""
import json
import os

_KB_PATH = os.path.join(os.path.dirname(__file__), 'knowledge', 'qa_pairs.json')
_kb_cache: list | None = None


def _load_kb() -> list:
    global _kb_cache
    if _kb_cache is None:
        with open(_KB_PATH, encoding='utf-8') as f:
            _kb_cache = json.load(f)
    return _kb_cache


def get_response(message: str) -> str:
    message_lower = message.lower()
    try:
        kb = _load_kb()
    except Exception:
        return (
            "I'm having trouble accessing my knowledge base. "
            "Please consult your local DA technician."
        )

    best_score = 0
    best_answer = None

    for entry in kb:
        keywords: list[str] = entry.get('keywords', [])
        score = sum(1 for kw in keywords if kw.lower() in message_lower)
        if score > best_score:
            best_score = score
            best_answer = entry.get('answer', '')

    if best_score == 0 or not best_answer:
        return (
            "I'm not sure about that. You can ask me about rice diseases like "
            "Bacterial Leaf Blight, Brown Spot, Leaf Blast, Sheath Blight, or Tungro Virus. "
            "I can also help with fertilizer recommendations and pest management."
        )

    return best_answer
