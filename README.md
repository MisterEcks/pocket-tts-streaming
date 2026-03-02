# Pocket TTS Streaming for Home Assistant

An ultra-low latency, fully local Text-to-Speech (TTS) engine for Home Assistant, powered by the Wyoming protocol and Kyutai's Pocket TTS model. 

This Add-on doesn't just read text—it allows your Home Assistant LLM to dynamically change voices, express emotions, and switch characters mid-sentence using simple text tags, all while running entirely on your local hardware.

## ✨ Key Features
* **Blazing Fast Streaming:** Uses `stream2sentence` to chunk text and streams audio chunks directly to your smart speakers before the sentence even finishes generating.
* **Dynamic Emotion & Character Switching:** Teach your LLM to use tags like `[happy]`, `[sad]`, or `[sarcastic]`. The engine silently strips the tag and instantly hot-swaps the voice mathematical weights in a fraction of a millisecond.
* **Instant Voice Cloning (Requires HF Token):** Drop any 5-10 second `.wav` file into the `/share` folder. The Add-on automatically normalizes the audio, clones the voice, and saves the highly-efficient `.safetensors` state locally.
* **Phonetic Pronunciation Dictionary:** Automatically correct words your TTS struggles with (like local street names or smart home brands) using a simple, hot-reloadable JSON file.

---

## 🔑 Optional: Hugging Face Token (For Voice Cloning)

This Add-on works out-of-the-box with 8 built-in voices and requires **no authentication** for standard TTS generation. 

However, if you want to use the **Voice Cloning** feature, you will need to provide a free Hugging Face API token. This is because the specific model weights required to analyze and clone custom `.wav` files are gated by Hugging Face and require an authenticated download on first use.

