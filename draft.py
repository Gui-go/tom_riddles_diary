def check_riddle_answer(answer: str) -> bool:
    if not isinstance(answer, str) or not answer:
        return False
    return "diary" in answer.strip().lower()



print(check_riddle_answer("my diary"))      # True
print(check_riddle_answer("DIARY"))         # True
print(check_riddle_answer("diary entry"))   # True
print(check_riddle_answer("journal"))       # False
print(check_riddle_answer(""))              # False
print(check_riddle_answer(None))            # False