# Tom Riddle's Diary

![Diary Icon](📖) *Write with care... the diary never forgets.*

**Tom Riddle's Diary** is an interactive web application built with [Streamlit](https://streamlit.io/) that emulates the enchanted diary of Tom Marvolo Riddle from the *Harry Potter* series. Powered by a local language model (Ollama's `phi3`), the app lets users converse with a young Tom Riddle, whose responses are cryptic, manipulative, and laced with dark charm. The diary challenges users with a riddle about Riddle's true identity, creating an immersive and eerie experience.

## Table of Contents
- [Project Overview](#project-overview)
- [Features](#features)
- [Technical Details](#technical-details)
- [Styling and Aesthetic](#styling-and-aesthetic)
- [Installation and Setup](#installation-and-setup)
- [Usage](#usage)
- [Future Improvements](#future-improvements)
- [License](#license)

## Project Overview

This project brings Tom Riddle’s diary to life as a digital artifact. Users write entries, and the diary responds as if possessed by Riddle’s youthful soul, probing their secrets and guarding its own. A key feature is the riddle mechanic, where users must guess Riddle’s true name ("Voldemort") to unlock deeper interactions. The app combines natural language processing, state management, and custom styling to create a magical yet menacing experience.

The goal was to craft a user interface that feels like writing in a cursed book, with a handwritten font, dark colors, and a sinister atmosphere, while ensuring readability and engagement.

## Features

- **Interactive Dialogue**: Converse with Tom Riddle, who responds with cold eloquence and veiled superiority, using a local language model (`phi3`).
- **Riddle Challenge**: After mentioning identity-related keywords (e.g., "who are you"), the diary poses a riddle: "What is my true name?" Correctly answering "Voldemort" advances the interaction.
- **State Management**: Tracks conversation history, user name, turn count, and riddle status using a typed dictionary (`DiaryState`).
- **Dynamic Responses**: Randomizes greetings and riddle prompts for variety, enhancing replayability.
- **Error Handling**: Gracefully manages empty inputs and model errors, with warnings like "The diary demands words..."
- **Session Control**: Ends the session after 10 exchanges or if the user says "goodbye," mimicking a closing book.
- **Dark Aesthetic**: Custom styling with a handwritten font, dark backgrounds, and eerie colors to evoke Voldemort’s presence.

## Technical Details

- **Framework**: Streamlit for the web interface, providing a simple yet powerful frontend.
- **Language Model**: Ollama with the `phi3` model for generating Riddle’s responses locally.
- **Libraries**:
  - `streamlit`: For building the app.
  - `ollama`: To interface with the local language model.
  - `fuzzywuzzy`: For flexible riddle answer matching (e.g., accepting "Voldemort" with 80% similarity).
  - `typing`, `operator`, `random`: For state management and response variety.
- **State Structure**: Uses a `DiaryState` typed dictionary to manage:
  - `messages`: List of user and assistant messages.
  - `turn_count`: Tracks conversation turns.
  - `user_input`: Stores the latest input.
  - `user_name`: Records the user’s name.
  - `riddle_active`: Flags when the riddle is posed.
  - `riddle_answered`: Tracks if the riddle is solved.
- **Logic Flow**:
  1. Prompts for the user’s name on first interaction.
  2. Responds to inputs, triggering the riddle if identity keywords are detected.
  3. Evaluates riddle answers using fuzzy matching.
  4. Generates dynamic responses with a system prompt enforcing Riddle’s tone.
  5. Ends the session after set conditions.

## Styling and Aesthetic

The app’s design mirrors a dark, magical diary, with styling tailored to feel like Tom Riddle’s own handiwork:

- **Font**: Uses "Shadows Into Light" (Google Fonts) for a legible, handwritten look, applied to messages, inputs, and buttons.
- **Colors**:
  - **Background**: Dark gray (`#1a1a1a`) for the app, black (`#0d0d0d`) for the chat area, evoking a cursed parchment.
  - **Diary Text**: Greenish-white (`#d4e4d4`) with a text shadow, suggesting Slytherin and dark magic.
  - **User Text**: Muted gray (`#b3b3b3`) to contrast with Riddle’s dominant voice.
  - **Input Label**: White (`#ffffff`) for the "Write in the diary:" prompt, standing out sharply.
  - **Button**: Dark red background (`#4a1c1c`) with black text (`#000000`) for the "Etch Your Words" button, ensuring readability and menace.
- **Chat Container**: Black with a red border (`#4a1c1c`), like a book bound in blood.
- **Readability**: Large font sizes (24px for messages, 20px for inputs/buttons) ensure clarity, even with the cursive font.

The black text on the button was a deliberate choice to improve contrast against the dark red background, finalized after testing various colors to ensure it pops without clashing with the eerie theme.

## Installation and Setup

### Prerequisites
- Python 3.8+
- [Ollama](https://ollama.ai/) installed with the `phi3` model pulled.
- A modern web browser.

### Steps
1. **Clone the Repository** (if hosted):
```bash
git clone <repository-url>
cd tom-riddles-diary
```
2. **Install Dependencies**: Create a virtual environment and install required packages:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install streamlit ollama fuzzywuzzy python-Levenshtein
```
3. **Set Up Ollama**: Ensure Ollama is running and the phi3 model is available:
```bash
ollama pull phi3
ollama serve
```
4. **Run the App**: Launch the Streamlit app:
```bash
streamlit run app.py
```
Open the provided URL (e.g., http://localhost:8501) in your browser.

### Notes
Ensure Ollama is running before starting the app, or you’ll see errors like "The diary trembles."
If python-Levenshtein fails to install, fuzzywuzzy will work but may be slower.

## Usage
1. Open the App: Access the app in your browser.
2. Enter Your Name: Write your name in the input field to begin.
3. Converse: Type messages in the "Write in the diary:" field and click "Etch Your Words."
- Try asking about Riddle’s identity (e.g., "Who are you?") to trigger the riddle.
- Answer the riddle with "Voldemort" (spelling variations are tolerated).
4. Explore Responses: Riddle’s replies are short, cryptic, and may reference Harry Potter characters like Dumbledore or Hagrid.
5. End the Session: Say "goodbye" or reach 10 exchanges to close the diary.
6. Restart: Refresh the page to start a new session.
### Example Interaction:

- **Diary**: Greetings. I am the diary of Tom Marvolo Riddle. Write your name, and we shall begin.
- **You**: Harry
- **Diary**: Hello Harry, my name is Tom Riddle. How did my diary fall into your hands?
- **You**: Who are you really?
- **Diary**: You think you know me, Harry? I am Tom Riddle, yet that name hides a greater truth. What is my true name?
- **You**: Voldemort
- **Diary**: Yesss, Harry. I am Voldemort, and this diary holds my essence. What secrets will you share with me now?

## Future Improvements
- Advanced NLP: Integrate a larger model (e.g., LLaMA) for richer, more nuanced responses.
- Memory Expansion: Store more conversation history to deepen Riddle’s manipulation.
- Animations: Add ink-drip or fade-in effects for messages to enhance the magical feel.
- Sound Effects: Include subtle audio (e.g., whispers) for immersion, if browser-compatible.
- Custom Riddles: Introduce new puzzles tied to Harry Potter lore, like Horcrux hints.
- Accessibility: Add options for higher contrast or larger fonts for better usability.
- Multi-language Support: Allow Riddle to respond in other languages for global users.

## License
This project is licensed under the GNU License. See the LICENSE file for details.

Created with a touch of dark magic by Guilherme. Open the diary at your own risk.