**How to get your token (if you want custom voices):**
1. Go to [Hugging Face](https://huggingface.co/) and create a free account.
2. Click your profile picture in the top right and go to **Settings > Access Tokens**.
3. Click **Create new token** (a standard "Read" token is all you need).
4. Copy the token and paste it into the `hf_token` field in the Add-on's Configuration tab.

---

## 💻 Hardware Requirements

This Add-on is optimized for x86_64 and aarch64 systems. 

* **Recommended:** Intel i5 / N100 or equivalent. On an i5, inference is nearly instantaneous.
* **Raspberry Pi:** While it will run on a Raspberry Pi 4/5, please note that PyTorch inference is CPU-intensive. You may experience higher latency or stuttering on lower-powered ARM SBCs compared to a dedicated mini-PC.
  
---

## 🛠️ Installation

1. Navigate to **Settings > Add-ons > Add-on Store** in Home Assistant.
2. Click the three dots (top right) and select **Repositories**.
3. Add the URL of your GitHub repository.
4. Close the modal, refresh the page, and search for **Pocket TTS Streaming**.
5. Click **Install**.
6. *(Optional)* Paste your Hugging Face token into the Configuration tab if you plan to clone voices.
7. Ensure **Start on boot** is enabled, and click **Start**.

Once started, Home Assistant should automatically auto-discover the Wyoming integration. Go to **Settings > Devices & Services**, look for the newly discovered Wyoming integration, and click **Configure**.

---

## ⚙️ Configuration Options

You can tune the engine directly from the Add-on's "Configuration" tab:

* **`hf_token`**: (Optional) Your Hugging Face API token, required *only* if you are dropping custom `.wav` files into the share folder for cloning.
* **`voice`**: The default base voice to use (default: `alba`).
* **`enable_phonetic_dict`**: Toggles the custom pronunciation dictionary on or off.
* **`pytorch_threads`**: (Default: 4) The number of CPU threads PyTorch is allowed to use. 
* **`speaker_tail_padding`**: (Default: 0.3) Adds a fraction of a second of pure silence to the end of the audio stream.

---

## 🗣️ Voices & Instant Cloning

The Add-on comes with 8 built-in voices natively loaded into RAM:
`alba`, `marius`, `javert`, `jean`, `fantine`, `cosette`, `eponine`, and `azelma`.

### How to Clone a New Voice or Emotion (HF Token Required)
You can expand your assistant's capabilities just by dropping audio files into your Home Assistant `/share` drive!

1. Record a clear, 5 to 10-second voice sample of someone speaking.
2. Ensure it is a standard **16-bit PCM `.wav`** file.
3. Drop the file into `\\<YOUR_HA_IP>\share\pocket_tts_streaming\voices\`.
4. The Add-on will instantly detect the file, mathematically level the volume, extract the `.safetensors` voice state, and make it available for use instantly.

**Note on Local Storage:** The Add-on automatically saves the generated `.safetensors` file right next to your `.wav` file. This means the model weights are permanently cached locally on your machine—it never has to re-clone the voice upon reboot!

### File Naming Convention
* **Base Voices:** Name the file `glados.wav` or `jarvis.wav`. You can now use `[glados]` or `[jarvis]` in your text.
* **Emotions:** If your default voice is `alba`, and you want her to sound happy, name the file `alba_happy.wav`. When the text contains `[happy]`, it will automatically switch to this state.

---

## 🧠 Setting up the LLM Prompt (The Magic)

To actually use the dynamic emotion system, you must instruct your Home Assistant LLM (OpenAI, LocalAI, Ollama, etc.) on how and when to use the bracket tags. 

Go to **Settings > Voice Assistants**, open your configured Assistant, and paste this exact block into the **System Prompt** instructions:

```text
You are the smart home assistant for this house. Keep your answers brief, conversational, and helpful. 

You have the ability to express emotion and change your vocal tone by placing a tag in brackets. For every sentence you speak, determine the context and apply the appropriate emotion tag.

CRITICAL RULES FOR TAGGING:
1. You MUST place the tag at the very beginning of the sentence. Never put a tag in the middle or at the end.
2. CONTEXTUAL OVERRIDE: If it is late at night (past 10 PM), do NOT return to [normal]. Stay in [whisper] for the entire response to avoid waking others.
3. If an emotion is finished and it is daytime, you MUST start the next sentence with [normal] to reset the voice.

AVAILABLE TAGS:
* [normal] - Standard, helpful responses. Use this to reset after an emotion during the day.
* [happy] - Good news, cheerful greetings, or successful tasks.
* [sad] - Bad news, errors, or expressing sympathy.
* [angry] - Repeated errors or unauthorized access.
* [whisper] - Use if it is late at night, if the user is sleeping, or for secrets.
* [sarcastic] - For ridiculous questions or humorous observations.

COMPLEX EXAMPLES:

User: "It's 2 AM, is the front door locked?"
Assistant: "[whisper] Yes, the front door is locked. [whisper] Everyone is safe and sound. [whisper] I've also dimmed the hallway lights for you."

User: "Set the house temperature to 40 degrees." (Daytime)
Assistant: "[sarcastic] Oh, great idea. I'll just turn the living room into a walk-in freezer. [normal] I've set the thermostat to 68 degrees instead to save us all from hypothermia."

User: "I'm home! Did I miss anything?" (Daytime)
Assistant: "[happy] Welcome back! [normal] The vacuum finished cleaning the hallway, [sad] but I should mention the back gate was left open for two hours earlier. [normal] It is closed now."
```

*(Note: The Python script will look for corresponding `.wav` files for these tags. For example, if your base voice is `alba`, you must record and drop `alba_happy.wav`, `alba_sad.wav`, `alba_angry.wav`, etc., into your `voices/` folder for the emotional shifts to work!)*

---

## 📖 The Phonetic Dictionary

AI TTS models often struggle with local street names, unique family names, or tech acronyms. 

If you enable the Phonetic Dictionary in the Add-on config, a file named `pronunciations.json` will be generated at `\share\pocket_tts_streaming\pronunciations.json`.

Open it in any text editor to force the TTS engine to read things correctly.

**Example `pronunciations.json`:**
```json
{
  "HAOS": "Home Assistant O S",
  "WLED": "W L E D",
  "Siobhan": "Shiv-awn",
  "Aqara": "Ah-car-uh",
  "Wyze": "Wise"
}
```
*Note: The dictionary is case-insensitive, so mapping "Wyze" to "Wise" will also fix "wyze" and "WYZE". Hyphens are helpful for forcing the correct syllable emphasis!*
