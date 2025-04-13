# def check_riddle_answer(answer: str) -> bool:
#     if not isinstance(answer, str) or not answer:
#         return False
#     return "diary" in answer.strip().lower()

# print(check_riddle_answer("my diary"))      # True
# print(check_riddle_answer("DIARY"))         # True
# print(check_riddle_answer("diary entry"))   # True
# print(check_riddle_answer("journal"))       # False
# print(check_riddle_answer(""))              # False
# print(check_riddle_answer(None))            # False





from fuzzywuzzy import fuzz

def check_riddle_answer(answer: str) -> bool:
    cleaned_answer = answer.strip().lower()
    if len(cleaned_answer) < 4:
        return False
    similarity = max(
        fuzz.ratio(cleaned_answer, "voldemort"),
        fuzz.token_sort_ratio(cleaned_answer, "voldemort")
    )
    return similarity >= 85

print(check_riddle_answer("v"))
print(check_riddle_answer("vol"))
print(check_riddle_answer("vold"))
print(check_riddle_answer("voldem"))
print(check_riddle_answer("v0ldem"))
print(check_riddle_answer("v0ldem0rt"))
print(check_riddle_answer("v0ld3m0rt")) 
print(check_riddle_answer(""))        
print(check_riddle_answer("voldemor"))
print(check_riddle_answer("voldemort"))
print(check_riddle_answer("voldemort1"))
print(check_riddle_answer("valdemort"))
print(check_riddle_answer(None))      