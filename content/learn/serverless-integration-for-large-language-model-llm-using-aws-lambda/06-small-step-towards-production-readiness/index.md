---
date: '2025-09-26T12:05:00Z'
draft: false
title: '6 - A Small Step Towards Production Readiness'
weight: 6

description: "Learn to enhance Python code quality with Ruff and pre-commit, and streamline LLM prompt management for production-ready projects."
summary: "This post guides us through improving Python code quality using Ruff, a fast linter and formatter, and pre-commit for automated checks. It also covers structuring LLM prompts with a Prompt model for scalable AI integrations, including updates to Ollama and Bedrock chat services."

tags: ["Python", "code quality", "Ruff", "pre-commit", "LLM", "prompt engineering", "Ollama", "AWS Bedrock", "software engineering", "DevOps"]
---

## Overview

Improve code quality using Ruff and pre-commit, and streamline LLM prompt management for scalable, production-ready AI integrations.

[{{< icon "github" >}}](https://github.com/amoschen-ygtq/llm-with-lambda/tree/learn-serverless-integration-for-llm-6) **[source code](https://github.com/amoschen-ygtq/llm-with-lambda/tree/learn-serverless-integration-for-llm-6)**

## Code quality

The project has collected six Python files. We can see both single quote and double quote are used sometimes in the same file.

Python linters and consistent formatting contribute to higher quality, more maintainable, and more collaborative codebases by promoting readability, preventing errors, and streamlining development workflows.

**Ruff** is an extremely fast and unified Python linter and code formatter. Written in Rust, it is designed to replace and significantly outperform a host of existing tools, such as Flake8, Black, isort, and others.

**pre-commit** is a framework that manages and runs automated checks, known as "hooks," before a commit is finalized in a Git repository. Used together with Ruff to provide a mechanism for maintaining consistently high code quality.

```bash
pipenv install --dev pre-commit ruff
```

Create file `.pre-commit-config.yaml`.

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.13.1 # Use the latest version
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format
```

- `id: ruff`: The ruff hook runs the Ruff linter, which checks for potential errors, bugs, and best practice violations in your Python code.
- `--fix`: Tells the linter to automatically fix any fixable issues, such as removing unused imports or trailing whitespace.
- `--exit-non-zero-on-fix`: Ensures that if any fixable issues are found and fixed, the pre-commit hook will still fail and abort the commit. This is a deliberate step to force the developer to stage the automatically-applied changes before re-committing.
- `id: ruff-format`: The ruff-format hook uses Ruff's integrated formatter to apply a consistent code style to all staged Python files, ensuring uniform formatting across the entire project. It is important to run this hook after the ruff (linting) hook because some linting fixes can introduce formatting changes that need to be re-formatted.

To run the checks and formatting defined in the `.pre-commit-config.yaml` file automatically every time when attempt to run `git commit`, we need to installs the pre-commit hook scripts into your local Git repository.

```bash
pipenv run pre-commit install
```

Add `pyproject.toml` for Ruff configurations.

```yaml
# pyproject.toml
[tool.ruff]
line-length = 88
target-version = "py310"

[tool.ruff.lint]
# Select lint rules, including the isort rules ("I")
select = ["E", "F", "I"]
# Ruff format takes care of these stylistic issues
ignore = ["E501"]

[tool.ruff.format]
# Configure formatting options if you need to deviate from the defaults
quote-style = "double"
```

The letters "E", "F", and "I" are prefixes for different rule families, inherited from earlier tools. 

- **E (pycodestyle)**: The "E" rules check for errors related to code style and formatting, based on Python's official style guide, PEP 8. For example, they cover issues like incorrect indentation, too many blank lines, or improper spacing around operators.
- **F (Pyflakes)**: The "F" rules focus on detecting logical errors and potential bugs. They perform a simple static analysis of the code to find problems that would likely cause a runtime error. For examples, they check for unused imports, undefined variables, and other logical inconsistencies that are not caught by formatting or style checks.
- **I (isort)**: The "I" rules handle import-sorting. These rules ensure that all import statements are grouped and alphabetized in a consistent, standardized way.

For the existing files we need to manually apply the pre-commit hooks since these files are already committed.

```bash
pipenv run pre-commit run --all-files
```

Now commit all the changes to Git repo.

## Prompt management

Before we grow the Large Language Model (LLM) prompts to become more sophisticated we need to define a structure to manage it better.

Create a `models` folder. Then add `__init__.py` and `prompt.py` in this folder.

```
llm_with_lambda
|-- ...
|-- models
|   |-- __init__.py
|   `-- prompt.py
...
```

The `__init__.py` remains empty, and add following code to `prompt.py`.

```python
from dataclasses import dataclass
from enum import StrEnum
from typing import List


class MessageType(StrEnum):
    USER = "user"
    SYSTEM = "system"
    ASSISTANT = "assistant"


@dataclass
class Message:
    type: MessageType
    content: str


@dataclass
class Prompt:
    version: str
    messages: List[Message]
```

The above model allows us to define a collection of messages as a prompt to be sent to any LLM. This is sufficient starting point for a proof of concept (POC) project. As the project grows we can migrate to other more advanced framework such as **Promptify** or even the more advanced **LangChain**.

### Type of prompt message

- **System**: Defines the context, instructions, or role for the LLM, setting its behavior or tone (e.g., "You are a helpful assistant with expertise in geography.").
- **User**: Represents messages or inputs provided by the end-user interacting with the LLM. These are typically questions, instructions, or queries (e.g., "What's the capital of France?").
- **Assistant**: Represents the LLM's responses or outputs generated based on user and system messages (e.g., "The capital of France is Paris.").

In many LLM systems and APIs, the system message typically appears once at the start of a conversation or prompt sequence to set the context, tone, or behavior for the LLM. Some APIs enforce this by structurally separating the system message from the sequence of user and assistant messages.

### Update Ollama Chat Service

The chat service currently receives a user message as a string.

```python
# Current implementation
def chat(self, user_message):
    response = self.client.chat(
        model=self.model,
        messages=[{'role': 'user', 'content': user_message}]
    )
    return response['message']['content']
```

Adapting to the `Prompt` data structure we are going to update the `chat(...)` function to the following.

```python
# Adapting Prompt model
def chat(self, prompt: Prompt):
    messages = []
    for message in prompt.messages:
        role = message.type.value or "user"  # Default to user if unknown type
        messages.append({"role": role, "content": message.content})

    response = self.client.chat(
        model=self.model,
        messages=messages,
    )
    return response["message"]["content"]
```

This would allow us to carry an entire conversation between user and LLM through the Prompt model.

### Update Bedrock Chat Service

Similar to the Ollama Chat Service we are going to update the existing Bedrock `send_message(...)` function.

```python
# Current implementation
def send_message(self, prompt):
    messages = [{"role": "user", "content": [{"text": prompt}]}]
    response = self.bedrock_runtime.converse(
        modelId=self.inference_profile_arn,
        messages=messages
    )
    return response['output']['message']['content'][0]['text']
```

After adapting to use the `Prompt` model.

```python
# Adapting Prompt model
def send_message(self, prompt: Prompt):
    system = []
    messages = []
    for message in prompt.messages:
        content = {"text": message.content}
        if message.type == MessageType.SYSTEM:
            system.append(content)
        else:
            role = message.type.value
            messages.append({"role": role, "content": [content]})

    response = self.bedrock_runtime.converse(
        modelId=self.inference_profile_arn,
        messages=messages,
        system=system,
    )
    return response["output"]["message"]["content"][0]["text"]
```

Bedrock API is more complex and the reference for its message structure can be found [here](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/bedrock-runtime/client/converse.html).

We also can see that Bedrock enforces single instance of system message by having a separated parameter dedicated for it.

## Prompt service

Now we have both chat services updated and it's time to implement a service that produces the actual `Prompt` instance.

```python
from models.prompt import Message, MessageType, Prompt


class PromptService:
    def __init__(self):
        pass

    def build_content_summarization_prompt(self, text_content: str) -> Prompt:
        messages = [
            Message(type=MessageType.SYSTEM, content="You are a helpful assistant."),
            Message(
                type=MessageType.USER,
                content=("Please summarize the following content:\n\n" + text_content),
            ),
        ]
        return Prompt(version="1.0", messages=messages)
```

Finally instead of hard code the prompt message in `main.py` as the following.

```python
# Current implementation
scraper = WebScraperService()
text_content = scraper.scrape_plain_text(URL)
if text_content:
    chat_service = OllamaChatService()
    user_message = f"Please summarize the following content:\n\n{text_content}"
    reply = chat_service.chat(user_message)
    print(reply)
```

We use the prompt service to create the prompt for us.

```python
# Adapting Prompt model
scraper = WebScraperService()
chat_service = OllamaChatService()
prompt_service = PromptService()

text_content = scraper.scrape_plain_text(URL)
if text_content:
    summarization_prompt = prompt_service.build_content_summarization_prompt(
        text_content
    )
    reply = chat_service.chat(summarization_prompt)
    print(reply)
```

Then we also update and deploy the Lambda after verifying the new mechanism above works locally.

## Congratulations !! :tada:

