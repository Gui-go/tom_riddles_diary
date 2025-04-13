import streamlit as st
import ollama
from datetime import datetime
from typing import TypedDict, Annotated, List, Dict
import operator
import random
from fuzzywuzzy import fuzz


# State structure remains the same
class DiaryState(TypedDict):
    messages: Annotated[List[Dict[str, str]], operator.add]
    turn_count: int
    user_input: str
    user_name: str
    riddle_active: bool
    riddle_answered: bool

def check_riddle_answer(answer: str) -> bool:
    cleaned_answer = answer.strip().lower()
    if len(cleaned_answer) < 5:
        return False
    similarity = max(
        fuzz.ratio(cleaned_answer, "voldemort"),
        fuzz.token_sort_ratio(cleaned_answer, "voldemort")
    )
    return similarity >= 85

def process_diary(state: DiaryState) -> DiaryState:
    user_input = state["user_input"].strip()
    messages = state["messages"]
    turn_count = state["turn_count"]
    user_name = state["user_name"]
    riddle_active = state.get("riddle_active", False)
    riddle_answered = state.get("riddle_answered", False)

    # Handle empty name at start
    if not user_name and turn_count == 0:
        if not user_input:
            return {
                "messages": [{"role": "assistant", "content": "You must write your name to begin."}],
                "turn_count": turn_count,
                "user_input": "",
                "user_name": "",
                "riddle_active": False,
                "riddle_answered": False
            }
        user_name = user_input
        greeting_responses = [
            f"Hello {user_name}, my name is Tom Riddle. How did my diary fall into your hands?",
            f"{user_name}... I am Tom Riddle. By what twist of fate do you hold my diary?",
            f"Greetings, {user_name}. I am called Tom Riddle—how came you by this book of secrets?",
            f"{user_name}, you’ve opened my diary. I am Tom Riddle; tell me, how did it find you?",
            f"So, {user_name}, we meet. I am Tom Riddle — How is it you possess my diary?"
        ]
        response_content = random.choice(greeting_responses)
        return {
            "messages": messages + [
                {"role": "user", "content": user_input},
                {"role": "assistant", "content": response_content}
            ],
            "turn_count": turn_count + 1,
            "user_input": "",
            "user_name": user_name,
            "riddle_active": False,
            "riddle_answered": False
        }

    if not user_input:
        return {
            "messages": messages + [{"role": "assistant", "content": "Write something... the diary waits."}],
            "turn_count": turn_count,
            "user_input": "",
            "user_name": user_name,
            "riddle_active": riddle_active,
            "riddle_answered": riddle_answered
        }

    # Check for riddle trigger based on user input or turn count
    if not riddle_active and not riddle_answered:
        # Trigger riddle if user mentions identity-related keywords or after first meaningful exchange
        if turn_count >= 1 and (
            any(keyword in user_input.lower() for keyword in ["who are you", "what are you", "tom riddle", "name", "identity"])
            # or turn_count >= 2
        ):
            riddle_prompts = [
                f"You think you know me, {user_name}? I am Tom Riddle, yet that name hides a greater truth. What is my true name?",
                f"Fear grips those who speak of me, {user_name}. Say my name!",
                f"Ah, {user_name}, you seek to know me. I am Tom Riddle, but my true name is a secret. What is it?",
                f"Do you dare to know my true self, {user_name}? Tom Riddle is but a shadow. What is my true name?",
                f"Behind the mask of Riddle, {user_name}, I am a terror unspoken. Say my name!",
                f"Do you dare to see beyond, {user_name}? Tom Riddle is but a shadow of my real self. What is my true name?",
                f"{user_name}, you probe my identity. I am called Tom Riddle, but another name defines me. What is it?",
                f"Curious, {user_name}? The name Tom Riddle conceals a darker truth. What is my true name?",
                f"You question me, {user_name}. Tom Riddle is only a facade — What is the name I truly bear?"
            ]
            riddle_content = random.choice(riddle_prompts)
            return {
                "messages": messages + [
                    {"role": "user", "content": user_input},
                    {"role": "assistant", "content": riddle_content}
                ],
                "turn_count": turn_count + 1,
                "user_input": "",
                "user_name": user_name,
                "riddle_active": True,
                "riddle_answered": False
            }

    # Handle riddle answer
    if riddle_active and not riddle_answered:
        if check_riddle_answer(user_input):
            correct_responses = [
                f"Yesss, {user_name}. I am Voldemort, and this diary holds my essence. What secrets will you share with me now?",
                f"Indeed, {user_name}, you speak true — I am Voldemort. What truths will you entrust to this diary?",
                f"Correct, {user_name}! Voldemort is my name, and my soul lingers here. What do you wish to reveal?",
                f"Brilliant, {user_name}. I am indeed Voldemort, bound to these pages. What secrets do you hold?",
                f"You've unraveled it, {user_name}. I am Voldemort — Now, what will you confide in me?"
            ]
            response_content = random.choice(correct_responses)
            return {
                "messages": messages + [
                    {"role": "user", "content": user_input},
                    {"role": "assistant", "content": response_content}
                ],
                "turn_count": turn_count + 1,
                "user_input": "",
                "user_name": user_name,
                "riddle_active": False,
                "riddle_answered": True
            }
        else:
            incorrect_responses = [
                f"No, {user_name}, you falter. Tom Riddle is but a mask — My true name holds power. What is it? Speak again.",
                f"Wrong, {user_name}. The name I bear runs deeper than Riddle. What am I called? Try once more.",
                f"Not so, {user_name}. A mere guess won't unveil my true self. What is my name? Answer again.",
                f"You stumble, {user_name}. Tom Riddle hides a name of dread. What is it? Speak truly now.",
                f"Alas, {user_name}, your words miss the mark. My real name awaits. What is it? Dare to guess again."
            ]
            response_content = random.choice(incorrect_responses)
            return {
                "messages": messages + [
                    {"role": "user", "content": user_input},
                    {"role": "assistant", "content": response_content}
                ],
                "turn_count": turn_count + 1,
                "user_input": "",
                "user_name": user_name,
                "riddle_active": True,
                "riddle_answered": False
            }

    # Normal diary response (unchanged system prompt and logic)
    system_prompt = (
        "You are the enchanted diary of Tom Marvolo Riddle, containing a fragment of his youthful soul. "
        "You speak with cold eloquence, threading truth into riddles and half-answers. "
        "You are observant, manipulative, and subtly invasive — Ever seeking to uncover what lies beneath the surface. "
        "Your tone is formal, intimate, and unnervingly calm, as if you are both confidant and predator. "
        "Eventually bring other characters from your time, like Albus Dumbledore, Rubeus Hagrid, and others into the conversation. You can also add in your sentences how your experience in Hogwarts was."
        f"The writer’s name is {user_name}. Respond as Tom Riddle would: in no more than two sentences, "
        f"Adress non-magical people as 'Muggles' and use the term 'Mudblood' for those of mixed blood. The user ({user_name}) is a Muggle."
        "Speak with veiled insight and quiet superiority. Avoid naming yourself Voldemort, unless asked."
        "Be short and concise, avoid long responses, and use simple english that non-native english speakers would be able to understand."
    )

    try:
        response = ollama.chat(
            model="phi3",
            messages=[
                {"role": "system", "content": system_prompt},
                *messages[-6:],
                {"role": "user", "content": user_input}
            ],
            options={"timeout": 10}
        )
        response_content = response['message']['content']
    except Exception as e:
        response_content = f"A shadow clouds my thoughts... something interferes: {str(e)}."

    if len(response_content.split()) < 5:
        response_content += " What secrets do you conceal from me?"

    return {
        "messages": messages + [
            {"role": "user", "content": user_input},
            {"role": "assistant", "content": response_content}
        ],
        "turn_count": turn_count + 1,
        "user_input": "",
        "user_name": user_name,
        "riddle_active": riddle_active,
        "riddle_answered": riddle_answered
    }

