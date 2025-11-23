---
date: '2025-11-23T12:05:00Z'
draft: false
title: '7 - Getting Structural Output from Large Language Model (LLM)'
weight: 7

description: "Learn how to reliably extract structured, machine-readable JSON from Large Language Models using Pydantic models, JSON schemas, few-shot prompting, and native enforcement features in Ollama and Amazon Bedrock – essential for integrating LLMs into production applications."
summary: "Hands-on guide to forcing LLMs to return perfect JSON using Pydantic schemas + few-shot examples + Ollama/Bedrock structured output features, with ready-to-run code for serverless Python apps."

tags: ["python-development", "large-language-models", "aws-lambda", "amazon-bedrock", "serverless"]
---

## Overview

Reliably extracting structured JSON output from LLMs using Pydantic models, JSON schemas, few-shot prompting, and provider-native enforcement (Ollama's format parameter + Amazon Bedrock's Tool Use) in a serverless Python application.

[{{< icon "github" >}}](https://github.com/amoschen-ygtq/llm-with-lambda/tree/learn-serverless-integration-for-llm-7) **[source code](https://github.com/amoschen-ygtq/llm-with-lambda/tree/learn-serverless-integration-for-llm-7)**

## Consistent Structural Output

Large Language Models (LLMs) can solve problems that are difficult or impractical for traditional computing systems. To reliably integrate an LLM as a building block in larger applications, it must produce consistent, machine-readable output—typically in JSON format.

To reliably get valid JSON output from an LLM, two main things are required:

1. **Define a structured output format** (usually a JSON Schema, Pydantic model, Zod schema, etc.) that precisely describes the expected keys, types, required fields, and constraints.

2. **Make the LLM aware of this format and enforce it** through one or both of the following mechanisms:
   - **Prompt-level guidance**: Explicitly provide the schema in the system/user prompt and instruct the model to output JSON that strictly conforms to it (often combined with few-shot examples or reasoning instructions).
   - **API-level enforcement** (preferred when available): Use the LLM provider’s native structured output / function-calling / JSON mode feature (e.g., Ollama’s `format="json"`, Amazon Bedrock's `<toolConfig>`, OpenAI’s `response_format={ "type": "json_schema", "json_schema": ... }`, Anthropic’s `<tool>`, etc.). This constrains the model’s actual token generation so it can only produce valid JSON matching the schema.

In practice, the most reliable results come from combining both (clear prompt + API-level constraint), especially with frontier models that support true JSON schema enforcement.

### JSON Schema

In Python we can use Pydantic to define data model and generate JSON Schema from this model definition. Pydantic is a widely used Python library for data validation and settings management using Python type annotations.

Let's add Pydantic to the project by running following command.

```bash
pipenv install pydantic
```

Then we add `online_course.py` in the `models` folder.

```
llm_with_lambda
|-- .devcontainer
|-- src
|   |-- models
|   |   |-- ...
|   |   |-- online_course.py  # New file
```

Start with a small model and later we can add more to it.

```python
# online_course.py
from pydantic import BaseModel, Field, field_validator

class OnlineCourse(BaseModel):
    """Information about an online course."""

    title: str = Field(..., description="The title of the online course")
    instructor: str = Field(..., description="The name of the course instructor")
    platform: str = Field(..., description="The platform where the course is hosted")
    url: str = Field(..., description="The URL of the online course")
    description: str = Field(
        ..., description="A brief description of the course content"
    )
```

`BaseModel` gives us two particularly useful methods:

- `model_dump_json()` – converts a Pydantic model instance into a clean JSON string. We’ll use this to create **correct JSON examples** to insert into the prompt.
- `model_validate_json()` (and its sibling `model_validate()`) – parses JSON output from the LLM and automatically converts it into a properly typed Python object (while raising clear errors if the JSON is invalid or doesn’t match the schema).

These methods make the round-trip (Python → JSON example in prompt → LLM → JSON response → Python) simple, reliable, and less error-prone.

### Few-Shot Prompting

When we ask the LLM to perform a task without providing an example it is known as the **[Zero-shot prompting](https://www.promptingguide.ai/techniques/zeroshot)**. For instance, you can ask a language model to classify text as positive or negative without showing it any examples first. This type of prompting requires the model to rely on its existing, pre-trained knowledge to understand and complete the task, making it a fast and versatile method for generating responses.

The "zero-shot" terminology originates from a machine learning concept called **zero-shot learning (ZSL)**, where a model is expected to classify data into categories it did not encounter during its training phase. In the context of prompting, it specifically refers to the complete absence of illustrative examples in the prompt itself, requiring the model to apply its pre-existing, generalized knowledge to a novel instruction.

For complex problems zero-shot prompting becomes inadequate. Providing context and examples enable the LLM to do in-context learning. This steers the model to perform better without fine-tuning. This technique is known as the [few-shot prompting](https://www.promptingguide.ai/techniques/fewshot) or [few-shot learning](https://platform.openai.com/docs/guides/prompt-engineering#few-shot-learning).

In our `PromptService` let's assume an example JSON object is going to be provided with `BaseModel` as its base class. We then can use the `model_dump_json()` to get the JSON presentation of this object and use it as part of the prompt.

The following code adds a new method in the `prompt_service.py` for building a prompt with example JSON output.

```python
# services/prompt_service.py
from pydantic import BaseModel
from models.prompt import Message, MessageType, Prompt

class PromptService:

    # ...

    def build_content_summarization_prompt_for_structural_output(
        self, text_content: str, example: BaseModel
    ) -> Prompt:
        messages = [
            Message(type=MessageType.SYSTEM, content="You are a helpful assistant."),
            Message(
                type=MessageType.USER,
                content=(
                    "Extract the details of the online course from the following content "
                    "and structure output into a JSON format according to the OnlineCourse model:\n\n"
                    + text_content
                    + "\n\n"
                    "Here is an example of the OnlineCourse model:\n"
                    f"{example.model_dump_json(indent=2)}"
                ),
            ),
        ]
        return Prompt(version="1.0", messages=messages)
```

### Define Response Format

Relying on the prompt alone is often not enough to guarantee valid JSON output from an LLM.

For reliable results, you should use **API-level structured output enforcement** whenever the provider supports it.

Different providers implement this feature in their own way because it’s tightly coupled with how the model was trained. The exact mechanism (and its reliability) varies across platforms.

In the next sections, we’ll look at two popular options:
- **Ollama** (local/open-source)
- **Amazon Bedrock** (fully managed)

and see how each handles enforced JSON output.

#### Ollama

The Ollama API provides a `format` parameter for providing JSON Schema specification.

```python
from ollama import Client

client = Client(host="...")
client.chat(
    model="llama3.2",
    messages=messages,
    format=json_schema,  # JSON Schema for output format
)
```

With this let's add a new method to the `OllamaChatService`.

```python
# services/ollama_chat_service.py
from typing import Type
from ollama import Client
from pydantic import BaseModel
from models.prompt import Prompt

class OllamaChatService:
    
    # ...

    def structural_chat(
        self, prompt: Prompt, output_model: Type[BaseModel]
    ) -> BaseModel:
        messages = self.__build_messages(prompt)
        json_schema = output_model.model_json_schema()
        
        # Send the request with the desired JSON schema format
        response = self.client.chat(
            model=self.model,
            messages=messages,
            format=json_schema,
        )
        json_output = response["message"]["content"]

        # Validate and parse the JSON output into the specified Pydantic model
        validated_data = output_model.model_validate_json(json_output)
        return validated_data

    # This is reused in the chat() method
    def __build_messages(self, prompt: Prompt):
        messages = []
        for message in prompt.messages:
            role = message.type.value or "user"  # Default to user if unknown type
            messages.append({"role": role, "content": message.content})
        return messages
```

Let's update and run the `main.py` to verify everything works.

```python
# main.py

# ...

text_content = scraper.scrape_plain_text(URL)
if text_content:
    example = OnlineCourse(
        title="Example Course",
        instructor="John Doe",
        platform="Udemy",
        url="https://www.udemy.com/course/example-course",
        description="This is an example course description.",
    )
    summarization_prompt = (
        prompt_service.build_content_summarization_prompt_for_structural_output(
            text_content,
            example,
        )
    )
    reply = chat_service.structural_chat(summarization_prompt, OnlineCourse)
    print(reply.model_dump_json(indent=2))
```

Let's run `pipenv run python src/main.py` in terminal.

```json
{
  "title": "AI Engineer Core Track: LLM Engineering, RAG, QLoRA, Agents",
  "instructor": "Ligency ​ and Ed Donner",
  "platform": "Udemy",
  "url": "https://www.udemy.com/course/ai-engineer-core-track-llm-engineering-rag-qlora-agents/",
  "description": "Become an LLM Engineer in 8 weeks: Build and deploy 8 LLM apps, mastering Generative AI, RAG, LoRA and AI Agents."
}
```

There is an extra space in the value for `"instructor"`. This could be because the local Llama model only has 3B parameters. I could download a larger model but I prefer run larger model in cloud for now.

#### Amazon Bedrock

There are two APIs provided by Amazon Bedrock to run inference - InvokeModel API, and Converse API.

The Converse API is the primary choice for most modern conversational applications due to its unified interface and built-in support for conversational features, while the InvokeModel API should be used when you require low-level, model-specific control or need to process very large inputs.

The Converse API uses a different approach for enforcing JSON response comparing to the Ollama's REST API. It requires a **Tool Use**, which involves defining a tool with a specific JSON schema as the input and then forcing the model to use that tool.

> **What is a Tool?** A Tool is a function given to the LLM. This function should fulfill a clear objective.

Below is the definition of the tool for receiving JSON input. It has three key properties. Full specification can be found [here](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_ToolSpecification.html#API_runtime_ToolSpecification_Contents).
- **name:** the key for this tool. No space is allowed.
- **description:** a concise functional description that allows the LLM to know what problem this tool solves.
- **inputSchema:** 

The code below uses the model's JSON schema to define the tool's input schema. This ensures when LLM engages this tool the input conforms with the required JSON format. The description of the Tool should be clear about what it does so that LLM knows when to engage this Tool for a specific task.

```python
json_schema = OnlineCourse.model_json_schema()
tool_config = {
    "tools": [
        {
            "toolSpec": {
                "name": "json_output_tool",
                "description": "Get the JSON output that align with the provided schema.",
                "inputSchema": {"json": json_schema},
            }
        }
    ]
}
response = self.bedrock_runtime.converse(
    modelId=self.inference_profile_arn,
    messages=messages,
    system=system,
    toolConfig=tool_config,
)
```

You might notice that part of the prompt matches the description. This allows the LLM to look for help from the tools provided from the users.

```json
"and structure output into a JSON format according to the OnlineCourse model:\n\n"
```

The end result is a response from the LLM that provides an input that satisfies the input schema of the tool. Instead of the normal `"text"` block it will have a `"toolUse"` block in the response content blocks. The `"input"` value in the tool use block is the JSON content that matches the `"inputSchema"` specified above.

```python
# The model will respond with a `toolUse` block.
content_blocks = response["output"]["message"]["content"]

tool_use_block = next(
    block["toolUse"] for block in content_blocks if "toolUse" in block
)
# This is your JSON object, already parsed and matching the schema
if "input" in tool_use_block:
    print("Tool use block found with input.")
    result = tool_use_block["input"]
else:
    print("No tool use block found, falling back to text content.")
    result = content_blocks[0]["text"]
```

The result can be a dict or a string. Though we hope receiving a tool use response we never know for sure it will be the case. When it comes as normal text response it is a string and we need to use `model_validate_json()`. If fortunately it is tool use response then Boto3 will make sure it's in the dict type. With this type we need to use `model_validate()`. Last but not least the returned data may not match the schema we defined.

```python
if isinstance(result, (str, bytes)):
    try:
        model_instance = model.model_validate_json(result)
        return model_instance
    except (ValidationError, json.JSONDecodeError) as e:
        print(f"Error validating JSON string: {e}")
        return None
elif isinstance(result, dict):
    try:
        model_instance = model.model_validate(result)
        return model_instance
    except ValidationError as e:
        print(f"Error validating dictionary: {e}")
        return None
else:
    print(f"Input data is of an unsupported type: {type(result)}")
    return None
```

Amazon Bedrock has an optional setting in the tool config to force the LLM to must engage the tool. Unfortunately I didn't find a model supports this option after a few try. So as of now I disabled this optional setting by default.

The latest Lambda code can be found [here](https://github.com/amoschen-ygtq/llm-with-lambda/blob/learn-serverless-integration-for-llm-7/src/lambda_function.py).

Previously we used the Llama 3.2 1B model. This time let's upgrade to the Llama 3.2 11B model. Please refer to the [Hello World from Amazon Bedrock](/learn/serverless-integration-for-large-language-model-llm-using-aws-lambda/02-hello-world-from-amazon-bedrock/) for detailed steps. Such as how to setup IAM permissions.

After deploying the latest Lambda and a test run should generate a response similar to the following.

```json
{
  "statusCode": 200,
  "body": "{\"response\": {\"title\": \"AI Engineer Core Track: LLM Engineering, RAG, QLoRA, Agents\", \"instructor\": \"Ed Donner\", \"platform\": \"Udemy\", \"url\": \"https://www.udemy.com/course/ai-engineer-core-track-llm-engineering-rag-qlora-agents/\", \"description\": \"Mastering Generative AI and LLMs: An 8-Week Hands-On Journey\", \"duration_hours\": null, \"level\": null, \"rating\": 4.7, \"num_reviews\": 21969}}"
}
```

### Fantastic !! :tada:

Here is the problem if we look a bit deeper into the outcome.

```
# The generated URL
https://www.udemy.com/course/ai-engineer-core-track-llm-engineering-rag-qlora-agents/

# The actual provided URL
https://www.udemy.com/course/llm-engineering-master-ai-and-large-language-models
```

Looks like the LLM came up its own imaginary URL ... :)

We can improve our prompt to fix this problem. I will leave this to you to explore!

## Thanks!