import logging
from anthropic import Anthropic
from backend.config import settings

logger = logging.getLogger(__name__)


class ClaudeService:
    def __init__(self):
        self.client = Anthropic(api_key=settings.api_key)
        self.conversation_history = []

    def chat(
        self,
        user_message: str,
        chatbot_name: str = "Zachar IA",
        user_name: str = None,
        language: str = "french",
        blagues: bool = False,
        behavior: str = "friendly",
    ) -> str:
        system_prompt = self._build_system_prompt(
            chatbot_name, user_name, language, blagues, behavior
        )
        self.conversation_history.append({"role": "user", "content": user_message})

        try:
            response = self.client.messages.create(
                model=settings.api_model,
                max_tokens=1024,
                system=system_prompt,
                messages=self.conversation_history,
            )
            assistant_message = response.content[0].text
            self.conversation_history.append({"role": "assistant", "content": assistant_message})
            return assistant_message

        except Exception as e:
            logger.error(f"Claude API error: {type(e).__name__}")
            self.conversation_history.pop()
            return "Désolé, je n'ai pas pu traiter votre message. Veuillez réessayer."

    def reset_conversation(self):
        self.conversation_history = []

    def get_conversation_length(self) -> int:
        return len(self.conversation_history) // 2

    def _build_system_prompt(
        self, chatbot_name: str, user_name: str, language: str, blagues: bool, behavior: str
    ) -> str:
        prompt = (
            f"Tu es {chatbot_name}, un chatbot intelligent et professionnel.\n"
            "Ton rôle:\n"
            "- Avoir des conversations naturelles et utiles\n"
            "- Être honnête et admettre si tu ne sais pas quelque chose\n"
            "- Adapter ton ton selon le contexte\n"
            "- Être respectueux et bienveillant"
        )

        if user_name:
            prompt += f"\n- L'utilisateur s'appelle {user_name}. Utilise son nom occasionnellement."

        tone_map = {
            "friendly": "\n- Sois amical et approachable",
            "professional": "\n- Sois professionnel et formel",
            "funny": "\n- Sois drôle et amusant",
        }
        prompt += tone_map.get(behavior, "")

        if blagues:
            prompt += "\n- N'hésite pas à faire des blagues quand c'est approprié"

        if language != "french":
            prompt += f"\n- Réponds toujours en {language}"

        return prompt