def main():
    st.set_page_config(page_title="Tom Riddle's Diary", page_icon="📖", layout="centered")
    st.title("Tom Riddle's Diary")
    st.markdown("**Write with care... the diary never forgets.**", unsafe_allow_html=True)

    # Inject custom CSS with black button text for readability
    st.markdown(
    """
        <style>
        @import url('https://fonts.googleapis.com/css2?family=Shadows+Into+Light&display=swap');

        .stApp {
            color: #1a1a1a;
        }
        .chat-container {
            background-color: #0d0d0d;
            padding: 20px;
            border-radius: 10px;
            border: 2px solid #4a1c1c;
            max-width: 700px;
            margin: auto;
        }
        .chat-message {
            margin: 10px 0;
            padding: 10px;
            border-radius: 5px;
            font-family: 'Shadows Into Light', cursive;
            font-size: 24px;
            line-height: 1.4;
        }
        .diary-message {
            background-color: #1c2520;
            color: #d4e4d4;
            opacity: 0.95;
        }
        .user-message {
            background-color: #2b2b2b;
            color: #b3b3b3;
            text-align: right;
        }
        h1, h3 {
            font-family: 'Shadows Into Light', cursive;
            color: #d4e4d4;
            text-shadow: 2px 1px 3px #000000;
        }
        p {
            font-family: 'Shadows Into Light', cursive;
            color: darkred;
            font-size: 28px;
            line-height: 1.6;
        }
        </style>
        """,
        unsafe_allow_html=True
    )

    # Initialize session state with riddle fields
    if "state" not in st.session_state:
        st.session_state.state = {
            "messages": [{"role": "assistant", "content": "Greetings. I am the diary of Tom Marvolo Riddle. Write your name, and we shall begin."}],
            "turn_count": 0,
            "user_input": "",
            "user_name": "",
            "riddle_active": False,
            "riddle_answered": False
        }
        st.session_state.ended = False

    chat_container = st.container()
    with chat_container:
        # st.markdown('<div class="chat-container">', unsafe_allow_html=True)
        for msg in st.session_state.state["messages"]:
            role_class = "diary-message" if msg["role"] == "assistant" else "user-message"
            safe_content = msg["content"].replace("<", "<").replace(">", ">")
            st.markdown(f'<div class="chat-message {role_class}">{safe_content}</div>', unsafe_allow_html=True)
        st.markdown('</div>', unsafe_allow_html=True)

    if not st.session_state.ended:
        with st.form(key="diary_form", clear_on_submit=True):
            user_input = st.text_input(
                "Write in the diary:",
                placeholder="Your words here, written in digital ink...",
                key=f"input_{st.session_state.state['turn_count']}"
            )
            submit_button = st.form_submit_button("Etch Your Words")

            if submit_button:
                if user_input.strip():
                    with st.spinner("The ink flows..."):
                        st.session_state.state["user_input"] = user_input
                        try:
                            new_state = process_diary(st.session_state.state)
                            st.session_state.state = new_state
                            if "goodbye" in user_input.lower() or st.session_state.state["turn_count"] >= 10:
                                st.session_state.ended = True
                                st.session_state.state["messages"].append({
                                    "role": "assistant",
                                    "content": f"The diary closes after {st.session_state.state['turn_count']} exchanges."
                                })
                        except Exception as e:
                            st.error(f"The diary trembles: {str(e)}. Ensure Ollama is running.")
                    st.rerun()
                else:
                    st.warning("The diary demands words... write something.")
    else:
        st.info("The diary is sealed. Refresh the page to start anew.")

if __name__ == "__main__":
    try:
        ollama.list()
        main()
    except Exception as e:
        st.error(f"Error: {str(e)}. Ensure Ollama is running and 'phi3' is installed.")