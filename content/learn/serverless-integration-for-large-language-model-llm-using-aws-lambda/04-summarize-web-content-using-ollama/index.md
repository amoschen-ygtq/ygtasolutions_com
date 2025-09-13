---
date: '2025-09-13'
draft: false
title: '4 - Summarize Web Content using Ollama'

description: "Build a modular Python app for web scraping and AI summarization with BeautifulSoup and Ollama."
summary: "This guide shows how to create a modular Python application for web scraping and AI summarization using BeautifulSoup and Ollama. It covers organizing scraper and chat services into a reusable module, integrating them in a main script, and generating summaries from online content."

tags: ["python-development", "web-scraping", "ollama", "modular-apps", "ai-integration"]
---

## Overview

Unlock the power of web scraping and AI summarization by building a modular Python application to efficiently process and summarize online content.

## Services

In order to orchestrate two major tasks - scraping and summarizing we need to package these two tasks into a self-contained module.

Create a sub-folder `services` under the `src` folder.

```
llm_with_lambda
|-- .devcontainer
|-- src
|   |-- services  # New folder
|   |-- lambda_handler.py
|   `-- main.py
...
```

### Web Scraper Service

Move the file `web_scraper.py` into the `services` folder and rename it as `web_scraper_service.py`.

```
llm_with_lambda
|-- .devcontainer
|-- src
|   |-- services
|   |   `-- web_scraper_service.py  # New file
|   |-- lambda_handler.py
|   `-- main.py
...
```

Rename the class to `WebScraperService`. Also update the reference to this class in the `if` statement towards the bottom of the file. Everything else remains the same.

```python
import requests
from bs4 import BeautifulSoup

class WebScraperService:                   <<<< Rename
    """
    A reusable service class for fetching and parsing web content.
    """
    def __init__(self, parser='html.parser'):
        """Initializes the service with a specific HTML parser."""
        self.parser = parser
        self.session = requests.Session()

    ...

if __name__ == '__main__':
    scraper = WebScraperService()          <<<< Rename
    ...
```

### Ollama Chat Service

Create a new file `ollama_chat_service.py` in the `services` folder.

```
llm_with_lambda
|-- .devcontainer
|-- src
|   |-- services
|   |   |-- ollama_chat_service.py  # New file
|   |   `-- web_scraper_service.py
|   |-- lambda_handler.py
|   `-- main.py
...
```

Move all the code from `main.py` into `ollama_chat_service.py` without any change.

Refactoring is best start with cut/paste.

```python
from ollama import Client

# Specify the host URL for Ollama's REST API
client = Client(host='http://host.docker.internal:11434')

# Send user prompt to Llama 3.2 model
response = client.chat(
    model='llama3.2',
    messages=[{'role': 'user', 'content': 'Hello from the devcontainer with Pipenv!'}]
)
print(response['message']['content'])
```

Similar to the `WebSraperService` let's create the `OllamaChatService` as following.

```python
from ollama import Client

class OlamaChatService:
    def __init__(self, host='http://host.docker.internal:11434', model='llama3.2'):
        self.client = Client(host=host)
        self.model = model

    def chat(self, user_message):
        response = self.client.chat(
            model=self.model,
            messages=[{'role': 'user', 'content': user_message}]
        )
        return response['message']['content']
```

In order to allow `main.py` to import these services we need to make the `services` folder a module by adding the `__init__.py` file.

```
llm_with_lambda
|-- .devcontainer
|-- src
|   |-- services
|   |   |-- __init__.py             # New file
|   |   |-- ollama_chat_service.py
|   |   `-- web_scraper_service.py
|   |-- lambda_handler.py
|   `-- main.py
...
```

The content of this `__init__.py` file is the follwoing.

```python
"""
This module initializes and exposes the core services for the application.

Imports:
    OlamaChatService: Service for handling chat interactions using Ollama.
    WebScraperService: Service for scraping web content.

Note:
    The imports make these services available for use throughout the package.
"""

from .ollama_chat_service import OlamaChatService
from .web_scraper_service import WebScraperService
```

## Summarize

Open the `main.py` file and replace it with the following content.

```python
from services import OlamaChatService
from services import WebScraperService

URL = 'https://www.udemy.com/course/llm-engineering-master-ai-and-large-language-models'

scraper = WebScraperService()
text_content = scraper.scrape_plain_text(URL)
if text_content:
    chat_service = OlamaChatService()
    user_message = f"Please summarize the following content:\n\n{text_content}"
    reply = chat_service.chat(user_message)
    print(reply)
else:
    print("Failed to retrieve or parse content from the URL.")
```

Run following command to fetch and display the summary.

```bash
pipenv run python src/main.py
```

Below is the sample output.

```
The course "LLM Engineering: Master AI, Large Language Models & Agents" on Udemy is an 8-week hands-on journey to learn about Generative AI and Large Language Models (LLMs). Here's a summary of the course:

**Course Overview**

* The course aims to accelerate learners' careers in AI with practical, real-world projects.
* It covers cutting-edge techniques, including RAG, QLoRA, and Agents.
* No advanced math is required to master LLM engineering.

**What You'll Learn**

* Build advanced Generative AI products using cutting-edge models and frameworks.
* Experiment with over 20 groundbreaking AI models, including Frontier and Open-Source models.
* Develop proficiency with platforms like HuggingFace, LangChain, and Gradio.
* Implement state-of-the-art techniques such as RAG, QLoRA fine-tuning, and Agents.

**Course Structure**

* Week 1: Foundations and First Projects
* Week 2: Frontier APIs and Customer Service Chatbots
* Week 3: Embracing Open-Source Models
* Week 4: LLM Selection and Code Generation
* Week 5: Retrieval-Augmented Generation (RAG)
* Week 6: Transitioning to Training
* Week 7: Advanced Training Techniques
* Week 8: Deployment and Finalization

**Instructor**

* The course is led by Ed Donner, a technology leader and repeat founder of AI startups.
* Ed has over 20 years of experience in AI and technology, including co-founding and selling an AI startup.

**Who This Course Is For**

* Aspiring AI engineers and data scientists eager to break into the field of Generative AI and LLMs.
* Professionals looking to upskill and stay competitive in the rapidly evolving AI landscape.
* Developers interested in building advanced AI applications with practical, hands-on experience.
```

## Congratulations !! :tada:
