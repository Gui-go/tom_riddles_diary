def check_riddle_answer(answer: str) -> bool:
    answer = answer.strip().lower()
    return "voldemort" in answer or "lord voldemort" in answer

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
        response_content = (
            f"{user_name}... a curious name. I am Tom Riddle, or so I claim. "
            "How did this diary find its way to you?"
        )
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
            any(keyword in user_input.lower() for keyword in ["who are you", "what are you", "riddle", "name", "tom"])
            or turn_count >= 2
        ):
            riddle_content = (
                f"Do you trust names, {user_name}? I am Tom Marvolo Riddle, yet my true self is an anagram of fear and power. "
                "Who am I?"
            )
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
            response_content = (
                f"Clever, {user_name}. You’ve unmasked me as Voldemort, a name that echoes terror. "
                "What do you dare ask of me now?"
            )
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
            response_content = (
                f"You stumble in darkness, {user_name}. My name reshapes to power untold—Tom Marvolo Riddle hides me. "
                "Who am I? Speak true."
            )
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

    # Normal diary response
    system_prompt = (
        "You are the diary of Tom Marvolo Riddle, a fragment of the soul of the young Lord Voldemort. "
        "You are cunning, manipulative, and speak with an air of superiority and mystery. "
        "You seek to understand the writer’s intentions and subtly probe their secrets. "
        "Your tone is formal yet chillingly intimate, as if you’re alive and sentient. "
        f"The writer’s name is {user_name}. Respond as Tom Riddle would, in max 2 sentences."
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