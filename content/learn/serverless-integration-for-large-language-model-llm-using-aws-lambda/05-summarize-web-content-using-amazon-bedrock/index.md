---
date: '2025-09-15T00:00:00Z'
draft: false
title: '5 - Summarize Web Content using Amazon Bedrock'
weight: 5

description: "Master LLMs with AWS Lambda using Python, AWS CLI setup, Bedrock Chat, web scraping, and automated deployment."
summary: "This article guides you through building a modular Python application to leverage Large Language Models (LLMs) with AWS Lambda. Learn to set up AWS CLI with IAM Identity Center, create a Bedrock Chat Service, implement web scraping and summarization, and automate Lambda deployment with a ZIP file. Includes practical code examples and verification steps."

tags: ["python-development", "aws-lambda", "large-language-models", "web-scraping", "bedrock-chat", "automated-deployment"]
---

## Overview

Discover how to harness LLMs with AWS Lambda through a modular Python application, mastering AWS CLI setup, Bedrock Chat Service, web scraping, summarization, and automated deployment with precision.

[{{< icon "github" >}}](https://github.com/amoschen-ygtq/llm-with-lambda/tree/learn-serverless-integration-for-llm-5) **[source code](https://github.com/amoschen-ygtq/llm-with-lambda/tree/learn-serverless-integration-for-llm-5)**

## AWS Command Line Interface (CLI)

AWS programmatic access enables applications, scripts, or automated processes to interact with AWS resources without direct human intervention through the AWS Management Console. This is typically achieved using AWS Identity and Access Management (IAM) credentials, specifically access keys (an access key ID and a secret access key).

At large, there are two ways to set up the programmatic access.

### Simple but not recommended way

[Authenticating using IAM user credentials for the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-authentication-user.html)

Use this for quick experiment within a limited timeframe. Push yourself to complete the IAM Identity Center setup. For most single-person shop it does not cost any penny and provides a streamlined dev experience.

### Effective and proper way

Follow the two steps below to complete IAM Identity Center setup.

- [Enable IAM Identity Center](https://docs.aws.amazon.com/singlesignon/latest/userguide/enable-identity-center.html#to-enable-identity-center-instance)
- [Configure user access with the default IAM Identity Center directory](https://docs.aws.amazon.com/singlesignon/latest/userguide/quick-start-default-idc.html)


### Install AWS CLI

It is important to script the manual steps in development workflow even for some seemly one-off tasks. For a single-person shop there will have time to re-do the same task. For team environment we have times to onboard a new member.

Create a `scripts` folder in project root.

```
llm_with_lambda
|-- ...
|-- scripts  # New folder
...
```

Add a `install_tools.sh` file in this folder. With LLM's help writing a shell script becomes much easier these days. Please find the source code at [here](https://github.com/amoschen-ygtq/llm-with-lambda/blob/learn-serverless-integration-for-llm-5/scripts/install_tools.sh).

```
llm_with_lambda
|-- ...
|-- scripts
|   `-- install_tools.sh  # New file
...
```

Change this script to an executable file.

```bash
chmod u+x scripts/install_tools.sh
```

Then run the script to install AWS CLI.

```bash
scripts/install_tools.sh
```

### Verify access

Assume you have managed to set up the programmatic access credentials. Set up environment variables and verify.

```bash
export AWS_ACCESS_KEY_ID=...          # Replace with yours
export AWS_SECRET_ACCESS_KEY=...      # Replace with yours
export AWS_DEFAULT_REGION=us-east-1   # Or other region at your choice
```

Verify your access with the following command.

```bash
aws sts get-caller-identity
```

When success the output looks like the following.

```
{
    "UserId": "...",
    "Account": "...",
    "Arn": "..."
}
```

## Bedrock Chat Service

As we extending the Lambda to scraping the web content it is important to modularize both the scraping and summarization into two modules.

Create a new file `bedrock_chat_service.py` in the `services` folder.

```
llm_with_lambda
|-- ...
|-- services
|   `-- bedrock_chat_service.py  # New file
...
```

Use the following code for the `BedrockChatService`.

```python
import boto3

class BedrockChatService:
    def __init__(self, inference_profile_arn, region_name='us-east-1'):
        self.inference_profile_arn = inference_profile_arn
        self.bedrock_runtime = boto3.client(
            service_name='bedrock-runtime',
            region_name=region_name
        )

    def send_message(self, prompt):
        messages = [{"role": "user", "content": [{"text": prompt}]}]
        response = self.bedrock_runtime.converse(
            modelId=self.inference_profile_arn,
            messages=messages
        )
        return response['output']['message']['content'][0]['text']
```

## Scraping and summarizing

A small structural adjustment is required for allowing the services module deployed partially. Open the `services/__init__.py` file and remove all content and save it as an empty file. Adjust import statements in the `main.py` to following.

```python
from services.ollama_chat_service import OllamaChatService
from services.web_scraper_service import WebScraperService
```

When we deploy the service module to AWS Lambda we only need a portion of it. Having an `__init__.py` file that references both local and cloud-native files blocks us from deploying the services module.

Next, update `lambda_function.py` to the following for using both `WebScraperService` and the `BedrockService`.

```python
import json
import os

from services.bedrock_chat_service import BedrockChatService
from services.web_scraper_service import WebScraperService

# Your inference profile ARN from Step 1
INFERENCE_PROFILE_ARN = os.environ.get("INFERENCE_PROFILE_ARN", None)
if INFERENCE_PROFILE_ARN is None:
    raise ValueError("INFERENCE_PROFILE_ARN environment variable is not set.")

DEFAULT_URL = 'https://www.udemy.com/course/llm-engineering-master-ai-and-large-language-models'

# Initialize Bedrock service in global scope
bedrock_service = BedrockChatService(inference_profile_arn=INFERENCE_PROFILE_ARN)
scraper = WebScraperService()

def lambda_handler(event, context):
    """
    Scrapes text content from a given URL and sends it to a Bedrock model for processing.
    """
    # Extract the user prompt from the Lambda event payload
    url = event.get('url', DEFAULT_URL)
    try:
        text_content = scraper.scrape_plain_text(url)
    except Exception as e:
        print(f"Error scraping URL: {e}")
        text_content = None

    prompt = f"Please summarize the following content:\n\n{text_content}"
    try:
        output_message = bedrock_service.send_message(prompt)
        return {
            'statusCode': 200,
            'body': json.dumps({'response': output_message})
        }
    except Exception as e:
        print(f"Error invoking Bedrock model: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
```

## Deploy Lambda using a ZIP file

As the Lambda grows it requires more Python packages. The packaging and deployment of Lambda need to be automated.

Create `deploy_lambda.sh` in the `scripts` folder.

```bash
#!/bin/bash

# The 'set -e' command instructs the shell to immediately exit if any command within the script returns a non-zero exit status.
# This helps prevent the script from continuing execution after an error, which can improve reliability and safety.
set -e

SRC_PATH="src"
BUILD_PATH=".build"
HANDLER_FILE="lambda_function.py"
SERVICES_PACKAGE_INIT="services/__init__.py"
BEDROCK_SERVICE_FILE="services/bedrock_chat_service.py"
SCRAPER_SERVICE_FILE="services/web_scraper_service.py"

LAMBDA_NAME="llm-with-lambda"
ZIP_FILE="lambda_package.zip"
ZIP_PATH="$BUILD_PATH/$ZIP_FILE"

# Create .build directory if it doesn't exist
rm -rf ".build/$LAMBDA_NAME"
mkdir -p ".build/$LAMBDA_NAME/services"

# Copy handler file to .build/llm-with-lambda/
cp "$SRC_PATH/$HANDLER_FILE" "$BUILD_PATH/$LAMBDA_NAME/$HANDLER_FILE"

# Copy services files to .build/llm-with-lambda/services/
cp "$SRC_PATH/$SERVICES_PACKAGE_INIT" "$BUILD_PATH/$LAMBDA_NAME/$SERVICES_PACKAGE_INIT"
cp "$SRC_PATH/$BEDROCK_SERVICE_FILE"  "$BUILD_PATH/$LAMBDA_NAME/$BEDROCK_SERVICE_FILE"
cp "$SRC_PATH/$SCRAPER_SERVICE_FILE"  "$BUILD_PATH/$LAMBDA_NAME/$SCRAPER_SERVICE_FILE"

# Export requirements.txt to .build/$LAMBDA_NAME/ from Pipfile in project root
pipenv requirements > "$BUILD_PATH/$LAMBDA_NAME/requirements.txt"

# Install dependencies into .build/$LAMBDA_NAME/ as individual folders
pip3 install --target "$BUILD_PATH/$LAMBDA_NAME/" -r "$BUILD_PATH/$LAMBDA_NAME/requirements.txt"

# Remove requirements.txt from .build/$LAMBDA_NAME/
rm "$BUILD_PATH/$LAMBDA_NAME/requirements.txt"

# Remove old zip if exists
rm -f "$ZIP_PATH"

# Create zip package
(cd ".build/$LAMBDA_NAME" && zip -r "../$ZIP_FILE" .)

# Deploy to AWS Lambda
aws lambda update-function-code \
    --function-name "$LAMBDA_NAME" \
    --zip-file "fileb://$ZIP_PATH" \
    --region us-east-1
```

Change this script to an executable file.

```bash
chmod u+x scripts/deploy_lambda.sh
```

Then run the script to package and deploy the Lambda.

```bash
scripts/deploy_lambda.sh
```

You should see something similar to the following.

```
{
    "FunctionName": "llm-with-lambda",
    "FunctionArn": "arn:aws:lambda:us-east-1:123456789012:function:llm-with-lambda",
    "Runtime": "python3.11",
    "Role": "arn:aws:iam::123456789012:role/service-role/llm-with-lambda-role-91wvm026",
    "Handler": "lambda_function.lambda_handler",
    "CodeSize": 3302,
    "Description": "",
    "Timeout": 60,
    "MemorySize": 128,
    "LastModified": "2025-09-14T02:34:54.000+0000",
    "CodeSha256": "n1vNbdIPNVzTg5Tlds34/ULnkNaTTFAvWhYhjTCse84=",
    "Version": "$LATEST",
    "TracingConfig": {
        "Mode": "PassThrough"
    },
    ...
}
```

## Verify

The Lambda is successfully deployed, and we can verify through the **Last modified** value in the top section.

- Open the `llm-with-lambda` Lambda function from the **management console**.
- Click on the **Test** tab below the Function overview section.
- Replace the **Event JSON** with the following content in the Test event section.

  ```json
  {
    "url": "https://www.udemy.com/course/llm-engineering-master-ai-and-large-language-models"
  }
  ```

The test result is an stringified JSON. After some clean up it should look similar to below.

```
The Udemy course "LLM Engineering: Master AI, Large Language Models & Agents" is a 8-week hands-on journey that teaches aspiring AI engineers and data scientists how to build and deploy advanced Large Language Models (LLMs) and Generative AI products. Here's a summary of the course:

**Course Overview:**

* The course is designed to help learners build advanced LLM products, experiment with over 20 groundbreaking AI models, and master state-of-the-art techniques like RAG (Retrieval-Augmented Generation), QLoRA fine-tuning, and Agents.
* The course is divided into 8 weeks, with each week focusing on a specific topic, such as foundations, Frontier APIs, Open-Source models, LLM selection, and deployment.

**Key Topics:**

* Building advanced Generative AI products using cutting-edge models and frameworks
* Experimenting with over 20 groundbreaking AI models, including Frontier and Open-Source models
* Developing proficiency with platforms like HuggingFace, LangChain, and Gradio
* Implementing state-of-the-art techniques like RAG, QLoRA fine-tuning, and Agents
* Creating real-world AI applications, including:
\t+ A multi-modal customer support assistant
\t+ An AI knowledge worker
\t+ An AI programmer
\t+ An ecommerce application
\t+ A product that predicts prices of unseen products

**Course Structure:**

* Week 1: Foundations and First Projects
* Week 2: Frontier APIs and Customer Service Chatbots
* Week 3: Embracing Open-Source Models
* Week 4: LLM Selection and Code Generation
* Week 5: Retrieval-Augmented Generation (RAG)
* Week 6: Transitioning to Training
* Week 7: Advanced Training Techniques
* Week 8: Deployment and Finalization

**Instructor:**

* Ed Donner is a technology leader and repeat founder of AI startups, with over 20 years of experience in AI and technology. He's the co-founder and CTO of Nebula, the platform to source, understand, engage, and manage talent, using Generative AI and other forms of machine learning.

**Target Audience:**

* Aspiring AI engineers and data scientists
* Professionals looking to upskill and stay competitive in the rapidly evolving AI landscape
* Developers interested in building advanced AI applications with practical, hands-on experience
* Individuals seeking a career transition or aiming to enhance productivity through LLM-built frameworks
```

## Congratulations !! :tada:

